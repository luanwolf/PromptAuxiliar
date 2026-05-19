﻿# Prompt Auxiliar — instalador estilo one-liner (Chris Titus / WinUtil)
# Uso: irm "https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/win.ps1" | iex
#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$Update,
    [switch]$SetupOnly,
    [string]$Branch = $env:PROMPTAUX_BRANCH
)

$ErrorActionPreference = 'Stop'

if (-not $Branch) { $Branch = 'main' }

$RepoOwner = if ($env:PROMPTAUX_REPO_OWNER) { $env:PROMPTAUX_REPO_OWNER } else { 'luanwolf' }
$RepoName  = if ($env:PROMPTAUX_REPO_NAME)  { $env:PROMPTAUX_REPO_NAME }  else { 'PromptAuxiliar' }

$ScriptDir = $PSScriptRoot
if (-not $ScriptDir -and $MyInvocation.MyCommand.Path) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$InstallRoot = if ($env:PROMPTAUX_HOME) {
    $env:PROMPTAUX_HOME
} elseif ($ScriptDir -and (Test-Path (Join-Path $ScriptDir 'main.py'))) {
    $ScriptDir
} else {
    Join-Path $env:LOCALAPPDATA 'PromptAuxiliar'
}

function Write-PromptAuxBanner {
    Write-Host ''
    Write-Host '  ============================================' -ForegroundColor DarkCyan
    Write-Host '            PROMPT AUXILIAR' -ForegroundColor Cyan
    Write-Host '       Utilitarios Windows / WebView2' -ForegroundColor Cyan
    Write-Host '  ============================================' -ForegroundColor DarkCyan
    Write-Host ''
}

function Update-PromptAuxPath {
    $machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user"
}

function Test-PromptAuxPythonExe {
    param([string]$ExePath)

    if (-not $ExePath -or -not (Test-Path -LiteralPath $ExePath)) { return $null }
    $v = & $ExePath -c "import sys; print(sys.version_info >= (3,10))" 2>$null
    if ($v -eq 'True') { return @{ Cmd = $ExePath; Arg = @() } }
    return $null
}

function Test-PromptAuxPythonCmd {
    param([string]$Cmd)

    if ($Cmd -eq 'py') {
        if (-not (Get-Command py -ErrorAction SilentlyContinue)) { return $null }
        $v = & py -3 -c "import sys; print(sys.version_info >= (3,10))" 2>$null
        if ($v -eq 'True') { return @{ Cmd = 'py'; Arg = @('-3') } }
        return $null
    }

    $exe = Get-Command $Cmd -ErrorAction SilentlyContinue
    if (-not $exe) { return $null }
    return Test-PromptAuxPythonExe -ExePath $exe.Source
}

function Find-PromptAuxPythonFromDisk {
    $candidates = [System.Collections.Generic.List[string]]::new()

    $roots = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Python')
        (Join-Path $env:ProgramFiles 'Python312')
        (Join-Path $env:ProgramFiles 'Python311')
        (Join-Path $env:ProgramFiles 'Python310')
    ) | Where-Object { $_ -and (Test-Path $_) }

    foreach ($root in $roots) {
        Get-ChildItem -Path $root -Filter 'python.exe' -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object { $candidates.Add($_.FullName) }
    }

    foreach ($p in ($candidates | Sort-Object -Unique)) {
        $info = Test-PromptAuxPythonExe -ExePath $p
        if ($info) { return $info }
    }
    return $null
}

function Find-PromptAuxPython {
    foreach ($cmd in @('python', 'py')) {
        $info = Test-PromptAuxPythonCmd -Cmd $cmd
        if ($info) { return $info }
    }
    return Find-PromptAuxPythonFromDisk
}

function Test-WingetInstallOk {
    param([int]$ExitCode)

    if ($ExitCode -eq 0) { return $true }
    # Já instalado / nada a fazer (códigos comuns do winget)
    $ok = @(-1978335189, -1978335135, -1978335212, 2316632107)
    return $ExitCode -in $ok
}

function Invoke-WingetInstallPython {
    param([string]$PackageId, [string]$Scope)

    $args = @(
        'install', '--id', $PackageId, '-e', '-h',
        '--accept-package-agreements', '--accept-source-agreements',
        '--scope', $Scope
    )
    Write-Host "  winget install $PackageId (escopo: $Scope)…" -ForegroundColor DarkGray
    & winget @args
    return (Test-WingetInstallOk -ExitCode $LASTEXITCODE)
}

function Install-PromptAuxPythonViaWinget {
    $ids = @('Python.Python.3.12', 'Python.Python.3.11', 'Python.Python.3.10')
    $scopes = @('user', 'machine')

    foreach ($id in $ids) {
        foreach ($scope in $scopes) {
            try {
                if (Invoke-WingetInstallPython -PackageId $id -Scope $scope) {
                    return $true
                }
            } catch {
                Write-Host "  winget falhou ($id / $scope): $($_.Exception.Message)" -ForegroundColor DarkYellow
            }
        }
    }
    return $false
}

