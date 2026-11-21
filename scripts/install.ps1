#Requires -Version 5.1
<#
.SYNOPSIS
    把本仓库的 project-plan skill 安装到 Codex 的 skills 目录。

.PARAMETER Target
    安装目标目录，默认 ~/.codex/skills/project-plan。

.EXAMPLE
    powershell -File scripts/install.ps1
#>
[CmdletBinding()]
param(
    [string]$Target = (Join-Path $env:USERPROFILE '.codex\skills\project-plan')
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repoRoot 'skills\project-plan'

if (-not (Test-Path -LiteralPath (Join-Path $source 'SKILL.md') -PathType Leaf)) {
    throw "找不到 skill 源文件：$source\SKILL.md"
}

New-Item -ItemType Directory -Path $Target -Force | Out-Null
Copy-Item -Path (Join-Path $source '*') -Destination $Target -Recurse -Force

Write-Host "[OK] 已安装到 $Target" -ForegroundColor Green
Get-ChildItem -LiteralPath $Target -Recurse -File |
    ForEach-Object { Write-Host ('  - ' + $_.FullName.Substring($Target.Length + 1)) }