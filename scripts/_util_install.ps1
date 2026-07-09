# Funções compartilhadas de instalação - dot-source pelos scripts Utilitários
# Encoding: UTF-8 with BOM

function Test-PACommand {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-PAPythonCmd {
    if (Test-PACommand 'py') { return @('py', '-3') }
    if (Test-PACommand 'python') { return @('python') }
    return $null
}

function Test-PAWingetInstallOk {
    param([int]$ExitCode)
    if ($ExitCode -eq 0) { return $true }
    $ok = @(-1978335189, -1978335135, -1978335212, 2316632107)
    return $ExitCode -in $ok
}

function Update-PAPathEnv {
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
        [System.Environment]::GetEnvironmentVariable('Path', 'User')
}

function Resolve-PAToolPath {
    param([string]$CommandName)

    if (Test-PACommand $CommandName) {
        return (Get-Command $CommandName -CommandType Application).Source
    }

    # ponytail: alguns pacotes (ex.: ImageMagick) instalam em Program Files sem PATH imediato na sessão.
    if ($CommandName -eq 'magick') {
        foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
            if (-not $root) { continue }
            $hit = Get-ChildItem -Path (Join-Path $root 'ImageMagick-*') -Filter 'magick.exe' -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($hit) { return $hit.FullName }
        }
    }

    return $null
}

function Install-PAWingetPackage {
    param([string]$WingetId)

    foreach ($scope in @('user', 'machine')) {
        Write-Host "  Tentando winget ($WingetId, escopo $scope)..." -ForegroundColor DarkGray
        & winget install --id $WingetId -e -h `
            --accept-package-agreements --accept-source-agreements --scope $scope 2>$null
        if (Test-PAWingetInstallOk -ExitCode $LASTEXITCODE) {
            return $true
        }
    }

    return $false
}

function Ensure-PATool {
    param(
        [string]$CommandName,
        [string]$WingetId,
        [string]$PipPackage
    )

    if (Test-PACommand $CommandName) {
        Write-Host "  $CommandName já está instalado." -ForegroundColor DarkGreen
        return
    }

    $existing = Resolve-PAToolPath -CommandName $CommandName
    if ($existing) {
        $toolDir = Split-Path $existing -Parent
        if ($env:Path -notlike "*$toolDir*") {
            $env:Path = "$toolDir;$env:Path"
        }
        Write-Host "  $CommandName já está instalado." -ForegroundColor DarkGreen
        return
    }

    Write-Host "  $CommandName não encontrado. Instalando..." -ForegroundColor Yellow

    if ($WingetId -and (Test-PACommand 'winget')) {
        if (Install-PAWingetPackage -WingetId $WingetId) {
            Start-Sleep -Seconds 2
            Update-PAPathEnv
            $toolPath = Resolve-PAToolPath -CommandName $CommandName
            if ($toolPath) {
                $toolDir = Split-Path $toolPath -Parent
                if ($env:Path -notlike "*$toolDir*") {
                    $env:Path = "$toolDir;$env:Path"
                }
                Write-Host "  $CommandName instalado via winget." -ForegroundColor Green
                return
            }
        }
    }

    if (-not $PipPackage) {
        throw "Não foi possível instalar $CommandName. Tente: winget install --id $WingetId"
    }

    $py = Get-PAPythonCmd
    if (-not $py) {
        throw "Python não encontrado. Instale Python 3.10+ para usar $CommandName."
    }

    Write-Host "  Instalando via pip ($PipPackage)..." -ForegroundColor DarkGray
    & @py -m pip install -U $PipPackage -q --disable-pip-version-check
    if (-not (Test-PACommand $CommandName)) {
        throw "Não foi possivel instalar $CommandName. Tente: pip install $PipPackage"
    }
    Write-Host "  $CommandName instalado via pip." -ForegroundColor Green
}
