# Cria atalhos versionados (Area de Trabalho e Menu Iniciar) apontando para win.ps1
#Requires -Version 5.1
param(
    [string]$ProjectRoot = $env:PROMPTAUX_HOME,
    [string]$VersionLabel = ''
)

$ErrorActionPreference = 'Stop'
if (-not $ProjectRoot) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}
$ProjectRoot = (Resolve-Path $ProjectRoot).Path
$env:PROMPTAUX_HOME = $ProjectRoot

function Get-PromptAuxInstalledVersion {
    param([string]$Root)
    $cfg = Join-Path $Root 'app\config.py'
    if (-not (Test-Path -LiteralPath $cfg)) { return '0.0.0' }
    $text = Get-Content -LiteralPath $cfg -Raw
    if ($text -match 'APP_VERSION\s*=\s*"([^"]+)"') { return $Matches[1].Trim() }
    return '0.0.0'
}

$version = if ($VersionLabel) { $VersionLabel.Trim() } else { Get-PromptAuxInstalledVersion -Root $ProjectRoot }
$ico = Join-Path $ProjectRoot 'imagens\logo.ico'
$launcherPs1 = Join-Path $ProjectRoot 'win.ps1'
$launcherCmd = Join-Path $ProjectRoot 'Iniciar-PromptAuxiliar.cmd'
$main = Join-Path $ProjectRoot 'main.py'
if (-not (Test-Path -LiteralPath $launcherPs1)) {
    throw "win.ps1 não encontrado em $ProjectRoot"
}
if (-not (Test-Path -LiteralPath $main)) {
    throw "main.py não encontrado em $ProjectRoot"
}

$useCmd = Test-Path -LiteralPath $launcherCmd
$wsh = New-Object -ComObject WScript.Shell
$shortcutFileName = "Prompt Auxiliar v$version.lnk"
$description = "Prompt Auxiliar v$version - Winget e Debloat"

function Set-PromptAuxShortcut {
    param([string]$LnkPath)
    $dir = Split-Path -Parent $LnkPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $s = $wsh.CreateShortcut($LnkPath)
    if ($useCmd) {
        $s.TargetPath = $launcherCmd
        $s.Arguments = ''
    } else {
        $s.TargetPath = 'powershell.exe'
        $s.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$launcherPs1`""
    }
    $s.WorkingDirectory = $ProjectRoot
    $s.WindowStyle = 1
    $s.Description = $description
    if (Test-Path -LiteralPath $ico) { $s.IconLocation = "$ico,0" }
    $s.Save()
}

function Remove-PromptAuxOldShortcuts {
    param(
        [string[]]$SearchDirs,
        [string]$KeepFileName
    )
    $removed = 0
    foreach ($dir in $SearchDirs) {
        if (-not (Test-Path -LiteralPath $dir)) { continue }
        Get-ChildItem -LiteralPath $dir -Filter 'Prompt Auxiliar*.lnk' -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne $KeepFileName } |
            ForEach-Object {
                Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
                Write-Host "  Removido atalho antigo: $($_.Name)" -ForegroundColor DarkGray
                $removed++
            }
    }
    return $removed
}

function Repair-PromptAuxShortcutFile {
    param([string]$LnkPath, [string]$ExpectedName)
    if (-not (Test-Path -LiteralPath $LnkPath)) { return $false }
    try {
        $leaf = Split-Path -Leaf $LnkPath
        if ($leaf -ne $ExpectedName) { return $false }
        $s = $wsh.CreateShortcut($LnkPath)
        $needsFix = $false
        if ($s.Arguments -match 'Atualizar-e-Iniciar\.ps1') { $needsFix = $true }
        if (-not $useCmd -and $s.Arguments -and $s.Arguments -notmatch [regex]::Escape($launcherPs1)) {
            $needsFix = $true
        }
        if ($useCmd -and $s.TargetPath -ne $launcherCmd) { $needsFix = $true }
        if ($s.Description -ne $description) { $needsFix = $true }
        if (-not $needsFix) { return $false }
        Set-PromptAuxShortcut -LnkPath $LnkPath
        return $true
    } catch {
        return $false
    }
}

$desktop = [Environment]::GetFolderPath('Desktop')
$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$searchDirs = @($desktop, $startMenu)

Remove-PromptAuxOldShortcuts -SearchDirs $searchDirs -KeepFileName $shortcutFileName | Out-Null

$targets = @(
    (Join-Path $desktop $shortcutFileName),
    (Join-Path $startMenu $shortcutFileName)
)

foreach ($lnkPath in $targets) {
    Set-PromptAuxShortcut -LnkPath $lnkPath
    Write-Host "Atalho: $lnkPath" -ForegroundColor Green
}

$repaired = 0
foreach ($dir in $searchDirs) {
    if (-not (Test-Path -LiteralPath $dir)) { continue }
    $expected = Join-Path $dir $shortcutFileName
    if (Repair-PromptAuxShortcutFile -LnkPath $expected -ExpectedName $shortcutFileName) {
        $repaired++
    }
}

if ($repaired -gt 0) {
    Write-Host "$repaired atalho(s) corrigido(s)." -ForegroundColor DarkGray
}

if ($useCmd) {
    Write-Host "Atalhos usam Iniciar-PromptAuxiliar.cmd (versão v$version)." -ForegroundColor DarkGray
} else {
    Write-Host "Atalhos usam win.ps1 com Bypass (versão v$version)." -ForegroundColor DarkGray
}
