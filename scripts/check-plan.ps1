#Requires -Version 5.1
<#
.SYNOPSIS
    校验 PLAN.md 的结构与规模，避免清单腐化。

.DESCRIPTION
    检查项：
      1. 必备章节齐全：目标 / 进行中 / 待做 / 决策 / 坑
      2. 「目标」非空且不是占位符
      3. 「进行中」最多 1 条
      4. 有效行数不超过 -MaxLines（默认 50）

.PARAMETER Path
    PLAN.md 路径，默认当前目录下的 PLAN.md。

.PARAMETER MaxLines
    有效行数上限，默认 50。

.EXAMPLE
    powershell -File scripts/check-plan.ps1
#>
[CmdletBinding()]
param(
    [string]$Path = (Join-Path (Get-Location) 'PLAN.md'),
    [int]$MaxLines = 50
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    Write-Host "[FAIL] 找不到计划文件：$Path" -ForegroundColor Red
    exit 1
}

$lines = @(Get-Content -LiteralPath $Path -Encoding UTF8)
$sections = @{}
$current = $null
$inFence = $false

foreach ($line in $lines) {
    if ($line -match '^\s*(```|~~~)') { $inFence = -not $inFence }
    if (-not $inFence -and $line -match '^##\s+(.+?)\s*$') {
        $current = $Matches[1]
        if (-not $sections.ContainsKey($current)) {
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

$problems = New-Object System.Collections.Generic.List[string]

foreach ($name in @('目标', '进行中', '待做', '决策', '坑')) {
    if (-not $sections.ContainsKey($name)) { $problems.Add("缺少章节：## $name") }
}

$goalLines = @(Get-SectionLines '目标' | Where-Object { $_.Trim() -ne '' })
$goal = ($goalLines -join ' ').Trim()
if ($goal -eq '' -or $goal -match '^<.*>$') {
    $problems.Add('「目标」为空或仍是占位符')
}

$doing = @(Get-SectionLines '进行中' | Where-Object { $_ -match '^\s*-\s\[ \]' })
$todo = @(Get-SectionLines '待做' | Where-Object { $_ -match '^\s*-\s\[ \]' })

if ($doing.Count -gt 1) {
    $problems.Add("「进行中」有 $($doing.Count) 条，最多允许 1 条")
}
if ($doing.Count -eq 0) {
    Write-Host '[WARN] 「进行中」为空：确认是否真的没有在做的任务' -ForegroundColor Yellow
}

$effective = @($lines | Where-Object { $_.Trim() -ne '' }).Count
if ($effective -gt $MaxLines) {
    $problems.Add("有效行数 $effective 超过上限 $MaxLines，请归档旧里程碑")
}

if ($problems.Count -gt 0) {
    foreach ($problem in $problems) {
        Write-Host "[FAIL] $problem" -ForegroundColor Red
    }
    exit 1
}

Write-Host ("[OK] {0}：有效行 {1}/{2}，进行中 {3}，待做 {4}" -f (Split-Path -Leaf $Path), $effective, $MaxLines, $doing.Count, $todo.Count) -ForegroundColor Green
exit 0