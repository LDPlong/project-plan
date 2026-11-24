#Requires -Version 5.1
<#
.SYNOPSIS
    Runs the positive and negative cases for check-plan.ps1.

.DESCRIPTION
    Creates a temporary directory, generates PLAN.md fixtures, runs the checker
    in a child process for each case, and compares the exit code and output.

    Exit code 0 when every case passes, 1 otherwise.

.PARAMETER CheckerPath
    Path to check-plan.ps1. Defaults to the copy inside the skill directory.

.PARAMETER KeepTemp
    Keep the temporary directory for inspection.

.EXAMPLE
    powershell -File scripts/verify-skill.ps1

.EXAMPLE
    powershell -File scripts/verify-skill.ps1 -KeepTemp
#>
[CmdletBinding()]
param(
    [string]$CheckerPath = (Join-Path $PSScriptRoot '../skills/project-plan/scripts/check-plan.ps1'),
    [switch]$KeepTemp
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$checker = [System.IO.Path]::GetFullPath($CheckerPath)
$template = Join-Path $repoRoot 'skills/project-plan/references/PLAN-template.md'

foreach ($required in @($checker, $template)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        Write-Host "[FAIL] Missing file: $required" -ForegroundColor Red
        exit 1
    }
}

$hostExe = 'powershell'
try { $hostExe = (Get-Process -Id $PID).Path } catch { }
$onWindows = ($env:OS -eq 'Windows_NT')

$workDir = Join-Path ([System.IO.Path]::GetTempPath()) ('pp-verify-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $workDir -Force | Out-Null

$script:caseIndex = 0
$script:passed = 0
$script:failed = 0

function New-Plan {
    param([hashtable]$Override = @{})

    $sections = [ordered]@{
        '目标'       = @('Ship it; acceptance: works')
        '非目标'     = @('- nothing')
        '当前里程碑' = @('M1')
        '进行中'     = @('- [ ] T1 first task')
        '待做'       = @('- [ ] T2 second task')
        '决策'       = @('- 2026-11-24 JWT: stateless deploy')
        '坑'         = @('- local PG required, otherwise P1001')
        '归档'       = @()
    }

    foreach ($key in @($Override.Keys)) {
        if ($null -eq $Override[$key]) { $sections.Remove($key) }
        else { $sections[$key] = @($Override[$key]) }
    }

    $builder = New-Object System.Text.StringBuilder
    foreach ($key in $sections.Keys) {
        [void]$builder.AppendLine("## $key")
        foreach ($line in $sections[$key]) { [void]$builder.AppendLine($line) }
        [void]$builder.AppendLine()
    }
    $builder.ToString()
}

function Invoke-Case {
    param(
        [string]$Name,
        [string]$Plan,
        [int]$ExpectedExit,
        [string[]]$ExpectPattern = @(),
        [string[]]$RejectPattern = @(),
        [int]$MaxAgeDays = 0,
        [int]$TouchDaysAgo = 0,
        [switch]$NoFile
    )

    $script:caseIndex++
    $file = Join-Path $workDir ('case-{0:D2}.md' -f $script:caseIndex)

    if (-not $NoFile) {
        [System.IO.File]::WriteAllText($file, $Plan, (New-Object System.Text.UTF8Encoding($false)))
        if ($TouchDaysAgo -gt 0) {
            (Get-Item -LiteralPath $file).LastWriteTime = (Get-Date).AddDays(-$TouchDaysAgo)
        }
    }

    $arguments = @('-NoProfile', '-File', $checker, '-Path', $file, '-MaxAgeDays', "$MaxAgeDays")
    if ($onWindows) { $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $checker, '-Path', $file, '-MaxAgeDays', "$MaxAgeDays") }

    $output = (& $hostExe @arguments 2>&1 | Out-String)
    $actualExit = $LASTEXITCODE

    $problems = New-Object System.Collections.Generic.List[string]
    if ($actualExit -ne $ExpectedExit) {
        $problems.Add("exit code $actualExit, expected $ExpectedExit")
    }
    foreach ($pattern in $ExpectPattern) {
        if ($output -notmatch $pattern) { $problems.Add("missing output /$pattern/") }
    }
    foreach ($pattern in $RejectPattern) {
        if ($output -match $pattern) { $problems.Add("unexpected output /$pattern/") }
    }

    if ($problems.Count -eq 0) {
        $script:passed++
        Write-Host "[PASS] $Name" -ForegroundColor Green
    }
    else {
        $script:failed++
        Write-Host "[FAIL] $Name" -ForegroundColor Red
        foreach ($problem in $problems) { Write-Host "       $problem" -ForegroundColor Red }
        Write-Host '       --- checker output ---'
        foreach ($line in ($output -split "`r?`n")) {
            if ($line.Trim() -ne '') { Write-Host "       $line" }
        }
    }
}

