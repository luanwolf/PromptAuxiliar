# Prompt Auxiliar - instalador one-liner
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
    Write-Host "  winget install $PackageId (escopo: $Scope)..." -ForegroundColor DarkGray
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

    Write-Host "  Baixando instalador oficial Python $ver..." -ForegroundColor DarkGray
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing

    Write-Host '  Instalando Python (modo silencioso, adiciona ao PATH)...' -ForegroundColor DarkGray
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
        Write-Host '  Tentando instalar via winget...' -ForegroundColor DarkGray
        $wingetOk = Install-PromptAuxPythonViaWinget
    } else {
        Write-Host '  winget não disponível neste PC.' -ForegroundColor DarkYellow
    }

    if (-not $wingetOk) {
        Write-Host '  winget não concluiu - usando instalador python.org...' -ForegroundColor DarkYellow
        Install-PromptAuxPythonViaOfficial | Out-Null
    }

    Start-Sleep -Seconds 3
    Update-PromptAuxPath
    Write-Host '  Verificando Python instalado...' -ForegroundColor Green
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

function Write-PromptAuxUtf8NoBom {
    param([string]$Path, [string]$Content)
    $utf8 = New-Object System.Text.UTF8Encoding $false
    $text = $Content.TrimStart([char]0xFEFF)
    [System.IO.File]::WriteAllText($Path, $text, $utf8)
}

function Sync-PromptAuxUpdateModuleFromGitHub {
    param(
        [string]$InstallRoot,
        [string]$Owner,
        [string]$Name,
        [string]$Branch,
        [string]$SourceRoot = ''
    )
    Sync-PromptAuxEssentialScriptsFromGitHub `
        -InstallRoot $InstallRoot `
        -Owner $Owner `
        -Name $Name `
        -Branch $Branch `
        -SourceRoot $SourceRoot `
        -Only @('Update-PromptAuxiliar.ps1')
}

function Get-PromptAuxEssentialScriptNames {
    # Atualizar-e-Iniciar.ps1 foi substituido por win.ps1 / Iniciar-PromptAuxiliar.cmd
    return @(
        'Update-PromptAuxiliar.ps1',
        'Criar-Atalho.ps1',
        'Concluir-Troca-Instalacao.ps1',
        'Reparar-Atalho.ps1'
    )
}

function Get-PromptAuxBatScriptNames {
    return @(
        '_ui.bat',
        'aplicar_ajustes.bat',
        'alternar_contexto.bat',
        'ativar_office_kms.bat',
        'ativar_windows.bat',
        'ativar_windows_kms.bat',
        'atualizar_softwares.bat',
        'criar_atalhos.bat',
        'gerenciar_inicializacao.bat',
        'instalar_runtimes.bat',
        'instalar_software.bat',
        'limpeza_disco.bat',
        'limpeza_malware.bat',
        'limpeza_profunda.bat',
        'limpeza_temporarios.bat',
        'reparar_rede.bat',
        'windows_utility.bat'
    )
}

function Get-PromptAuxScriptPs1Names {
    return @('limpeza_temporarios.ps1')
}

function Test-PromptAuxRepoFilePresent {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    try {
        return (Get-Item -LiteralPath $Path).Length -ge 8
    } catch {
        return $false
    }
}

