# Repara atalhos que ainda apontam para Atualizar-e-Iniciar.ps1 ausente
#Requires -Version 5.1
param(
    [string]$ProjectRoot = $env:PROMPTAUX_HOME
)

$ErrorActionPreference = 'Stop'
if (-not $ProjectRoot) {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'PromptAuxiliar')
        (Split-Path -Parent $PSScriptRoot)
    )
    foreach ($c in $candidates) {
        if ((Test-Path -LiteralPath (Join-Path $c 'win.ps1'))) {
            $ProjectRoot = $c
            break
        }
    }
}
if (-not $ProjectRoot) {
    Write-Host 'Instalacao nao encontrada. Execute o instalador irm do GitHub.' -ForegroundColor Red
    exit 1
}

$criar = Join-Path $ProjectRoot 'powershell\Criar-Atalho.ps1'
if (-not (Test-Path -LiteralPath $criar)) {
    Write-Host "Criar-Atalho.ps1 nao encontrado em $ProjectRoot" -ForegroundColor Red
    exit 1
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $criar -ProjectRoot $ProjectRoot
Write-Host 'Pronto. Tente abrir o atalho Prompt Auxiliar novamente.' -ForegroundColor Green
