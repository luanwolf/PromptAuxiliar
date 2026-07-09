# Cria atalho na Area de Trabalho e Menu Iniciar com icone do Prompt Auxiliar
#Requires -Version 5.1
param(
    [string]$ProjectRoot = $env:PROMPTAUX_HOME
)

$ErrorActionPreference = 'Stop'
if (-not $ProjectRoot) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}
$ProjectRoot = (Resolve-Path $ProjectRoot).Path

$iconScript = Join-Path $ProjectRoot 'scripts\build_icon.py'
$python = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $python) { $python = 'py' }

if ((Test-Path $iconScript) -and $python) {
    try {
        if ($python -eq 'py') {
            & py -3 $iconScript | Out-Null
        } else {
            & $python $iconScript | Out-Null
        }
    } catch {
        Write-Warning "Nao foi possivel regenerar logo.ico: $_"
    }
}

$ico = Join-Path $ProjectRoot 'imagens\logo.ico'
if (-not (Test-Path $ico)) {
    $ico = Join-Path $ProjectRoot 'web\assets\logo.ico'
}
$main = Join-Path $ProjectRoot 'main.py'
if (-not $python -or $python -eq 'py') {
    $python = (Get-Command python -ErrorAction SilentlyContinue).Source
}
if (-not $python) { $python = 'python' }

if (-not (Test-Path $main)) {
    throw "main.py nao encontrado em $ProjectRoot"
}

$version = '2.8.0'
$configPy = Join-Path $ProjectRoot 'app\config.py'
if (Test-Path $configPy) {
    $m = Select-String -Path $configPy -Pattern 'APP_VERSION\s*=\s*"([^"]+)"' | Select-Object -First 1
    if ($m) { $version = $m.Matches[0].Groups[1].Value }
}

$desktop = [Environment]::GetFolderPath('Desktop')
$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$targets = @(
    (Join-Path $desktop 'Prompt Auxiliar.lnk'),
    (Join-Path $startMenu 'Prompt Auxiliar.lnk')
)

foreach ($lnkPath in $targets) {
    $s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnkPath)
    $s.TargetPath = $python
    $s.Arguments = "`"$main`""
    $s.WorkingDirectory = $ProjectRoot
    $s.WindowStyle = 1
    $s.Description = "Prompt Auxiliar v$version - Winget, Debloat e scripts"
    if (Test-Path $ico) { $s.IconLocation = "$ico,0" }
    $s.Save()
    Write-Host "Atalho: $lnkPath" -ForegroundColor Green
}

Write-Host "Icone: $ico" -ForegroundColor DarkGray