function Install-PromptAuxPythonViaOfficial {
    $ver = '3.12.10'
    $url = "https://www.python.org/ftp/python/$ver/python-$ver-amd64.exe"
    $installer = Join-Path $env:TEMP "python-$ver-amd64.exe"

    Write-Host "  Baixando instalador oficial Python $ver…" -ForegroundColor DarkGray
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing

    Write-Host '  Instalando Python (modo silencioso, adiciona ao PATH)…' -ForegroundColor DarkGray
    $proc = Start-Process -FilePath $installer -ArgumentList @(
        '/quiet',
        'InstallAllUsers=0',
        'PrependPath=1',
        'Include_test=0',
        'Include_launcher=1'
    ) -Wait -PassThru

    Remove-Item $installer -Force -ErrorAction SilentlyContinue
    if ($proc.ExitCode -ne 0) {
        throw "Instalador oficial retornou codigo $($proc.ExitCode)."
    }
    return $true
}

function Install-PromptAuxPython {
    Write-Host '  Python 3.10+ não encontrado.' -ForegroundColor Yellow

    $wingetOk = $false
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host '  Tentando instalar via winget…' -ForegroundColor DarkGray
        $wingetOk = Install-PromptAuxPythonViaWinget
    } else {
        Write-Host '  winget não disponível neste PC.' -ForegroundColor DarkYellow
    }

    if (-not $wingetOk) {
        Write-Host '  winget não concluiu — usando instalador python.org…' -ForegroundColor DarkYellow
        Install-PromptAuxPythonViaOfficial | Out-Null
    }

    Start-Sleep -Seconds 3
    Update-PromptAuxPath
    Write-Host '  Verificando Python instalado…' -ForegroundColor Green
}

function Get-PromptAuxPython {
    $info = Find-PromptAuxPython
    if ($info) { return $info }

    Install-PromptAuxPython
    Update-PromptAuxPath

    foreach ($i in 1..5) {
        $info = Find-PromptAuxPython
        if ($info) { return $info }
        Start-Sleep -Seconds 2
        Update-PromptAuxPath
    }

    throw @"
Python 3.10+ ainda não foi detectado após a instalação.
Feche este PowerShell, abra um novo e execute o comando irm novamente.
Ou instale manualmente: https://www.python.org/downloads/ (marque 'Add python.exe to PATH').
"@
}

function Test-PromptAuxPs1Syntax {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $parseErrors = $null
    $tokens = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors)
    return (-not $parseErrors -or $parseErrors.Count -eq 0)
}

function Sync-PromptAuxUpdateModuleFromGitHub {
    param(
        [string]$InstallRoot,
        [string]$Owner,
        [string]$Name,
        [string]$Branch
    )
    $psDir = Join-Path $InstallRoot 'powershell'
    if (-not (Test-Path -LiteralPath $psDir)) {
        New-Item -ItemType Directory -Path $psDir -Force | Out-Null
    }
    $dest = Join-Path $psDir 'Update-PromptAuxiliar.ps1'
    $url = "https://raw.githubusercontent.com/$Owner/$Name/$Branch/powershell/Update-PromptAuxiliar.ps1"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
}

function Install-PromptAuxiliarSourceZip {
    param(
        [string]$Destination,
        [string]$Owner,
        [string]$Name,
        [string]$Branch
    )

    $zipUrl = "https://github.com/$Owner/$Name/archive/refs/heads/$Branch.zip"
    $tempZip = Join-Path ([System.IO.Path]::GetTempPath()) "PromptAuxiliar-$Branch.zip"
    $tempExtract = Join-Path ([System.IO.Path]::GetTempPath()) "PromptAuxiliar-extract-$([Guid]::NewGuid().ToString('n'))"

    Write-Host "  Baixando branch $Branch do GitHub..." -ForegroundColor DarkGray
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip -UseBasicParsing

    if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

    $extracted = Get-ChildItem -Path $tempExtract -Directory | Select-Object -First 1
    if (-not $extracted) { throw 'Pacote ZIP invalido ou vazio.' }

    if (Test-Path $Destination) {
        Write-Host '  Substituindo arquivos da instalacao...' -ForegroundColor DarkGray
        Remove-Item $Destination -Recurse -Force
    }
    New-Item -ItemType Directory -Path (Split-Path $Destination -Parent) -Force | Out-Null
    Move-Item -Path $extracted.FullName -Destination $Destination

    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
    Remove-Item $tempExtract -Force -ErrorAction SilentlyContinue
}

function Install-PromptAuxiliarSource {
    param([string]$Destination, [string]$Owner, [string]$Name, [string]$Ref)
    Install-PromptAuxiliarSourceZip -Destination $Destination -Owner $Owner -Name $Name -Branch $Ref
}

