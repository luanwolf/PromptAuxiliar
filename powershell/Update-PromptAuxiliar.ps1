# Verifica versão no GitHub e atualiza a pasta de instalação (ZIP da branch).
#Requires -Version 5.1
# Encoding: UTF-8 with BOM (compativel com Windows PowerShell 5.1)

function Get-PromptAuxRepoConfig {
    param([string]$InstallRoot)

    $owner = if ($env:PROMPTAUX_REPO_OWNER) { $env:PROMPTAUX_REPO_OWNER } else { 'luanwolf' }
    $name = if ($env:PROMPTAUX_REPO_NAME) { $env:PROMPTAUX_REPO_NAME } else { 'PromptAuxiliar' }
    $branch = if ($env:PROMPTAUX_BRANCH) { $env:PROMPTAUX_BRANCH } else { 'main' }

    $cfg = Join-Path $InstallRoot 'app\config.py'
    if (Test-Path -LiteralPath $cfg) {
        $text = Get-Content -LiteralPath $cfg -Raw -ErrorAction SilentlyContinue
        if ($text -match 'GITHUB_OWNER\s*=\s*"([^"]+)"') { $owner = $Matches[1] }
        if ($text -match 'GITHUB_REPO\s*=\s*"([^"]+)"') { $name = $Matches[1] }
        if ($text -match 'GITHUB_BRANCH\s*=\s*"([^"]+)"') { $branch = $Matches[1] }
    }

    return @{ Owner = $owner; Name = $name; Branch = $branch }
}

function Get-PromptAuxVersionFromConfigText {
    param([string]$Text)
    if ($Text -match 'APP_VERSION\s*=\s*"([^"]+)"') { return $Matches[1].Trim() }
    return $null
}

function Get-PromptAuxLocalVersion {
    param([string]$InstallRoot)

    $cfg = Join-Path $InstallRoot 'app\config.py'
    if (Test-Path -LiteralPath $cfg) {
        return Get-PromptAuxVersionFromConfigText -Text (Get-Content -LiteralPath $cfg -Raw)
    }
    return $null
}

function Get-PromptAuxRemoteVersion {
    param([string]$Owner, [string]$Name, [string]$Branch)

    $cacheBust = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $url = "https://raw.githubusercontent.com/$Owner/$Name/$Branch/app/config.py?_=$cacheBust"
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $text = (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 25).Content
        return Get-PromptAuxVersionFromConfigText -Text $text
    } catch {
        Write-Host "  Não foi possivel consultar atualizacoes ($url)." -ForegroundColor DarkYellow
        return $null
    }
}

function Compare-PromptAuxVersion {
    param([string]$Local, [string]$Remote)

    if (-not $Remote) { return $null }
    if (-not $Local) { return -1 }

    $pa = @($Local.Split('.') | ForEach-Object { [int]($_ -replace '\D.*$', '0') })
    $pb = @($Remote.Split('.') | ForEach-Object { [int]($_ -replace '\D.*$', '0') })
    $n = [Math]::Max($pa.Count, $pb.Count)
    for ($i = 0; $i -lt $n; $i++) {
        $va = if ($i -lt $pa.Count) { $pa[$i] } else { 0 }
        $vb = if ($i -lt $pb.Count) { $pb[$i] } else { 0 }
        if ($va -lt $vb) { return -1 }
        if ($va -gt $vb) { return 1 }
    }
    return 0
}

