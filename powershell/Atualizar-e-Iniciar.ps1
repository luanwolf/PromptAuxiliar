# Atualiza do GitHub (se houver versão nova) e abre o Prompt Auxiliar.
#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

$InstallRoot = if ($env:PROMPTAUX_HOME) {
    $env:PROMPTAUX_HOME
} else {
    Split-Path -Parent $PSScriptRoot
}
$InstallRoot = (Resolve-Path $InstallRoot).Path
$env:PROMPTAUX_HOME = $InstallRoot

$win = Join-Path $InstallRoot 'win.ps1'
if (-not (Test-Path -LiteralPath $win)) {
    throw "Instalação não encontrada: $InstallRoot`nExecute: irm `"https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/win.ps1`" | iex"
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $win
