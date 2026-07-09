# Prompt Auxiliar v2.8.0 — instalador (entry point IRM)
# irm "https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/install.ps1" | iex
#Requires -Version 5.1

$PromptAuxVersion = '2.8.0'
$ErrorActionPreference = 'Stop'

$DefaultWinUrl = if ($env:PROMPTAUX_WIN_URL) {
    $env:PROMPTAUX_WIN_URL
} else {
    'https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/win.ps1'
}

$localWin = if ($PSScriptRoot) { Join-Path $PSScriptRoot 'win.ps1' } else { $null }

if ($localWin -and (Test-Path -LiteralPath $localWin)) {
    & $localWin @args
    return
}

Write-Host "Prompt Auxiliar v$PromptAuxVersion — instalador remoto" -ForegroundColor Cyan
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $response = Invoke-WebRequest -Uri $DefaultWinUrl -UseBasicParsing
    $content = [string]$response.Content
    if ([string]::IsNullOrWhiteSpace($content)) {
        throw 'Resposta vazia do servidor.'
    }
    Invoke-Expression $content
} catch {
    throw "Falha ao baixar win.ps1 de $DefaultWinUrl. $_"
}
