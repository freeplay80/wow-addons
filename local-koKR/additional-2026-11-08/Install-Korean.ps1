[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
$gameAddOns = 'D:\Blizzard Games\World of Warcraft\_forever_\Interface\AddOns'
$sourceRoot = Join-Path $PSScriptRoot 'source'
$backupRoot = Join-Path $PSScriptRoot 'original'
$plan = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'install-plan.json') -Raw -Encoding UTF8 | ConvertFrom-Json)
if ($plan.Count -ne 11) { throw 'Unexpected installation plan.' }

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
Assert-PlainItem $sourceRoot $true
Assert-PlainItem $backupRoot $true

# All sources, backups and live files must match the verified versions before any write.
$entries = foreach ($entry in $plan) {
    if ($entry.relative -notmatch '^(KeepOrSell|ForeverMap|Leatrix_Plus|Questie|QuestieTrace|HanharEnhancementHUD)\\[A-Za-z0-9_.\\-]+\.(lua|toc)$' -or
        ($entry.relative -split '\\') -contains '..') {
        throw "Unexpected relative path: $($entry.relative)"
    }
    $source = Join-Path $sourceRoot $entry.relative
    $backup = Join-Path $backupRoot $entry.relative
    $target = Join-Path $gameAddOns $entry.relative
    $addon = ($entry.relative -split '\\')[0]
    Assert-PlainItem (Join-Path $gameAddOns $addon) $true
    Assert-PlainItem (Split-Path -Parent $target) $true
    foreach ($file in @($source, $backup, $target)) { Assert-PlainItem $file $false }
    if ((Get-RealHash $source) -ne $entry.after) { throw "Source changed: $source" }
    if ((Get-RealHash $backup) -ne $entry.before) { throw "Backup changed: $backup" }
    if ((Get-RealHash $target) -ne $entry.before) { throw "Installed file changed: $target" }
    [pscustomobject]@{ Source = $source; Backup = $backup; Target = $target; Hash = $entry.after }
}
if ($PSCmdlet.ShouldProcess($gameAddOns, "설치된 애드온의 번역 파일 $($entries.Count)개를 검증본으로 갱신")) {
    foreach ($entry in $entries) {
        Copy-Item -LiteralPath $entry.Source -Destination $entry.Target -Force
        if ((Get-RealHash $entry.Target) -ne $entry.Hash) { throw "Copy mismatch: $($entry.Target)" }
    }
    Write-Output "Installed and SHA-256 verified $($entries.Count) files in $gameAddOns"
    Write-Output "Backup: $backupRoot"
}
