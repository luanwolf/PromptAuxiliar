﻿# Atualiza do GitHub (se houver versao nova) e abre o Prompt Auxiliar.
#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

function Wait-PromptAuxEnter {
    Write-Host ''
    Write-Host 'Pressione Enter para fechar...' -ForegroundColor Yellow
    Read-Host | Out-Null
}

$InstallRoot = if ($env:PROMPTAUX_HOME) {
    $env:PROMPTAUX_HOME
} else {
    Split-Path -Parent $PSScriptRoot
}
$InstallRoot = (Resolve-Path $InstallRoot).Path
$env:PROMPTAUX_HOME = $InstallRoot

$win = Join-Path $InstallRoot 'win.ps1'
if (-not (Test-Path -LiteralPath $win)) {
    Write-Host "Instalacao nao encontrada: $InstallRoot" -ForegroundColor Red
    Write-Host 'Execute: irm "https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/win.ps1" | iex'
    Wait-PromptAuxEnter
    exit 1
}

try {
    & $win
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "win.ps1 retornou codigo $LASTEXITCODE"
    }
} catch {
    Write-Host ''
    Write-Host "ERRO: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.InvocationInfo.PositionMessage) {
        Write-Host $_.InvocationInfo.PositionMessage -ForegroundColor DarkGray
    }
    Wait-PromptAuxEnter
    exit 1
}