function Sync-PromptAuxRepoFile {
    param(
        [string]$InstallRoot,
        [string]$RelativePath,
        [string]$Owner,
        [string]$Name,
        [string]$Branch,
        [string]$SourceRoot = ''
    )
    $dest = Join-Path $InstallRoot ($RelativePath -replace '/', '\')
    $destDir = Split-Path -Parent $dest
    if ($destDir -and -not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force -ErrorAction SilentlyContinue | Out-Null
    }

    if ($SourceRoot) {
        try {
            $srcRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
            $dstRoot = (Resolve-Path -LiteralPath $InstallRoot).Path
            if ($srcRoot -ieq $dstRoot) { $SourceRoot = '' }
        } catch { }
    }

    if ($SourceRoot) {
        $src = Join-Path $SourceRoot ($RelativePath -replace '/', '\')
        if (Test-Path -LiteralPath $src) {
            try {
                Copy-Item -LiteralPath $src -Destination $dest -Force -ErrorAction Stop
                return $true
            } catch {
                Write-Host "  Aviso: nao foi possivel copiar $RelativePath (arquivo em uso?)." -ForegroundColor DarkYellow
            }
        }
    }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $cacheBust = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $urlPath = $RelativePath -replace '\\', '/'
        $url = "https://raw.githubusercontent.com/$Owner/$Name/$Branch/$urlPath?_=$cacheBust"
        $headers = @{ 'User-Agent' = 'PromptAuxiliar-Installer' }
        $content = (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 25 -Headers $headers).Content
        if (-not $content -or $content.Trim().Length -lt 8) {
            throw 'Resposta vazia do GitHub'
        }
        Write-PromptAuxUtf8NoBom -Path $dest -Content $content
        return $true
    } catch {
        if (Test-PromptAuxRepoFilePresent -Path $dest) {
            return $true
        }
        $hint = 'sem internet ou arquivo ausente no GitHub'
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 404) {
            $hint = 'ainda nao publicado na branch main (faca push) ou URL incorreta'
        }
        Write-Host "  Aviso: $RelativePath - $hint" -ForegroundColor DarkYellow
        return $false
    }
}

function Sync-PromptAuxBatScriptsFromGitHub {
    param(
        [string]$InstallRoot,
        [string]$Owner,
        [string]$Name,
        [string]$Branch,
        [string]$SourceRoot = ''
    )
    $ok = 0
    $fail = 0
    foreach ($name in (Get-PromptAuxBatScriptNames)) {
        if (Sync-PromptAuxRepoFile -InstallRoot $InstallRoot -RelativePath "scripts/$name" -Owner $Owner -Name $Name -Branch $Branch -SourceRoot $SourceRoot) {
            $ok++
        } else {
            $fail++
        }
    }
    foreach ($name in (Get-PromptAuxScriptPs1Names)) {
        if (Sync-PromptAuxRepoFile -InstallRoot $InstallRoot -RelativePath "scripts/$name" -Owner $Owner -Name $Name -Branch $Branch -SourceRoot $SourceRoot) {
            $ok++
        } else {
            $fail++
        }
    }
    return @{ Ok = $ok; Fail = $fail }
}

function Sync-PromptAuxUiBatFromGitHub {
    param(
        [string]$InstallRoot,
        [string]$Owner,
        [string]$Name,
        [string]$Branch,
        [string]$SourceRoot = ''
    )
    Sync-PromptAuxRepoFile -InstallRoot $InstallRoot -RelativePath 'scripts/_ui.bat' -Owner $Owner -Name $Name -Branch $Branch -SourceRoot $SourceRoot | Out-Null
}

function Copy-PromptAuxEssentialScriptsLocal {
    param(
        [string]$InstallRoot,
        [string]$SourceRoot
    )
    if (-not $SourceRoot) { return 0 }
    try {
        $srcRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
        $dstRoot = (Resolve-Path -LiteralPath $InstallRoot).Path
        if ($srcRoot -eq $dstRoot) { return 0 }
    } catch {
        return 0
    }
    $copied = 0
    $psDir = Join-Path $InstallRoot 'powershell'
    if (-not (Test-Path -LiteralPath $psDir)) {
        New-Item -ItemType Directory -Path $psDir -Force | Out-Null
    }
    foreach ($name in (Get-PromptAuxEssentialScriptNames)) {
        $src = Join-Path $SourceRoot "powershell\$name"
        $dest = Join-Path $psDir $name
        if ((Test-Path -LiteralPath $src) -and (-not (Test-Path -LiteralPath $dest))) {
            Copy-Item -LiteralPath $src -Destination $dest -Force
            $copied++
        }
    }
    return $copied
}

