#Requires -Version 5.1
<#
.SYNOPSIS
    Installs the project-plan skill into the Codex skills directory.

.DESCRIPTION
    Copies skills/project-plan to the target directory, then removes files that
    no longer exist in the source. Use -KeepExtra to skip the cleanup.

.PARAMETER Target
    Installation directory. Defaults to ~/.codex/skills/project-plan.

.PARAMETER KeepExtra
    Keep files that exist in the target but not in the source.

.EXAMPLE
    powershell -File scripts/install.ps1

.EXAMPLE
    powershell -File scripts/install.ps1 -Target D:\path\to\skills\project-plan -KeepExtra
#>
[CmdletBinding()]
param(
    [string]$Target = (Join-Path $env:USERPROFILE '.codex\skills\project-plan'),
    [switch]$KeepExtra
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repoRoot 'skills\project-plan'

if (-not (Test-Path -LiteralPath (Join-Path $source 'SKILL.md') -PathType Leaf)) {
    throw "Skill source not found: $source\SKILL.md"
}

$splitChars = [char[]]@('\', '/')
$targetFull = [System.IO.Path]::GetFullPath($Target).TrimEnd($splitChars)
$driveRoot = [System.IO.Path]::GetPathRoot($targetFull).TrimEnd($splitChars)
if ($targetFull -eq $driveRoot) {
    throw "Refusing to install into a drive root: $targetFull"
}

New-Item -ItemType Directory -Path $targetFull -Force | Out-Null
Copy-Item -Path (Join-Path $source '*') -Destination $targetFull -Recurse -Force

Write-Host "[OK] Installed to $targetFull" -ForegroundColor Green

if (-not $KeepExtra) {
    $sourceNames = @{}
    Get-ChildItem -LiteralPath $source -Recurse -File | ForEach-Object {
        $sourceNames[$_.FullName.Substring($source.Length + 1)] = $true
    }

    $extra = @(Get-ChildItem -LiteralPath $targetFull -Recurse -File | Where-Object {
        -not $sourceNames.ContainsKey($_.FullName.Substring($targetFull.Length + 1))
    })

    foreach ($file in $extra) {
        $relative = $file.FullName.Substring($targetFull.Length + 1)
        Remove-Item -LiteralPath $file.FullName -Force
        Write-Host "  - removed $relative" -ForegroundColor Yellow
    }
}

Get-ChildItem -LiteralPath $targetFull -Recurse -File |
    ForEach-Object { Write-Host ('  = ' + $_.FullName.Substring($targetFull.Length + 1)) }