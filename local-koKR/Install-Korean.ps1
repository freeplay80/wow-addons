[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
$gameAddOns = 'D:\Blizzard Games\World of Warcraft\_forever_\Interface\AddOns'
$backupRoot = Join-Path $PSScriptRoot 'original'
$plan = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'install-plan.json') -Raw -Encoding UTF8 | ConvertFrom-Json)
if ($plan.Count -eq 0) { throw 'No verified changes to install.' }

function Assert-PlainItem([string]$Path, [bool]$Directory) {
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.PSIsContainer -ne $Directory -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "Unexpected path: $Path"
    }
}

function Get-RealHash([string]$Path) {
    $WhatIfPreference = $false
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

Assert-PlainItem $gameAddOns $true
if (Test-Path -LiteralPath $backupRoot) { throw "Backup directory already exists: $backupRoot" }

$entries = foreach ($entry in $plan) {
    if ($entry.relative -notmatch '^(?:Lueur|ForeverLootSparkles|HanharEnhancementHUD)\\(?:Locales\\)?[A-Za-z0-9_.-]+\.(?:lua|toc)$') {
        throw "Unexpected relative path: $($entry.relative)"
    }
    $source = Join-Path $PSScriptRoot $entry.relative
    $target = Join-Path $gameAddOns $entry.relative
    $backup = Join-Path $backupRoot $entry.relative
    $addon = ($entry.relative -split '\\')[0]
    Assert-PlainItem (Join-Path $gameAddOns $addon) $true
    Assert-PlainItem (Split-Path -Parent $target) $true
    Assert-PlainItem $source $false
    if ((Get-RealHash $source) -ne $entry.after) { throw "Staged file changed: $source" }
    if (Test-Path -LiteralPath $target) {
        Assert-PlainItem $target $false
        if ((Get-RealHash $target) -ne $entry.before) { throw "Installed file changed: $target" }
    } elseif ($entry.before) {
        throw "Installed file is missing: $target"
    }
    [pscustomobject]@{ Source = $source; Target = $target; Backup = $backup; Before = $entry.before; After = $entry.after }
}

if ($PSCmdlet.ShouldProcess($gameAddOns, "Backup existing files and install $($entries.Count) verified Korean UI files")) {
    foreach ($entry in $entries) {
        if ($entry.Before) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $entry.Backup) -Force | Out-Null
            Copy-Item -LiteralPath $entry.Target -Destination $entry.Backup
            if ((Get-RealHash $entry.Backup) -ne $entry.Before) { throw "Backup hash mismatch: $($entry.Backup)" }
        }
    }
    foreach ($entry in $entries) {
        Copy-Item -LiteralPath $entry.Source -Destination $entry.Target -Force
        if ((Get-RealHash $entry.Target) -ne $entry.After) { throw "Installed file hash mismatch: $($entry.Target)" }
    }
    Write-Output "Installed and verified $($entries.Count) files in $gameAddOns"
    Write-Output "Original files: $backupRoot"
}