function Test-PromptAuxSkipAutoUpdate {
    param([string]$InstallRoot, [string]$ScriptDir)

    if ($env:PROMPTAUX_SKIP_AUTO_UPDATE -eq '1') { return $true }

    $defaultInstall = Join-Path $env:LOCALAPPDATA 'PromptAuxiliar'
    if ($InstallRoot -and (Test-Path -LiteralPath $defaultInstall)) {
        try {
            $a = (Resolve-Path -LiteralPath $InstallRoot).Path.TrimEnd('\')
            $b = (Resolve-Path -LiteralPath $defaultInstall).Path.TrimEnd('\')
            if ($a -ieq $b) { return $false }
        } catch { }
    }

    if (-not (Test-Path (Join-Path $InstallRoot '.git'))) { return $false }
    if ($ScriptDir -and $InstallRoot) {
        try {
            if ((Resolve-Path $InstallRoot).Path -eq (Resolve-Path $ScriptDir).Path) { return $true }
        } catch {
            return $true
        }
    }
    return $false
}

function Write-PromptAuxUtf8NoBom {
    param([string]$Path, [string]$Content)
    $utf8 = New-Object System.Text.UTF8Encoding $false
    $text = $Content.TrimStart([char]0xFEFF)
    [System.IO.File]::WriteAllText($Path, $text, $utf8)
}

function Test-PromptAuxPathInUse {
    param([string]$Path, [int]$ExcludePid = 0)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $root = $Path.TrimEnd('\')
    $pattern = $root + '*'
    $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
    foreach ($p in $procs) {
        if ($p.ProcessId -eq $PID) { continue }
        if ($ExcludePid -gt 0 -and $p.ProcessId -eq $ExcludePid) { continue }
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

    # Adia somente se algum processo esta usando arquivos da pasta
    if (Test-PromptAuxPathInUse -Path $Destination) {
        return $true
    }

    # Adia se o diretorio atual esta dentro da pasta destino
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
# Prompt Auxiliar - troca de pasta apos atualização
`$Host.UI.RawUI.WindowTitle = 'Prompt Auxiliar - concluindo atualização'
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

Write-Host '  Substituindo arquivos da instalação...' -ForegroundColor DarkGray
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
Write-Host '  Atualizacao concluída.' -ForegroundColor Green
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
    if ($destExists) {
        Write-Host '  Substituindo arquivos da instalação...' -ForegroundColor DarkGray
        try {
            Remove-Item -LiteralPath $Destination -Recurse -Force -ErrorAction Stop
        } catch {
            Write-Host '  Arquivo em uso - atualização sera aplicada apos fechar esta janela.' -ForegroundColor Cyan
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

function Update-PromptAuxiliarRefreshShortcuts {
    param([string]$InstallRoot)
    $criar = Join-Path $InstallRoot 'powershell\Criar-Atalho.ps1'
    if (-not (Test-Path -LiteralPath $criar)) { return }
    Write-Host '  Atualizando atalhos...' -ForegroundColor DarkGray
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $criar -ProjectRoot $InstallRoot
}

function Update-PromptAuxiliarIfNewer {
    param(
        [string]$InstallRoot,
        [string]$ScriptDir = '',
        [switch]$Force
    )

    if (Test-PromptAuxSkipAutoUpdate -InstallRoot $InstallRoot -ScriptDir $ScriptDir) {
        Write-Host '  Atualizacao automatica desativada (clone local / PROMPTAUX_SKIP_AUTO_UPDATE).' -ForegroundColor DarkGray
        return $false
    }

    $repo = Get-PromptAuxRepoConfig -InstallRoot $InstallRoot
    $local = Get-PromptAuxLocalVersion -InstallRoot $InstallRoot
    $remote = Get-PromptAuxRemoteVersion -Owner $repo.Owner -Name $repo.Name -Branch $repo.Branch

    $missing = -not (Test-Path (Join-Path $InstallRoot 'main.py'))
    $cmp = Compare-PromptAuxVersion -Local $local -Remote $remote

    if ($null -eq $cmp -and -not $missing -and -not $Force) {
        Write-Host '  Não foi possivel comparar com a versão remota.' -ForegroundColor DarkYellow
        return $false
    }

    if (-not $Force -and -not $missing -and ($null -ne $cmp) -and $cmp -ge 0) {
        if ($local) {
            $suffix = if ($cmp -gt 0) { ' (local mais recente que o GitHub)' } else { ' - ja atualizado.' }
            $msg = "  Versao local v$local (remota v$remote)$suffix"
            Write-Host $msg -ForegroundColor DarkGray
        }
        return $false
    }

    if ($remote) {
        $msg = "  Atualizacao disponível: v$local -> v$remote"
        Write-Host $msg -ForegroundColor Cyan
    } elseif ($missing) {
        Write-Host '  Instalação não encontrada - baixando...' -ForegroundColor Cyan
    }

    $zipResult = Install-PromptAuxiliarSourceZip -Destination $InstallRoot -Owner $repo.Owner -Name $repo.Name -Branch $repo.Branch -ScriptDir $ScriptDir
    if ($zipResult.Deferred) {
        return 'deferred'
    }
    Update-PromptAuxiliarRefreshShortcuts -InstallRoot $InstallRoot
    Write-Host "  Atualizado em: $InstallRoot" -ForegroundColor Green
    return $true
}
