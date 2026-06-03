#Requires -Version 5.1
. "$PSScriptRoot\_ui.ps1"

$url  = $env:PA_UTIL_URL
$dest = $env:PA_UTIL_DEST

Show-PABanner "Download Spotify (spotdl)" "Baixa musica ou playlist do Spotify em MP3."

if ([string]::IsNullOrWhiteSpace($url) -or [string]::IsNullOrWhiteSpace($dest)) {
    Write-Host '  URL ou pasta de destino nao informados pelo app.' -ForegroundColor Red
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

function Test-PACommand {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

$startTime = Get-Date
$results   = [System.Collections.ArrayList]::new()

Invoke-PAStep "Verificando spotdl" $results {
    if (-not (Test-PACommand 'spotdl')) {
        Write-Host '  spotdl nao encontrado. Instalando via pip...' -ForegroundColor Yellow
        $py = if (Test-PACommand 'py') { @('py', '-3') } elseif (Test-PACommand 'python') { @('python') } else { $null }
        if (-not $py) { throw 'Python nao encontrado. Instale Python 3.10+ ou: pip install spotdl' }
        & @py -m pip install -U spotdl -q --disable-pip-version-check
        if (-not (Test-PACommand 'spotdl')) { throw 'Falha ao instalar spotdl. Tente: pip install spotdl' }
    }
}

Invoke-PAStep "Baixando do Spotify" $results {
    spotdl download $url --output $dest --format mp3
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "spotdl encerrou com codigo $LASTEXITCODE"
    }
}

Write-PASummary -Results $results -StartTime $startTime -Titulo "baixar_spotdl"