function Sync-PromptAuxEssentialScriptsFromGitHub {
    param(
        [string]$InstallRoot,
        [string]$Owner,
        [string]$Name,
        [string]$Branch,
        [string]$SourceRoot = '',
        [string[]]$Only = @()
    )
    $names = if ($Only -and $Only.Count -gt 0) { $Only } else { Get-PromptAuxEssentialScriptNames }
    $psDir = Join-Path $InstallRoot 'powershell'
    if (-not (Test-Path -LiteralPath $psDir)) {
        New-Item -ItemType Directory -Path $psDir -Force | Out-Null
    }
    if ($SourceRoot) {
        Copy-PromptAuxEssentialScriptsLocal -InstallRoot $InstallRoot -SourceRoot $SourceRoot | Out-Null
    }
    foreach ($name in $names) {
        Sync-PromptAuxRepoFile -InstallRoot $InstallRoot -RelativePath "powershell/$name" -Owner $Owner -Name $Name -Branch $Branch -SourceRoot $SourceRoot | Out-Null
    }
}

function Enable-PromptAuxiliarExecutionPolicy {
    if ($env:PROMPTAUX_SKIP_EXEC_POLICY -eq '1') { return }
    try {
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop
    } catch { }
    try {
        $userPolicy = Get-ExecutionPolicy -Scope CurrentUser
        if ($userPolicy -in @('Undefined', 'Restricted', 'AllSigned')) {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
            Write-Host '  ExecutionPolicy: RemoteSigned (usuario) - scripts locais sem -Bypass' -ForegroundColor DarkGray
        }
    } catch {
        Write-Host '  Aviso: nao foi possivel definir RemoteSigned. Atalhos usam launcher com Bypass.' -ForegroundColor DarkYellow
    }
}

function Write-PromptAuxiliarCmdLauncher {
    param([string]$InstallRoot)
    $cmdPath = Join-Path $InstallRoot 'Iniciar-PromptAuxiliar.cmd'
    $content = @"
@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0win.ps1" %*
"@
    Write-PromptAuxUtf8NoBom -Path $cmdPath -Content $content
}

function Repair-PromptAuxDesktopShortcuts {
    param([string]$InstallRoot)
    $criar = Join-Path $InstallRoot 'powershell\Criar-Atalho.ps1'
    if (-not (Test-Path -LiteralPath $criar)) { return }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File $criar -ProjectRoot $InstallRoot 2>$null
}

