#Requires -Version 5.1
. "$PSScriptRoot\_ui.ps1"
. "$PSScriptRoot\_util_install.ps1"

$src     = $env:PA_UTIL_SRC
$dest    = $env:PA_UTIL_DEST
$format  = ($env:PA_UTIL_FORMAT -replace '^\.', '').Trim().ToLower()
$outName = $env:PA_UTIL_OUTNAME

function Get-PAOutputBaseName {
    param(
        [string]$Requested,
        [string]$Fallback
    )

    $base = $Fallback
    if (-not [string]::IsNullOrWhiteSpace($Requested)) {
        $base = [IO.Path]::GetFileNameWithoutExtension($Requested.Trim())
        $base = [regex]::Replace($base, '[\\/:*?"<>|]', '')
        $base = $base.Trim().TrimEnd('.')
    }

    if ([string]::IsNullOrWhiteSpace($base)) {
        throw 'Nome de saída inválido.'
    }

    return $base
}

Show-PABanner "Converter imagem (ImageMagick)" "Converte imagens entre formatos comuns (JPEG, PNG, WebP, PDF, ICO, etc.)."

$allowed = @('jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'tiff', 'tif', 'pdf', 'ico', 'avif')

if ([string]::IsNullOrWhiteSpace($src) -or -not (Test-Path -LiteralPath $src -PathType Leaf)) {
    Write-Host '  Arquivo de origem não informado ou inexistente.' -ForegroundColor Red
    Read-Host '  Pressione Enter para fechar'
    exit 1
}

if ([string]::IsNullOrWhiteSpace($dest)) {
    Write-Host '  Pasta de destino não informada pelo app.' -ForegroundColor Red
    Read-Host '  Pressione Enter para fechar'
    exit 1
}

if ($format -notin $allowed) {
    Write-Host "  Formato de saída inválido: $format" -ForegroundColor Red
    Read-Host '  Pressione Enter para fechar'
    exit 1
}

if (-not (Test-Path -LiteralPath $dest)) {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
}

$extOut = switch ($format) {
    'jpeg' { 'jpg' }
    'tif'  { 'tiff' }
    default { $format }
}

$base    = Get-PAOutputBaseName -Requested $outName -Fallback ([IO.Path]::GetFileNameWithoutExtension($src))
$outPath = Join-Path $dest "$base.$extOut"
$srcExt  = [IO.Path]::GetExtension($src).ToLowerInvariant()

$sameFormat = $srcExt -eq ".$extOut"
$sameName   = $true
if (-not [string]::IsNullOrWhiteSpace($outName)) {
    $reqBase = [IO.Path]::GetFileNameWithoutExtension($outName.Trim())
    $reqBase = [regex]::Replace($reqBase, '[\\/:*?"<>|]', '').Trim().TrimEnd('.')
    $sameName = $reqBase -ieq [IO.Path]::GetFileNameWithoutExtension($src)
}
if ($sameFormat -and $sameName) {
    Write-Host '  O arquivo já está no formato de saída escolhido.' -ForegroundColor Yellow
    Write-Host "  Origem: $src" -ForegroundColor DarkGray
    Read-Host '  Pressione Enter para fechar'
    exit 0
}

Write-Host "  Origem : $src" -ForegroundColor DarkGray
Write-Host "  Pasta  : $dest" -ForegroundColor DarkGray
Write-Host "  Nome   : $base" -ForegroundColor DarkGray
Write-Host "  Saída  : $outPath" -ForegroundColor DarkGray
Write-Host "  Formato: $extOut" -ForegroundColor DarkGray
Write-Host ''

if (-not (Confirm-PAAction)) { exit 0 }

$startTime = Get-Date
$results   = [System.Collections.ArrayList]::new()

Invoke-PAStep "Verificar / instalar ImageMagick" $results {
    Ensure-PATool -CommandName 'magick' -WingetId 'ImageMagick.ImageMagick' -PipPackage ''
}

Invoke-PAStep "Convertendo imagem" $results {
    if (Test-Path -LiteralPath $outPath) {
        throw "Arquivo de destino já existe: $outPath"
    }

    $magick = Resolve-PAToolPath -CommandName 'magick'
    if (-not $magick) {
        throw "ImageMagick (magick) não encontrado após a instalação."
    }

    $inputArg = if ($srcExt -eq '.pdf') { "${src}[0]" } else { $src }
    $magickArgs = @($inputArg, '-auto-orient')

    if ($extOut -in @('jpg', 'jpeg', 'webp', 'avif')) {
        $magickArgs += '-quality', '92'
    }
    if ($extOut -eq 'ico') {
        $magickArgs += '-define', 'icon:auto-resize=256,128,64,48,32,16'
    }
    $magickArgs += $outPath

    & $magick @magickArgs
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "magick encerrou com código $LASTEXITCODE"
    }
    if (-not (Test-Path -LiteralPath $outPath)) {
        throw "Conversão concluída, mas o arquivo de saída não foi encontrado."
    }
}

Write-PASummary -Results $results -StartTime $startTime -Titulo "converter_imagem"
