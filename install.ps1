# Prompt Auxiliar - instalador one-liner via irm
# irm "https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/install.ps1" | iex

$ErrorActionPreference = 'Stop'

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    $global:OutputEncoding     = [System.Text.Encoding]::UTF8
    if ($Host.Name -eq 'ConsoleHost') { chcp 65001 | Out-Null }
} catch {}

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
    $winPath = Join-Path $env:TEMP 'PromptAuxiliar-win.ps1'
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($winPath, $scriptText.TrimStart([char]0xFEFF), $utf8)
    & $winPath @args
}
