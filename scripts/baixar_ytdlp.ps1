#Requires -Version 5.1
. "$PSScriptRoot\_ui.ps1"

$url  = $env:PA_UTIL_URL
$dest = $env:PA_UTIL_DEST
$mode = if ($env:PA_UTIL_MODE -eq 'audio') { 'audio' } else { 'video' }

Show-PABanner "Download (yt-dlp)" "Baixa video ou musica de links suportados (YouTube, etc.)."

if ([string]::IsNullOrWhiteSpace($url) -or [string]::IsNullOrWhiteSpace($dest)) {
    Write-Host '  URL ou pasta de destino nao informados pelo app.' -ForegroundColor Red
    Read-Host '  Pressione Enter para fechar'
    exit 1
}

if (-not (Test-Path -LiteralPath $dest)) {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
}

$modoLabel = if ($mode -eq 'audio') { 'Somente audio (MP3)' } else { 'Video (MP4)' }
Write-Host "  Link : $url" -ForegroundColor DarkGray
Write-Host "  Pasta: $dest" -ForegroundColor DarkGray
Write-Host "  Modo : $modoLabel" -ForegroundColor DarkGray
Write-Host ''

if (-not (Confirm-PAAction)) { exit 0 }

function Test-PACommand {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

$startTime = Get-Date
$results   = [System.Collections.ArrayList]::new()

Invoke-PAStep "Verificando yt-dlp" $results {
    if (-not (Test-PACommand 'yt-dlp')) {
        Write-Host '  yt-dlp nao encontrado. Instalando via pip...' -ForegroundColor Yellow
        $py = if (Test-PACommand 'py') { @('py', '-3') } elseif (Test-PACommand 'python') { @('python') } else { $null }
        if (-not $py) { throw 'Python nao encontrado. Instale Python 3.10+ ou: pip install yt-dlp' }
        & @py -m pip install -U yt-dlp -q --disable-pip-version-check
        if (-not (Test-PACommand 'yt-dlp')) { throw 'Falha ao instalar yt-dlp. Tente: pip install yt-dlp' }
    }
}

Invoke-PAStep "Baixando ($modoLabel)" $results {
    $outTemplate = Join-Path $dest '%(title)s.%(ext)s'
    if ($mode -eq 'audio') {
        yt-dlp -x --audio-format mp3 --audio-quality 0 -o $outTemplate --no-playlist -- $url
    } else {
        yt-dlp -f 'bv*+ba/b' --merge-output-format mp4 -o $outTemplate -- $url
    }
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "yt-dlp encerrou com codigo $LASTEXITCODE"
    }
}

Write-PASummary -Results $results -StartTime $startTime -Titulo "baixar_ytdlp"
