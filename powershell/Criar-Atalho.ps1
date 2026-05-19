# Cria ou corrige atalhos (Area de Trabalho e Menu Iniciar) para win.ps1
#Requires -Version 5.1
param(
    [string]$ProjectRoot = $env:PROMPTAUX_HOME
)

$ErrorActionPreference = 'Stop'
if (-not $ProjectRoot) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}
$ProjectRoot = (Resolve-Path $ProjectRoot).Path
$env:PROMPTAUX_HOME = $ProjectRoot

$ico = Join-Path $ProjectRoot 'imagens\logo.ico'
$launcher = Join-Path $ProjectRoot 'win.ps1'
$main = Join-Path $ProjectRoot 'main.py'
if (-not (Test-Path -LiteralPath $launcher)) {
    throw "win.ps1 nao encontrado em $ProjectRoot"
}
if (-not (Test-Path -LiteralPath $main)) {
    throw "main.py nao encontrado em $ProjectRoot"
}

$argLine = "-NoProfile -ExecutionPolicy Bypass -File `"$launcher`""
$wsh = New-Object -ComObject WScript.Shell

function Set-PromptAuxShortcut {
    param([string]$LnkPath)
    $dir = Split-Path -Parent $LnkPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $s = $wsh.CreateShortcut($LnkPath)
    $s.TargetPath = 'powershell.exe'
    $s.Arguments = $argLine
    $s.WorkingDirectory = $ProjectRoot
    $s.WindowStyle = 1
    $s.Description = 'Prompt Auxiliar - Winget e Debloat'
    if (Test-Path -LiteralPath $ico) { $s.IconLocation = "$ico,0" }
    $s.Save()
}

function Repair-PromptAuxShortcutFile {
    param([string]$LnkPath)
    if (-not (Test-Path -LiteralPath $LnkPath)) { return $false }
    try {
        $s = $wsh.CreateShortcut($LnkPath)
        $args = $s.Arguments
        $needsFix = $false
        if ($args -match 'Atualizar-e-Iniciar\.ps1') { $needsFix = $true }
        if ($args -and $args -notmatch [regex]::Escape($launcher)) { $needsFix = $true }
        if (-not $needsFix) { return $false }
        Set-PromptAuxShortcut -LnkPath $LnkPath
        return $true
    } catch {
        return $false
    }
}

$desktop = [Environment]::GetFolderPath('Desktop')
$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$targets = @(
    (Join-Path $desktop 'Prompt Auxiliar.lnk'),
    (Join-Path $startMenu 'Prompt Auxiliar.lnk')
)

$repaired = 0
foreach ($lnkPath in $targets) {
    Set-PromptAuxShortcut -LnkPath $lnkPath
    Write-Host "Atalho: $lnkPath" -ForegroundColor Green
}

$scanDirs = @($desktop, $startMenu)
foreach ($dir in $scanDirs) {
    if (-not (Test-Path -LiteralPath $dir)) { continue }
    Get-ChildItem -LiteralPath $dir -Filter '*.lnk' -File -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $s = $wsh.CreateShortcut($_.FullName)
            if ($s.Description -match 'Prompt Auxiliar' -or $_.Name -match 'Prompt Auxiliar') {
                if (Repair-PromptAuxShortcutFile -LnkPath $_.FullName) {
                    $repaired++
                    Write-Host "Corrigido: $($_.FullName)" -ForegroundColor Cyan
                }
            }
        } catch { }
    }
}

if ($repaired -gt 0) {
    Write-Host "$repaired atalho(s) antigo(s) atualizado(s) para win.ps1." -ForegroundColor DarkGray
}
