param(
  [ValidateRange(1, 3)]
  [int]$MaxAttempts = 2,
  [switch]$ListOnly
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$SmokeScript = Join-Path $Root "run_smoke.ps1"
$RunStamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$ReportDir = Join-Path $Root ("reports\final_{0}" -f $RunStamp)

$cases = @(
  [pscustomobject]@{ Group = "Base";       Key = "all";                      Name = "default smoke regression" },
  [pscustomobject]@{ Group = "Golden";     Key = "l0_expected";              Name = "Layer0 golden compare" },
  [pscustomobject]@{ Group = "Golden";     Key = "l1_expected";              Name = "Layer1 golden compare" },
  [pscustomobject]@{ Group = "Address";    Key = "l0_addr_map";              Name = "Layer0 address map" },
  [pscustomobject]@{ Group = "Address";    Key = "l1_addr_map";              Name = "Layer1 address map" },
  [pscustomobject]@{ Group = "Reset";      Key = "reset_inflight";           Name = "reset-in-flight recovery" },
  [pscustomobject]@{ Group = "Baseline";   Key = "reset_protocol";           Name = "reset protocol baseline" },
  [pscustomobject]@{ Group = "Baseline";   Key = "ready_busy_liveness";      Name = "ready-to-busy liveness baseline" },
  [pscustomobject]@{ Group = "Fault";      Key = "fault_l0_data";            Name = "Layer0 data fault" },
  [pscustomobject]@{ Group = "Fault";      Key = "fault_l1_data";            Name = "Layer1 data fault" },
  [pscustomobject]@{ Group = "Fault";      Key = "fault_illegal_csel";       Name = "illegal csel fault" },
  [pscustomobject]@{ Group = "Fault";      Key = "fault_missing_l0";         Name = "missing Layer0 address fault" },
  [pscustomobject]@{ Group = "Fault";      Key = "fault_duplicate_l1";       Name = "duplicate Layer1 address fault" },
  [pscustomobject]@{ Group = "Fault";      Key = "fault_l1_addr_oob";        Name = "Layer1 address range fault" },
  [pscustomobject]@{ Group = "Fault";      Key = "fault_reset_protocol";     Name = "reset protocol fault" },
  [pscustomobject]@{ Group = "Fault";      Key = "fault_ready_busy_timeout"; Name = "ready-to-busy timeout fault" }
)

if (!(Test-Path -LiteralPath $SmokeScript)) {
  throw "missing smoke runner: $SmokeScript"
}

if ($ListOnly) {
  $cases | Format-Table Group, Key, Name -AutoSize
  exit 0
}

New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
Set-Location $Root

$results = @()

foreach ($case in $cases) {
  $passed = $false
  $attemptUsed = 0
  $caseLog = Join-Path $ReportDir ("{0}.console.log" -f $case.Key)
  Set-Content -Path $caseLog -Value ("Case: {0} ({1})" -f $case.Name, $case.Key)

  for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
    $attemptUsed = $attempt
    Write-Host ("[RUN ] {0} (attempt {1}/{2})" -f $case.Name, $attempt, $MaxAttempts)
    Add-Content -Path $caseLog -Value ("`r`n=== Attempt {0}/{1} ===" -f $attempt, $MaxAttempts)

    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
      $output = & powershell -ExecutionPolicy Bypass -File $SmokeScript -Test $case.Key 2>&1
      $exitCode = $LASTEXITCODE
    }
    finally {
      $ErrorActionPreference = $oldErrorActionPreference
    }

    $output | Add-Content -Path $caseLog
    $output | ForEach-Object { Write-Host $_ }

    if ($exitCode -eq 0) {
      $passed = $true
      break
    }

    if ($attempt -lt $MaxAttempts) {
      Write-Host ("[RETRY] {0}" -f $case.Name)
    }
  }

  $status = if ($passed) { "PASS" } else { "FAIL" }
  Write-Host ("[{0}] {1}" -f $status, $case.Name)
  $results += [pscustomobject]@{
    Group = $case.Group
    Test = $case.Key
    Name = $case.Name
    Result = $status
    Attempts = $attemptUsed
    Log = $caseLog
  }
}

$passCount = @($results | Where-Object { $_.Result -eq "PASS" }).Count
$failCount = $results.Count - $passCount
$overall = if ($failCount -eq 0) { "PASS" } else { "FAIL" }
$summaryPath = Join-Path $ReportDir "final_regression_summary.md"

$summary = @(
  "# Final Regression Summary",
  "",
  "- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')",
  "- Overall: **$overall**",
  "- Passed: $passCount/$($results.Count)",
  "- Failed: $failCount",
  "- Max attempts per case: $MaxAttempts",
  "",
  "| Group | Test | Description | Result | Attempts |",
  "|---|---|---|---:|---:|"
)

foreach ($result in $results) {
  $summary += "| $($result.Group) | ``$($result.Test)`` | $($result.Name) | $($result.Result) | $($result.Attempts) |"
}

$summary | Set-Content -Path $summaryPath

Write-Host ""
Write-Host "Final Regression Matrix"
$results | Format-Table Group, Test, Result, Attempts -AutoSize
Write-Host ("Result: {0} ({1}/{2} PASS)" -f $overall, $passCount, $results.Count)
Write-Host "Summary: $summaryPath"

if ($failCount -ne 0) {
  exit 1
}

exit 0
