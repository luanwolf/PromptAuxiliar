# Instalador com Bypass na sessao (recomendado no one-liner)
# irm "https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/install.ps1" | iex
#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

try {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
} catch {
    Write-Warning 'Nao foi possivel usar Bypass nesta sessao. Tente abrir o PowerShell como usuario normal.'
}

$localWin = if ($PSScriptRoot) { Join-Path $PSScriptRoot 'win.ps1' } else { $null }

if ($localWin -and (Test-Path -LiteralPath $localWin)) {
    & $localWin @args
} else {
    $url = if ($env:PROMPTAUX_WIN_URL) {
        $env:PROMPTAUX_WIN_URL
    } else {
        'https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/win.ps1'
    }
    $scriptText = (Invoke-WebRequest -Uri $url -UseBasicParsing -Headers @{
        'User-Agent' = 'PromptAuxiliar-Installer'
    }).Content
    Invoke-Expression $scriptText
}