function Test-PromptAuxPathInUse {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $root = $Path.TrimEnd('\')
    $pattern = ($root + '*')
    $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
    foreach ($p in $procs) {
        if ($p.ExecutablePath -and ($p.ExecutablePath -like $pattern)) { return $true }
        if ($p.CommandLine -and ($p.CommandLine -like "*$root*")) { return $true }
    }
    return $false
}

function Test-PromptAuxRunningFromPath {
    param([string]$InstallRoot, [string]$ScriptDir)
    if (-not $ScriptDir) { return $false }
    try {
        return (Resolve-Path $InstallRoot).Path -eq (Resolve-Path $ScriptDir).Path
    } catch {
        return $false
    }
}

function Test-PromptAuxShouldDeferFolderSwap {
    param([string]$Destination, [string]$ScriptDir)

    if (-not (Test-Path -LiteralPath $Destination)) { return $false }

    if (Test-PromptAuxRunningFromPath -InstallRoot $Destination -ScriptDir $ScriptDir) {
        return $true
    }
    if (Test-PromptAuxPathInUse -Path $Destination) {
        return $true
    }

    # irm | iex nao define $ScriptDir; atualizacao padrao em %LOCALAPPDATA% sempre adia troca
    $defaultInstall = Join-Path $env:LOCALAPPDATA 'PromptAuxiliar'
    if (Test-Path -LiteralPath $defaultInstall) {
        try {
            if ((Resolve-Path $Destination).Path -eq (Resolve-Path $defaultInstall).Path) {
                return $true
            }
        } catch { }
    }

    try {
        $destPath = (Resolve-Path $Destination).Path
        $pwdPath = (Resolve-Path $PWD.Path).Path
        if ($pwdPath.StartsWith($destPath, [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    } catch { }

    return $false
}

function Get-PromptAuxVersionFromConfigFile {
    param([string]$ConfigPath)
    if (-not (Test-Path -LiteralPath $ConfigPath)) { return $null }
    $text = Get-Content -LiteralPath $ConfigPath -Raw -ErrorAction SilentlyContinue
    if ($text -match 'APP_VERSION\s*=\s*"([^"]+)"') { return $Matches[1].Trim() }
    return $null
}

function New-PromptAuxShortcutsFromStaging {
    param(
        [string]$StagingPath,
        [string]$Destination
    )
    $version = Get-PromptAuxVersionFromConfigFile -ConfigPath (Join-Path $StagingPath 'app\config.py')
    if (-not $version) { return }

    $criar = Join-Path $StagingPath 'powershell\Criar-Atalho.ps1'
    if (-not (Test-Path -LiteralPath $criar)) {
        $criar = Join-Path $Destination 'powershell\Criar-Atalho.ps1'
    }
    if (-not (Test-Path -LiteralPath $criar)) { return }

    Write-Host "  Criando atalho v$version (pode fechar esta janela em seguida)..." -ForegroundColor Cyan
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $criar -ProjectRoot $Destination -VersionLabel $version
}

function Invoke-PromptAuxDeferredFolderSwap {
    param(
        [string]$StagingPath,
        [string]$Destination
    )
    New-PromptAuxShortcutsFromStaging -StagingPath $StagingPath -Destination $Destination

    $parentPid = $PID
    $destEsc = $Destination.Replace("'", "''")
    $stageEsc = $StagingPath.Replace("'", "''")
    $ps1 = Join-Path ([System.IO.Path]::GetTempPath()) 'promptauxiliar-update-swap.ps1'
    $content = @"
# Prompt Auxiliar - troca de pasta apos atualizacao
`$Host.UI.RawUI.WindowTitle = 'Prompt Auxiliar - concluindo atualizacao'
`$ErrorActionPreference = 'SilentlyContinue'
`$dest = '$destEsc'
`$staging = '$stageEsc'
`$parentPid = $parentPid
`$myPid = `$PID

Write-Host ''
Write-Host '  Aguardando fechar a janela do instalador...' -ForegroundColor Cyan
`$deadline = (Get-Date).AddMinutes(15)
while ((Get-Process -Id `$parentPid -ErrorAction SilentlyContinue) -and ((Get-Date) -lt `$deadline)) {
    Start-Sleep -Milliseconds 400
}

Start-Sleep -Seconds 1
for (`$w = 0; `$w -lt 60; `$w++) {
    `$root = `$dest.TrimEnd('\')
    `$pattern = (`$root + '*')
    `$busy = `$false
    `$procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
    foreach (`$p in `$procs) {
        if (`$p.ProcessId -eq `$myPid) { continue }
        if (`$p.ExecutablePath -and (`$p.ExecutablePath -like `$pattern)) { `$busy = `$true; break }
        if (`$p.CommandLine -and (`$p.CommandLine -like "*`$root*")) { `$busy = `$true; break }
    }
    if (-not `$busy) { break }
    Start-Sleep -Seconds 1
}

Write-Host '  Substituindo arquivos da instalacao...' -ForegroundColor DarkGray
if (Test-Path -LiteralPath `$dest) {
    Remove-Item -LiteralPath `$dest -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path -LiteralPath `$dest) {
    cmd /c "rd /s /q `"`$dest`""
}
New-Item -ItemType Directory -Path (Split-Path `$dest -Parent) -Force | Out-Null
Move-Item -LiteralPath `$staging -Destination `$dest -Force

`$concluir = Join-Path `$dest 'powershell\Concluir-Troca-Instalacao.ps1'
if (Test-Path -LiteralPath `$concluir) {
    Write-Host '  Abrindo Prompt Auxiliar atualizado...' -ForegroundColor Green
    Start-Process -FilePath 'powershell.exe' -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', `$concluir, '-Destination', `$dest
    ) -WindowStyle Normal
} else {
    `$criar = Join-Path `$dest 'powershell\Criar-Atalho.ps1'
    if (Test-Path -LiteralPath `$criar) {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File `$criar -ProjectRoot `$dest
    }
    `$win = Join-Path `$dest 'win.ps1'
    if (Test-Path -LiteralPath `$win) {
        Start-Process -FilePath 'powershell.exe' -ArgumentList @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', `$win
        ) -WindowStyle Normal
    }
}
Write-Host ''
Write-Host '  Atualizacao concluida.' -ForegroundColor Green
Start-Sleep -Seconds 4
"@
    Write-PromptAuxUtf8NoBom -Path $ps1 -Content $content
    Start-Process -FilePath 'powershell.exe' -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Normal', '-File', $ps1
    ) -WindowStyle Normal | Out-Null
}

function Install-PromptAuxiliarSourceZip {
    param(
        [string]$Destination,
        [string]$Owner,
        [string]$Name,
        [string]$Branch,
        [string]$ScriptDir = ''
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

    $stagingRoot = Join-Path ([System.IO.Path]::GetTempPath()) "PromptAuxiliar-staging-$([Guid]::NewGuid().ToString('n'))"
    New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null
    $staging = Join-Path $stagingRoot 'PromptAuxiliar'
    Move-Item -Path $extracted.FullName -Destination $staging -Force

    $destExists = Test-Path -LiteralPath $Destination
    if ($destExists -and (Test-PromptAuxShouldDeferFolderSwap -Destination $Destination -ScriptDir $ScriptDir)) {
        Write-Host '  Atualizacao adiada: feche ESTA janela (Enter) para concluir a copia dos arquivos.' -ForegroundColor Cyan
        Write-Host '  O atalho da nova versao ja foi criado na Area de Trabalho.' -ForegroundColor DarkGray
        Invoke-PromptAuxDeferredFolderSwap -StagingPath $staging -Destination $Destination
        Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
        Remove-Item $tempExtract -Force -ErrorAction SilentlyContinue
        return @{ Deferred = $true }
    }

    if ($destExists) {
        Write-Host '  Substituindo arquivos da instalacao...' -ForegroundColor DarkGray
        try {
            Remove-Item -LiteralPath $Destination -Recurse -Force -ErrorAction Stop
        } catch {
            Write-Host '  Nao foi possivel substituir agora - aguardando fechar esta janela...' -ForegroundColor Cyan
            Invoke-PromptAuxDeferredFolderSwap -StagingPath $staging -Destination $Destination
            Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
            Remove-Item $tempExtract -Force -ErrorAction SilentlyContinue
            return @{ Deferred = $true }
        }
    }
    New-Item -ItemType Directory -Path (Split-Path $Destination -Parent) -Force | Out-Null
    Move-Item -Path $staging -Destination $Destination -Force

    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
    Remove-Item $tempExtract -Force -ErrorAction SilentlyContinue
    Remove-Item $stagingRoot -Force -ErrorAction SilentlyContinue
    return @{ Deferred = $false }
}

function Install-PromptAuxiliarSource {
    param([string]$Destination, [string]$Owner, [string]$Name, [string]$Ref, [string]$ScriptDir = '')
    Install-PromptAuxiliarSourceZip -Destination $Destination -Owner $Owner -Name $Name -Branch $Ref -ScriptDir $ScriptDir | Out-Null
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

    $script:PromptAuxDeferredExit = $false
    $updateModule = Join-Path $InstallRoot 'powershell\Update-PromptAuxiliar.ps1'
    $mainPy = Join-Path $InstallRoot 'main.py'
    $missingInstall = -not (Test-Path -LiteralPath $mainPy)

    try {
        Sync-PromptAuxUpdateModuleFromGitHub -InstallRoot $InstallRoot -Owner $Owner -Name $Name -Branch $Branch -SourceRoot $ScriptDir
    } catch {
        Write-Host '  Aviso: nao foi possivel baixar Update-PromptAuxiliar.ps1 do GitHub.' -ForegroundColor DarkYellow
    }

    $moduleOk = Test-PromptAuxPs1Syntax -Path $updateModule

    if (-not $moduleOk) {
        Write-Host '  Script de atualizacao local invalido - reinstalando via ZIP...' -ForegroundColor Cyan
        $zipResult = Install-PromptAuxiliarSourceZip -Destination $InstallRoot -Owner $Owner -Name $Name -Branch $Branch -ScriptDir $ScriptDir
        if ($zipResult.Deferred) { $script:PromptAuxDeferredExit = $true; return }
        $moduleOk = Test-PromptAuxPs1Syntax -Path $updateModule
    }

    if ($moduleOk) {
        . $updateModule
        if ($missingInstall -or $Force) {
            Write-Host '  Instalando Prompt Auxiliar...' -ForegroundColor Gray
        } else {
            Write-Host "  Usando instalacao em: $InstallRoot" -ForegroundColor DarkGray
        }
        $updateResult = Update-PromptAuxiliarIfNewer -InstallRoot $InstallRoot -ScriptDir $ScriptDir -Force:$Force
        if ($updateResult -eq 'deferred') { $script:PromptAuxDeferredExit = $true }
        return
    }

    if ($missingInstall -or $Force) {
        Write-Host '  Instalando Prompt Auxiliar...' -ForegroundColor Gray
    } else {
        Write-Host "  Usando instalacao em: $InstallRoot" -ForegroundColor DarkGray
    }
    $zipResult = Install-PromptAuxiliarSourceZip -Destination $InstallRoot -Owner $Owner -Name $Name -Branch $Branch -ScriptDir $ScriptDir
    if ($zipResult.Deferred) {
        $script:PromptAuxDeferredExit = $true
        return
    }
    Write-Host "  Instalado em: $InstallRoot" -ForegroundColor Green
}

function Install-PromptAuxiliarPythonDeps {
    param($PythonInfo, [string]$ProjectRoot)

    Write-Host "  Instalando dependências Python..." -ForegroundColor DarkGray
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
        $code = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }
        if ($code -ne 0) {
            throw "main.py encerrou com codigo $code"
        }
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
Enable-PromptAuxiliarExecutionPolicy

$forceUpdate = $Update -or ($env:PROMPTAUX_UPDATE -eq '1')
$script:PromptAuxDeferredExit = $false
Invoke-PromptAuxiliarInstallOrUpdate `
    -InstallRoot $InstallRoot `
    -ScriptDir $ScriptDir `
    -Owner $RepoOwner `
    -Name $RepoName `
    -Branch $Branch `
    -Force:$forceUpdate

if ($script:PromptAuxDeferredExit) {
    Write-Host ''
    Write-Host '  Pressione Enter e feche esta janela.' -ForegroundColor Green
    Write-Host '  Outra janela concluira a atualizacao e abrira o app.' -ForegroundColor Green
    Read-Host | Out-Null
    exit 0
}

Write-Host '  Sincronizando scripts (.bat) e auxiliares PowerShell...' -ForegroundColor DarkGray
$batSync = Sync-PromptAuxBatScriptsFromGitHub `
    -InstallRoot $InstallRoot `
    -Owner $RepoOwner `
    -Name $RepoName `
    -Branch $Branch `
    -SourceRoot $ScriptDir
Sync-PromptAuxEssentialScriptsFromGitHub `
    -InstallRoot $InstallRoot `
    -Owner $RepoOwner `
    -Name $RepoName `
    -Branch $Branch `
    -SourceRoot $ScriptDir
$uiBat = Join-Path $InstallRoot 'scripts\_ui.bat'
if ($batSync.Fail -gt 0 -and $batSync.Ok -eq 0) {
    if (Test-PromptAuxRepoFilePresent -Path $uiBat) {
        Write-Host '  Scripts .bat: usando copia local (download do GitHub indisponivel nesta execucao).' -ForegroundColor DarkGray
    } else {
        Write-Host '  Aviso: nenhum script .bat disponivel. Verifique internet ou faca push no GitHub.' -ForegroundColor DarkYellow
    }
} elseif ($batSync.Fail -gt 0) {
    Write-Host "  Scripts: $($batSync.Ok) atualizado(s), $($batSync.Fail) mantido(s) da instalacao local." -ForegroundColor DarkGray
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

Write-PromptAuxiliarCmdLauncher -InstallRoot $InstallRoot
Write-Host '  Atualizando atalhos...' -ForegroundColor DarkGray
Repair-PromptAuxDesktopShortcuts -InstallRoot $InstallRoot

Write-Host '  Abrindo interface...' -ForegroundColor Gray
Start-PromptAuxiliarProcess -PythonInfo $python -ProjectRoot $InstallRoot -ExtraArgs @()
