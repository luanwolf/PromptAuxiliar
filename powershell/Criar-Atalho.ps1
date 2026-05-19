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

$ico = Join-Path $ProjectRoot 'imagens\logo.ico'
$launcher = Join-Path $ProjectRoot 'powershell\Atualizar-e-Iniciar.ps1'
$main = Join-Path $ProjectRoot 'main.py'
if (-not (Test-Path -LiteralPath $launcher)) {
    throw "Atualizar-e-Iniciar.ps1 não encontrado em $ProjectRoot"
}

if (-not (Test-Path $ico)) {
    Write-Warning "Icone nao encontrado: $ico"
}
if (-not (Test-Path $main)) {
    throw "main.py nao encontrado em $ProjectRoot"
}

$desktop = [Environment]::GetFolderPath('Desktop')
$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$targets = @(
    (Join-Path $desktop 'Prompt Auxiliar.lnk'),
    (Join-Path $startMenu 'Prompt Auxiliar.lnk')
)

foreach ($lnkPath in $targets) {
    $s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnkPath)
    $s.TargetPath = 'powershell.exe'
    $s.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$launcher`""
    $s.WorkingDirectory = $ProjectRoot
    $s.WindowStyle = 1
    $s.Description = 'Prompt Auxiliar — Winget e Debloat'
    if (Test-Path $ico) { $s.IconLocation = "$ico,0" }
    $s.Save()
    Write-Host "Atalho: $lnkPath" -ForegroundColor Green
}

Write-Host "O atalho verifica atualizacoes no GitHub antes de abrir o app." -ForegroundColor DarkGray
