#Requires -Version 5.1
<#
.SYNOPSIS
    Validates the structure and freshness of PLAN.md.

.DESCRIPTION
    Fails with exit code 1 when:
      - a required section is missing: 目标 / 非目标 / 进行中 / 待做 / 决策 / 坑
      - a section heading appears more than once
      - 目标 is empty or still a placeholder
      - 进行中 has more than one unchecked task
      - the number of non-empty lines exceeds -MaxLines

    Warns without changing the exit code when:
      - 当前里程碑 is missing
      - 进行中 has no unchecked task, or still contains checked items
      - 待做 still contains checked items
      - 目标 has no acceptance wording (验收 / acceptance)
      - the file has not been updated for -MaxAgeDays while a task is in progress

.PARAMETER Path
    Path to PLAN.md. Defaults to PLAN.md in the current directory.

.PARAMETER MaxLines
    Maximum number of non-empty lines. Defaults to 50.

.PARAMETER MaxAgeDays
    Warn when PLAN.md has not been modified for this many days and a task is
    in progress. Use 0 to disable. Defaults to 14.

.EXAMPLE
    powershell -File scripts/check-plan.ps1 -Path PLAN.md

.EXAMPLE
    powershell -File scripts/check-plan.ps1 -Path PLAN.md -MaxAgeDays 0
#>
[CmdletBinding()]
param(
    [string]$Path = (Join-Path (Get-Location) 'PLAN.md'),
    [int]$MaxLines = 50,
    [int]$MaxAgeDays = 14
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    Write-Host "[FAIL] Plan file not found: $Path" -ForegroundColor Red
    exit 1
}

$lines = @(Get-Content -LiteralPath $Path -Encoding UTF8)
$sections = @{}
$duplicates = New-Object System.Collections.Generic.List[string]
$current = $null
$inFence = $false

foreach ($line in $lines) {
    if ($line -match '^\s*(```|~~~)') { $inFence = -not $inFence }
    if (-not $inFence -and $line -match '^##\s+(.+?)\s*$') {
        $current = $Matches[1]
        if ($sections.ContainsKey($current)) {
            $duplicates.Add($current)
        }
        else {
            $sections[$current] = New-Object System.Collections.Generic.List[string]
        }
    }
    elseif ($null -ne $current) {
        $sections[$current].Add($line)
    }
}

function Get-SectionLines {
    param([string]$Name)
    if ($sections.ContainsKey($Name)) { return @($sections[$Name]) }
    return @()
}

$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

$required = @('目标', '非目标', '进行中', '待做', '决策', '坑')
foreach ($name in $required) {
    if (-not $sections.ContainsKey($name)) { $failures.Add("Missing section: ## $name") }
}
if (-not $sections.ContainsKey('当前里程碑')) {
    $warnings.Add('Section 当前里程碑 is missing; add the current milestone name')
}
foreach ($name in $duplicates) {
    $failures.Add("Duplicate section: ## $name")
}

$goalLines = @(Get-SectionLines '目标' | Where-Object { $_.Trim() -ne '' })
$goal = ($goalLines -join ' ').Trim()
if ($goal -eq '' -or $goal -match '^<.*>$') {
    $failures.Add('Section 目标 is empty or still a placeholder')
}
elseif ($goal -notmatch '验收|acceptance') {
    $warnings.Add('Section 目标 has no acceptance wording; add how completion is verified')
}

$doing = @(Get-SectionLines '进行中' | Where-Object { $_ -match '^\s*-\s\[ \]' })
$doneInDoing = @(Get-SectionLines '进行中' | Where-Object { $_ -match '^\s*-\s\[[xX]\]' })
$todo = @(Get-SectionLines '待做' | Where-Object { $_ -match '^\s*-\s\[ \]' })
$doneInTodo = @(Get-SectionLines '待做' | Where-Object { $_ -match '^\s*-\s\[[xX]\]' })

if ($doing.Count -gt 1) {
    $failures.Add("Section 进行中 has $($doing.Count) unchecked items; at most 1 allowed")
}
if ($doneInDoing.Count -gt 0) {
    $warnings.Add("Section 进行中 has $($doneInDoing.Count) checked item(s); move them to 归档")
}
if ($doneInTodo.Count -gt 0) {
    $warnings.Add("Section 待做 has $($doneInTodo.Count) checked item(s); move them to 归档")
}
if ($doing.Count -eq 0 -and $doneInDoing.Count -eq 0) {
    $warnings.Add('No task is in progress')
}

$effective = @($lines | Where-Object { $_.Trim() -ne '' }).Count
if ($effective -gt $MaxLines) {
    $failures.Add("Non-empty lines: $effective, limit: $MaxLines; archive finished milestones or move old decisions to docs/plan-archive.md")
}

if ($MaxAgeDays -gt 0 -and $doing.Count -gt 0) {
    $ageDays = ((Get-Date) - (Get-Item -LiteralPath $Path).LastWriteTime).TotalDays
    if ($ageDays -gt $MaxAgeDays) {
        $warnings.Add(("PLAN.md has not been updated for {0:N0} days while a task is in progress" -f $ageDays))
    }
}

foreach ($message in $warnings) {
    Write-Host "[WARN] $message" -ForegroundColor Yellow
}
if ($failures.Count -gt 0) {
    foreach ($message in $failures) {
        Write-Host "[FAIL] $message" -ForegroundColor Red
    }
    exit 1
}

Write-Host ("[OK] {0}: {1}/{2} lines, in progress {3}, todo {4}, warnings {5}" -f `
    (Split-Path -Leaf $Path), $effective, $MaxLines, $doing.Count, $todo.Count, $warnings.Count) -ForegroundColor Green
exit 0