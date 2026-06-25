param(
  [ValidateSet("all", "clean", "short", "long", "dat", "dut_input", "layer0_write", "layer1_path", "l0_mem_feedback", "l0_expected", "l1_expected", "l0_addr_map", "l1_addr_map", "reset_inflight", "protocol", "protocol_negative", "fault_l0_data", "fault_l1_data", "fault_illegal_csel", "fault_missing_l0", "fault_duplicate_l1", "negative")]
  [string]$Test = "all"
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$UvmSrc = "C:\intelFPGA_lite\18.1\modelsim_ase\verilog_src\uvm-1.2\src"
$RunStamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$ReportDir = Join-Path $Root ("reports\smoke_{0}" -f $RunStamp)
$Lib = "smoke_$RunStamp"
$DutSource = "CONV.v"
$CompileDefines = @()

switch ($Test) {
  "fault_l0_data" {
    $DutSource = "CONV_buggy.v"
    $CompileDefines += "+define+FI_BUG1_L0_DATA"
  }
  "fault_l1_data" {
    $DutSource = "CONV_buggy.v"
    $CompileDefines += "+define+FI_BUG2_L1_DATA"
  }
  "fault_illegal_csel" {
    $DutSource = "CONV_buggy.v"
    $CompileDefines += "+define+FI_ASSERT_ILLEGAL_CSEL"
  }
  "fault_missing_l0" {
    $DutSource = "CONV_buggy.v"
    $CompileDefines += "+define+FI_BUG3_MISSING_L0"
  }
  "fault_duplicate_l1" {
    $DutSource = "CONV_buggy.v"
    $CompileDefines += "+define+FI_BUG4_L1_DUP_ADDR"
  }
}

New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
Set-Location $Root

function Has-Pattern {
  param(
    [string[]]$Lines,
    [string]$Pattern
  )
  return (($Lines | Select-String -Pattern $Pattern).Count -gt 0)
}

function Run-Cmd {
  param(
    [string]$Log,
    [scriptblock]$Command
  )
  $oldErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $out = & $Command 2>&1
    $code = $LASTEXITCODE
  }
  finally {
    $ErrorActionPreference = $oldErrorActionPreference
  }
  $out | Set-Content -Path $Log
  return [pscustomobject]@{ Lines = $out; ExitCode = $code; Log = $Log }
}

function Compile-Smoke {
  $compileLog = Join-Path $ReportDir "compile.log"

  $vlib = Run-Cmd -Log $compileLog -Command { vlib $Lib }
  if ($vlib.ExitCode -ne 0) {
    throw "vlib failed; see $compileLog"
  }

  $args = @(
    "-sv",
    "-timescale", "1ns/1ps",
    "-work", $Lib,
    "+define+UVM_NO_DPI"
  )
  $args += $CompileDefines
  $args += @(
    "+incdir+$UvmSrc",
    (Join-Path $UvmSrc "uvm_pkg.sv"),
    "conv_if.sv",
    "conv_pkg.sv",
    $DutSource,
    "conv_assertions.sv",
    "top.sv"
  )

  $out = & vlog @args 2>&1
  $code = $LASTEXITCODE
  $out | Add-Content -Path $compileLog

  if ($code -ne 0 -or !(Has-Pattern $out "Errors:\s*0")) {
    throw "compile failed; see $compileLog"
  }
}

function Run-SmokeCase {
  param(
    [string]$Name,
    [string]$UvmTest,
    [int]$ExpectedErrors,
    [string[]]$RequiredPatterns
  )

  $logName = ($Name -replace "\s+", "_").ToLower()
  $simLog = Join-Path $ReportDir "$logName.log"
  $result = Run-Cmd -Log $simLog -Command {
    vsim -suppress 19 -suppress 8785 -c -lib $Lib top +UVM_NO_RELNOTES "+UVM_TESTNAME=$UvmTest" -do "run -all; quit -f"
  }

  $errorOk = Has-Pattern $result.Lines ("UVM_ERROR\s*:\s*{0}" -f $ExpectedErrors)
  $fatalOk = Has-Pattern $result.Lines "UVM_FATAL\s*:\s*0"
  $patternsOk = $true
  foreach ($pattern in $RequiredPatterns) {
    if (!(Has-Pattern $result.Lines $pattern)) {
      $patternsOk = $false
    }
  }

  if ($result.ExitCode -eq 0 -and $errorOk -and $fatalOk -and $patternsOk) {
    Write-Host "[PASS] $Name"
    return $true
  }

  Write-Host "[FAIL] $Name"
  Write-Host "       log: $simLog"
  return $false
}

