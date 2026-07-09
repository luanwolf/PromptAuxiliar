# Prompt Auxiliar v2.8.0 — instalador estilo one-liner (Chris Titus / WinUtil)
# Uso: irm "https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/install.ps1" | iex
#      irm "https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/win.ps1" | iex
#Requires -Version 5.1

$PromptAuxVersion = '2.8.0'

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
    Write-Host "                  v$PromptAuxVersion" -ForegroundColor DarkCyan
    Write-Host '       Utilitarios Windows / WebView2' -ForegroundColor Cyan
    Write-Host '  ============================================' -ForegroundColor DarkCyan
    Write-Host ''
}

function Get-PromptAuxPython {
    foreach ($cmd in @('python', 'py')) {
        $exe = Get-Command $cmd -ErrorAction SilentlyContinue
        if (-not $exe) { continue }
        if ($cmd -eq 'py') {
            $v = & py -3 -c "import sys; print(sys.version_info >= (3,10))" 2>$null
            if ($v -eq 'True') { return @{ Cmd = 'py'; Arg = @('-3') } }
        } else {
            $v = & python -c "import sys; print(sys.version_info >= (3,10))" 2>$null
            if ($v -eq 'True') { return @{ Cmd = $exe.Source; Arg = @() } }
        }
    }
    throw @"
Python 3.10+ não encontrado.
Instale em https://www.python.org/downloads/ (marque 'Add to PATH') e execute o comando novamente.
"@
}

function Install-PromptAuxiliarSource {
    param([string]$Destination, [string]$Owner, [string]$Name, [string]$Ref)

    $zipUrl = "https://github.com/$Owner/$Name/archive/refs/heads/$Ref.zip"
    $tempZip = Join-Path ([System.IO.Path]::GetTempPath()) "PromptAuxiliar-$Ref.zip"
    $tempExtract = Join-Path ([System.IO.Path]::GetTempPath()) "PromptAuxiliar-extract-$([Guid]::NewGuid().ToString('n'))"

    Write-Host "  Baixando repositório ($Ref)…" -ForegroundColor DarkGray
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip -UseBasicParsing
    } catch {
        throw "Falha ao baixar $zipUrl. Verifique sua conexão ou defina PROMPTAUX_REPO_OWNER / PROMPTAUX_BRANCH."
    }

    if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

    $extracted = Get-ChildItem -Path $tempExtract -Directory | Select-Object -First 1
    if (-not $extracted) { throw 'Pacote ZIP inválido ou vazio.' }

    if (Test-Path $Destination) {
        Write-Host "  Atualizando pasta de instalação…" -ForegroundColor DarkGray
        Remove-Item $Destination -Recurse -Force
    }
    New-Item -ItemType Directory -Path (Split-Path $Destination -Parent) -Force | Out-Null
    Move-Item -Path $extracted.FullName -Destination $Destination

    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
    Remove-Item $tempExtract -Force -ErrorAction SilentlyContinue
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

# ——— Execução ———
Write-PromptAuxBanner

$forceUpdate = $Update -or ($env:PROMPTAUX_UPDATE -eq '1')
$isLocalClone = $ScriptDir -and ($InstallRoot -eq $ScriptDir)
$needsDownload = -not $isLocalClone -and ($forceUpdate -or -not (Test-Path (Join-Path $InstallRoot 'main.py')))
if ($needsDownload) {
    Write-Host '  Instalando Prompt Auxiliar…' -ForegroundColor Gray
    Install-PromptAuxiliarSource -Destination $InstallRoot -Owner $RepoOwner -Name $RepoName -Ref $Branch
    Write-Host "  Instalado em: $InstallRoot" -ForegroundColor Green
} else {
    Write-Host "  Usando instalação em: $InstallRoot" -ForegroundColor DarkGray
}

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
    Write-Host '  Criando atalhos (icone personalizado)…' -ForegroundColor DarkGray
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $atalhoPs1 -ProjectRoot $InstallRoot
}

Write-Host '  Abrindo interface…' -ForegroundColor Gray
Start-PromptAuxiliarProcess -PythonInfo $python -ProjectRoot $InstallRoot -ExtraArgs @()