try {
    $validPlan = New-Plan

    Invoke-Case -Name 'valid plan passes' -Plan $validPlan -ExpectedExit 0 `
        -ExpectPattern @('\[OK\]', 'warnings 0')

    Invoke-Case -Name 'missing 非目标 fails' -Plan (New-Plan @{ '非目标' = $null }) -ExpectedExit 1 `
        -ExpectPattern @('Missing section: ## 非目标')

    Invoke-Case -Name 'two unchecked tasks fail' -Plan (New-Plan @{ '进行中' = @('- [ ] T1', '- [ ] T2') }) -ExpectedExit 1 `
        -ExpectPattern @('at most 1 allowed')

    Invoke-Case -Name 'checked item in 进行中 warns' -Plan (New-Plan @{ '进行中' = @('- [x] T1 done') }) -ExpectedExit 0 `
        -ExpectPattern @('进行中 has 1 checked')

    Invoke-Case -Name 'checked item in 待做 warns' -Plan (New-Plan @{ '待做' = @('- [x] T2 done') }) -ExpectedExit 0 `
        -ExpectPattern @('待做 has 1 checked')

    $duplicate = $validPlan.Replace("## 非目标", "## 目标`nduplicate goal`n`n## 非目标")
    Invoke-Case -Name 'duplicate section fails' -Plan $duplicate -ExpectedExit 1 `
        -ExpectPattern @('Duplicate section: ## 目标')

    $templateText = Get-Content -Raw -LiteralPath $template -Encoding UTF8
    Invoke-Case -Name 'untouched template fails' -Plan $templateText -ExpectedExit 1 `
        -ExpectPattern @('placeholder')

    $longTodo = @(1..60 | ForEach-Object { "- [ ] task $_" })
    Invoke-Case -Name 'too many lines fail' -Plan (New-Plan @{ '待做' = $longTodo }) -ExpectedExit 1 `
        -ExpectPattern @('limit: 50')

    Invoke-Case -Name 'stale plan warns' -Plan $validPlan -ExpectedExit 0 -MaxAgeDays 14 -TouchDaysAgo 30 `
        -ExpectPattern @('days while a task is in progress')

    Invoke-Case -Name 'MaxAgeDays 0 disables staleness' -Plan $validPlan -ExpectedExit 0 -MaxAgeDays 0 -TouchDaysAgo 30 `
        -RejectPattern @('days while a task is in progress')

    Invoke-Case -Name 'goal without acceptance wording warns' -Plan (New-Plan @{ '目标' = @('Ship it') }) -ExpectedExit 0 `
        -ExpectPattern @('acceptance')

    Invoke-Case -Name 'missing 当前里程碑 warns' -Plan (New-Plan @{ '当前里程碑' = $null }) -ExpectedExit 0 `
        -ExpectPattern @('当前里程碑 is missing')

    Invoke-Case -Name 'missing file fails' -Plan '' -ExpectedExit 1 -NoFile `
        -ExpectPattern @('not found')

    Invoke-Case -Name 'headings inside code fences are ignored' -Plan (New-Plan @{ '坑' = @('- example:', '```markdown', '## 目标', '```') }) -ExpectedExit 0 `
        -ExpectPattern @('\[OK\]') -RejectPattern @('Duplicate section')

    Invoke-Case -Name 'empty 进行中 warns' -Plan (New-Plan @{ '进行中' = @() }) -ExpectedExit 0 `
        -ExpectPattern @('No task is in progress')
}
finally {
    if ($KeepTemp) {
        Write-Host "Temp directory kept: $workDir" -ForegroundColor Yellow
    }
    else {
        Remove-Item -LiteralPath $workDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$total = $script:passed + $script:failed
Write-Host ''
Write-Host ("{0}/{1} cases passed" -f $script:passed, $total) -ForegroundColor ($(if ($script:failed -eq 0) { 'Green' } else { 'Red' }))
if ($script:failed -gt 0) { exit 1 }
exit 0