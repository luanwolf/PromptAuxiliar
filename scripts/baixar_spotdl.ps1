#Requires -Version 5.1
. "$PSScriptRoot\_ui.ps1"
. "$PSScriptRoot\_util_install.ps1"

$url  = $env:PA_UTIL_URL
$dest = $env:PA_UTIL_DEST

Show-PABanner "Download Spotify (spotdl)" "Baixa música ou playlist do Spotify em MP3."

if ([string]::IsNullOrWhiteSpace($url) -or [string]::IsNullOrWhiteSpace($dest)) {
    Write-Host '  URL ou pasta de destino não informados pelo app.' -ForegroundColor Red
    Read-Host '  Pressione Enter para fechar'
    exit 1
}

if (-not (Test-Path -LiteralPath $dest)) {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
}

Write-Host "  Link : $url" -ForegroundColor DarkGray
Write-Host "  Pasta: $dest" -ForegroundColor DarkGray
Write-Host ''

if (-not (Confirm-PAAction)) { exit 0 }

$startTime = Get-Date
$results   = [System.Collections.ArrayList]::new()

Invoke-PAStep "Verificar / instalar spotdl" $results {
    Ensure-PATool -CommandName 'spotdl' -WingetId '' -PipPackage 'spotdl'
}

Invoke-PAStep "Baixando do Spotify" $results {
    spotdl download $url --output $dest --format mp3
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "spotdl encerrou com código $LASTEXITCODE"
    }
}

Write-PASummary -Results $results -StartTime $startTime -Titulo "baixar_spotdl"
