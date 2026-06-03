# Funções compartilhadas de instalação — dot-source pelos scripts Utilitários
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

function Ensure-PATool {
    param(
        [string]$CommandName,
        [string]$WingetId,
        [string]$PipPackage
    )

    if (Test-PACommand $CommandName) {
        Write-Host "  $CommandName ja esta instalado." -ForegroundColor DarkGreen
        return
    }

    Write-Host "  $CommandName nao encontrado. Instalando..." -ForegroundColor Yellow

    if ($WingetId -and (Test-PACommand 'winget')) {
        Write-Host "  Tentando winget ($WingetId)..." -ForegroundColor DarkGray
        & winget install --id $WingetId -e -h `
            --accept-package-agreements --accept-source-agreements --scope user 2>$null
        if (Test-PAWingetInstallOk -ExitCode $LASTEXITCODE) {
            Start-Sleep -Seconds 2
            $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [System.Environment]::GetEnvironmentVariable('Path', 'User')
            if (Test-PACommand $CommandName) {
                Write-Host "  $CommandName instalado via winget." -ForegroundColor Green
                return
            }
        }
    }

    $py = Get-PAPythonCmd
    if (-not $py) {
        throw "Python nao encontrado. Instale Python 3.10+ para usar $CommandName."
    }

    Write-Host "  Instalando via pip ($PipPackage)..." -ForegroundColor DarkGray
    & @py -m pip install -U $PipPackage -q --disable-pip-version-check
    if (-not (Test-PACommand $CommandName)) {
        throw "Nao foi possivel instalar $CommandName. Tente: pip install $PipPackage"
    }
    Write-Host "  $CommandName instalado via pip." -ForegroundColor Green
}
