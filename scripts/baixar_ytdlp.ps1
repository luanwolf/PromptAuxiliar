#Requires -Version 5.1
. "$PSScriptRoot\_ui.ps1"
. "$PSScriptRoot\_util_install.ps1"

$url      = $env:PA_UTIL_URL
$dest     = $env:PA_UTIL_DEST
$mode     = if ($env:PA_UTIL_MODE -eq 'audio') { 'audio' } else { 'video' }
$playlist = -not ($env:PA_UTIL_PLAYLIST -eq '0' -or $env:PA_UTIL_PLAYLIST -eq 'false')

Show-PABanner "Download (yt-dlp)" "Baixa video, musica ou playlist do YouTube e outros sites."

if ([string]::IsNullOrWhiteSpace($url) -or [string]::IsNullOrWhiteSpace($dest)) {
    Write-Host '  URL ou pasta de destino nao informados pelo app.' -ForegroundColor Red
    Read-Host '  Pressione Enter para fechar'
    exit 1
}

if (-not (Test-Path -LiteralPath $dest)) {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
}

$modoLabel = if ($mode -eq 'audio') { 'Somente audio (MP3)' } else { 'Video (MP4)' }
$plLabel   = if ($playlist) { 'Sim (playlist inteira)' } else { 'Nao (apenas este link)' }
Write-Host "  Link     : $url" -ForegroundColor DarkGray
Write-Host "  Pasta    : $dest" -ForegroundColor DarkGray
Write-Host "  Modo     : $modoLabel" -ForegroundColor DarkGray
Write-Host "  Playlist : $plLabel" -ForegroundColor DarkGray
Write-Host ''

if (-not (Confirm-PAAction)) { exit 0 }

$startTime = Get-Date
$results   = [System.Collections.ArrayList]::new()

Invoke-PAStep "Verificar / instalar yt-dlp" $results {
    Ensure-PATool -CommandName 'yt-dlp' -WingetId 'yt-dlp.yt-dlp' -PipPackage 'yt-dlp'
}

Invoke-PAStep "Baixando ($modoLabel)" $results {
    $outTemplate = Join-Path $dest '%(playlist)s/%(title)s.%(ext)s'
    if (-not $playlist) {
        $outTemplate = Join-Path $dest '%(title)s.%(ext)s'
    }
    $extra = @()
    if (-not $playlist) { $extra += '--no-playlist' }

    if ($mode -eq 'audio') {
        yt-dlp -x --audio-format mp3 --audio-quality 0 -o $outTemplate @extra -- $url
    } else {
        yt-dlp -f 'bv*+ba/b' --merge-output-format mp4 -o $outTemplate @extra -- $url
    }
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "yt-dlp encerrou com codigo $LASTEXITCODE"
    }
}

Write-PASummary -Results $results -StartTime $startTime -Titulo "baixar_ytdlp"
