param(
  [ValidateSet("all", "clean", "short", "long", "dat", "dut_input", "layer0_write", "layer1_path", "l0_mem_feedback", "l0_expected", "negative")]
  [string]$Test = "all"
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$UvmSrc = "C:\intelFPGA_lite\18.1\modelsim_ase\verilog_src\uvm-1.2\src"
$RunStamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$ReportDir = Join-Path $Root ("reports\smoke_{0}" -f $RunStamp)
$Lib = "smoke_$RunStamp"

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
    "+define+UVM_NO_DPI",
    "+incdir+$UvmSrc",
    (Join-Path $UvmSrc "uvm_pkg.sv"),
    "conv_if.sv",
    "conv_pkg.sv",
    "CONV.v",
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