function Invoke-PromptAuxiliarInstallOrUpdate {
    param(
        [string]$InstallRoot,
        [string]$ScriptDir,
        [string]$Owner,
        [string]$Name,
        [string]$Branch,
        [switch]$Force
    )

    $updateModule = Join-Path $InstallRoot 'powershell\Update-PromptAuxiliar.ps1'
    $mainPy = Join-Path $InstallRoot 'main.py'
    $missingInstall = -not (Test-Path -LiteralPath $mainPy)

    try {
        Sync-PromptAuxUpdateModuleFromGitHub -InstallRoot $InstallRoot -Owner $Owner -Name $Name -Branch $Branch
    } catch {
        Write-Host '  Aviso: nao foi possivel baixar Update-PromptAuxiliar.ps1 do GitHub.' -ForegroundColor DarkYellow
    }

    $moduleOk = Test-PromptAuxPs1Syntax -Path $updateModule

    if (-not $moduleOk) {
        Write-Host '  Script de atualizacao local invalido - reinstalando via ZIP...' -ForegroundColor Cyan
        Install-PromptAuxiliarSourceZip -Destination $InstallRoot -Owner $Owner -Name $Name -Branch $Branch
        $moduleOk = Test-PromptAuxPs1Syntax -Path $updateModule
    }

    if ($moduleOk) {
        . $updateModule
        if ($missingInstall -or $Force) {
            Write-Host '  Instalando Prompt Auxiliar...' -ForegroundColor Gray
            Update-PromptAuxiliarIfNewer -InstallRoot $InstallRoot -ScriptDir $ScriptDir -Force | Out-Null
        } else {
            Write-Host "  Usando instalacao em: $InstallRoot" -ForegroundColor DarkGray
            Update-PromptAuxiliarIfNewer -InstallRoot $InstallRoot -ScriptDir $ScriptDir -Force:$Force | Out-Null
        }
        return
    }

    if ($missingInstall -or $Force) {
        Write-Host '  Instalando Prompt Auxiliar...' -ForegroundColor Gray
    } else {
        Write-Host "  Usando instalacao em: $InstallRoot" -ForegroundColor DarkGray
    }
    Install-PromptAuxiliarSourceZip -Destination $InstallRoot -Owner $Owner -Name $Name -Branch $Branch
    Write-Host "  Instalado em: $InstallRoot" -ForegroundColor Green
}

function Install-PromptAuxiliarPythonDeps {
    param($PythonInfo, [string]$ProjectRoot)

    Write-Host "  Instalando dependências Python…" -ForegroundColor DarkGray
    $req = Join-Path $ProjectRoot 'requirements.txt'
    if (-not (Test-Path $req)) { throw "requirements.txt não encontrado em $ProjectRoot" }

    $pipArgs = @($PythonInfo.Arg + @('-m', 'pip', 'install', '-r', $req, '-q', '--disable-pip-version-check'))
    & $PythonInfo.Cmd @pipArgs
    if ($LASTEXITCODE -ne 0) {
        throw 'Falha ao instalar dependências. Execute manualmente: pip install -r requirements.txt'
    }
}

function Start-PromptAuxiliarProcess {
    param($PythonInfo, [string]$ProjectRoot, [string[]]$ExtraArgs)

    $main = Join-Path $ProjectRoot 'main.py'
    if (-not (Test-Path $main)) { throw "main.py não encontrado em $ProjectRoot" }

    $runArgs = $PythonInfo.Arg + @($main)
    if ($ExtraArgs.Count -gt 0) {
        $runArgs += $ExtraArgs
    }

    Push-Location $ProjectRoot
    try {
        & $PythonInfo.Cmd @runArgs
    } finally {
        Pop-Location
    }
}

# --- Execucao ---
trap {
    Write-Host ''
    Write-Host "ERRO: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Pressione Enter para fechar...' -ForegroundColor Yellow
    Read-Host | Out-Null
    exit 1
}

Write-PromptAuxBanner

$forceUpdate = $Update -or ($env:PROMPTAUX_UPDATE -eq '1')
Invoke-PromptAuxiliarInstallOrUpdate `
    -InstallRoot $InstallRoot `
    -ScriptDir $ScriptDir `
    -Owner $RepoOwner `
    -Name $RepoName `
    -Branch $Branch `
    -Force:$forceUpdate

$env:PROMPTAUX_HOME = $InstallRoot
$python = Get-PromptAuxPython
Install-PromptAuxiliarPythonDeps -PythonInfo $python -ProjectRoot $InstallRoot

if ($SetupOnly) {
    Push-Location $InstallRoot
    try {
        & $python.Cmd @($python.Arg + @('-c', 'from app.environment import preparar_ambiente; preparar_ambiente()'))
    } finally {
        Pop-Location
    }
    Write-Host '  Ambiente configurado (C:\PromptAuxiliar).' -ForegroundColor Green
    return
}

$atalhoPs1 = Join-Path $InstallRoot 'powershell\Criar-Atalho.ps1'
if (Test-Path $atalhoPs1) {
    Write-Host '  Criando atalhos...' -ForegroundColor DarkGray
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $atalhoPs1 -ProjectRoot $InstallRoot
}

Write-Host '  Abrindo interface...' -ForegroundColor Gray
Start-PromptAuxiliarProcess -PythonInfo $python -ProjectRoot $InstallRoot -ExtraArgs @()
