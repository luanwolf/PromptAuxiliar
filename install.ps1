# Alias do instalador — use win.ps1 no one-liner
# irm "https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/win.ps1" | iex
#Requires -Version 5.1

$localWin = if ($PSScriptRoot) { Join-Path $PSScriptRoot 'win.ps1' } else { $null }

if ($localWin -and (Test-Path $localWin)) {
    & $localWin @args
} else {
    $url = if ($env:PROMPTAUX_WIN_URL) {
        $env:PROMPTAUX_WIN_URL
    } else {
        'https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/win.ps1'
    }
    Invoke-Expression (Invoke-RestMethod -Uri $url -UseBasicParsing)
}