function Move-LibraryToReport {
  $dest = Join-Path $ReportDir "work"
  if (Test-Path -LiteralPath $Lib) {
    Move-Item -LiteralPath $Lib -Destination $dest -Force
  }
}

$cases = @(
  [pscustomobject]@{
    Key = "clean"
    Name = "clean smoke"
    UvmTest = "conv_test"
    ExpectedErrors = 0
    RequiredPatterns = @(
      "received expected ready count=3",
      "ready_seen_count=3",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "short"
    Name = "short scenario smoke"
    UvmTest = "conv_short_ready_test"
    ExpectedErrors = 0
    RequiredPatterns = @(
      "received expected ready count=1",
      "ready_seen_count=1",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "long"
    Name = "long scenario smoke"
    UvmTest = "conv_long_ready_test"
    ExpectedErrors = 0
    RequiredPatterns = @(
      "received expected ready count=5",
      "ready_seen_count=5",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "dat"
    Name = "dat plumbing smoke"
    UvmTest = "conv_dat_smoke_test"
    ExpectedErrors = 0
    RequiredPatterns = @(
      "opened dat file cnn_sti.dat",
      "read dat sample",
      "received expected ready count=1",
      "ready_seen_count=1",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "dut_input"
    Name = "dut input drive smoke"
    UvmTest = "conv_dut_input_drive_test"
    ExpectedErrors = 0
    RequiredPatterns = @(
      "opened dat file cnn_sti.dat",
      "read dat sample",
      "drive idata",
      "observed busy high",
      "received expected ready count=1",
      "ready_seen_count=1",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "layer0_write"
    Name = "layer0 write smoke"
    UvmTest = "conv_layer0_write_smoke_test"
    ExpectedErrors = 0
    RequiredPatterns = @(
      "opened dat file cnn_sti.dat",
      "drive idata",
      "observed layer0 write",
      "layer0 write check passed",
      "observed expected layer0 write count",
      "layer0_write_count=",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "layer1_path"
    Name = "layer1 path smoke"
    UvmTest = "conv_layer1_path_smoke_test"
    ExpectedErrors = 0
    RequiredPatterns = @(
      "opened dat file cnn_sti.dat",
      "drive idata",
      "observed layer0 write",
      "observed layer0 read",
      "observed layer1 write",
      "observed expected layer0 write count",
      "observed expected layer0 read count",
      "observed expected layer1 write count",
      "layer0_read_count=",
      "layer1_write_count=",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "l0_mem_feedback"
    Name = "l0 mem feedback smoke"
    UvmTest = "conv_l0_mem_feedback_smoke_test"
    ExpectedErrors = 0
    RequiredPatterns = @(
      "opened dat file cnn_sti.dat",
      "observed layer0 write",
      "served layer0 read",
      "observed layer0 read",
      "observed layer1 write",
      "observed expected layer0 write count",
      "observed expected layer0 read count",
      "observed expected layer1 write count",
      "layer0_read_count=",
      "layer1_write_count=",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "l0_expected"
    Name = "l0 expected compare smoke"
    UvmTest = "conv_l0_expected_smoke_test"
    ExpectedErrors = 0
    RunInAll = $false
    RequiredPatterns = @(
      "loaded layer0 expected file cnn_layer0_exp0.dat count=4096",
      "observed layer0 write",
      "served layer0 read",
      "layer0 expected compare passed count=4096",
      "observed expected layer0 write count=4096",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "l1_expected"
    Name = "l1 expected compare smoke"
    UvmTest = "conv_l1_expected_smoke_test"
    ExpectedErrors = 0
    RunInAll = $false
    RequiredPatterns = @(
      "loaded layer1 expected file cnn_layer1_exp0.dat count=1024",
      "served layer0 read",
      "observed layer1 write",
      "layer1 expected compare passed count=1024",
      "observed expected layer1 write count=1024",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "l0_addr_map"
    Name = "layer0 address map smoke"
    UvmTest = "conv_l0_address_map_smoke_test"
    ExpectedErrors = 0
    RunInAll = $false
    RequiredPatterns = @(
      "layer0 address map passed unique=4096 expected=4096",
      "observed expected layer0 write count=4096",
      "UVM_ERROR\s*:\s*0",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "l1_addr_map"
    Name = "layer1 address map smoke"
    UvmTest = "conv_l1_address_map_smoke_test"
    ExpectedErrors = 0
    RunInAll = $false
    RequiredPatterns = @(
      "layer1 address map passed unique=1024 expected=1024",
      "observed expected layer1 write count=1024",
      "UVM_ERROR\s*:\s*0",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "reset_inflight"
    Name = "reset-in-flight smoke"
    UvmTest = "conv_reset_inflight_test"
    ExpectedErrors = 0
    RunInAll = $false
    RequiredPatterns = @(
      "start reset-in-flight scenario",
      "observed reset during busy",
      "restart after reset",
      "received expected ready count=2",
      "observed expected layer1 write count=1024",
      "layer1 expected compare passed count=1024",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "protocol"
    Name = "protocol checker smoke"
    UvmTest = "conv_layer1_path_smoke_test"
    ExpectedErrors = 0
    RequiredPatterns = @(
      "protocol checker enabled",
      "observed layer0 write",
      "observed layer0 read",
      "observed layer1 write",
      "UVM_ERROR\s*:\s*0",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "protocol_negative"
    Name = "protocol negative smoke"
    UvmTest = "conv_protocol_negative_test"
    ExpectedErrors = 1
    RequiredPatterns = @(
      "injected ready while busy",
      "\[READY_WHILE_BUSY\]",
      "received expected ready count=2",
      "UVM_ERROR\s*:\s*1",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "fault_l0_data"
    Name = "layer0 data fault smoke"
    UvmTest = "conv_l0_expected_smoke_test"
    ExpectedErrors = 2
    RunInAll = $false
    RequiredPatterns = @(
      "loaded layer0 expected file cnn_layer0_exp0.dat count=4096",
      "layer0 expected mismatch addr=123",
      "layer0 expected compare failed",
      "UVM_ERROR\s*:\s*2",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "fault_l1_data"
    Name = "layer1 data fault smoke"
    UvmTest = "conv_l1_expected_smoke_test"
    ExpectedErrors = 2
    RunInAll = $false
    RequiredPatterns = @(
      "loaded layer1 expected file cnn_layer1_exp0.dat count=1024",
      "layer1 expected mismatch addr=17",
      "layer1 expected compare failed pass=1023 mismatch=1 expected=1024",
      "UVM_ERROR\s*:\s*2",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "fault_illegal_csel"
    Name = "illegal csel protocol fault smoke"
    UvmTest = "conv_protocol_csel_fault_test"
    ExpectedErrors = 1
    RunInAll = $false
    RequiredPatterns = @(
      "protocol checker enabled",
      "observed layer0 write",
      "\[CWR_ILLEGAL_CSEL\] cwr requires csel 001 or 011, got 010",
      "UVM_ERROR\s*:\s*1",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "fault_missing_l0"
    Name = "missing layer0 address fault smoke"
    UvmTest = "conv_l0_address_map_smoke_test"
    ExpectedErrors = 1
    RunInAll = $false
    RequiredPatterns = @(
      "\[L0_ADDR_MISSING\] missing layer0 write address=123",
      "layer0 address map failed unique=4095 missing=1 expected=4096",
      "observed expected layer0 write count=4095",
      "UVM_ERROR\s*:\s*1",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "fault_duplicate_l1"
    Name = "duplicate layer1 address fault smoke"
    UvmTest = "conv_l1_address_map_smoke_test"
    ExpectedErrors = 2
    RunInAll = $false
    RequiredPatterns = @(
      "\[L1_ADDR_DUPLICATE\] duplicate layer1 write address=0",
      "\[L1_ADDR_MISSING\] missing layer1 write address=1",
      "layer1 address map failed unique=1023 duplicate=1 missing=1 expected=1024",
      "observed expected layer1 write count=1024",
      "UVM_ERROR\s*:\s*2",
      "UVM_FATAL\s*:\s*0"
    )
  },
  [pscustomobject]@{
    Key = "negative"
    Name = "negative checker smoke"
    UvmTest = "conv_bad_ready_test"
    ExpectedErrors = 3
    RequiredPatterns = @(
      "expected ready_seen transaction",
      "received expected ready count=3",
      "ready_seen_count=0",
      "UVM_FATAL\s*:\s*0"
    )
  }
)

Compile-Smoke

$failed = 0
foreach ($case in $cases) {
  if ($Test -ne "all" -and $Test -ne $case.Key) {
    continue
  }
  if ($Test -eq "all" -and
      ($case.PSObject.Properties.Name -contains "RunInAll") -and
      !$case.RunInAll) {
    continue
  }

  $ok = Run-SmokeCase `
    -Name $case.Name `
    -UvmTest $case.UvmTest `
    -ExpectedErrors $case.ExpectedErrors `
    -RequiredPatterns $case.RequiredPatterns

  if (!$ok) {
    $failed++
  }
}

Move-LibraryToReport

Write-Host ""
Write-Host "Report: $ReportDir"

if ($failed -ne 0) {
  exit 1
}

Write-Host "[PASS] smoke regression completed"
exit 0
