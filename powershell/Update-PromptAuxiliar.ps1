# Verifica versao no GitHub e atualiza a pasta de instalacao (ZIP da branch).
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

    $url = "https://raw.githubusercontent.com/$Owner/$Name/$Branch/app/config.py"
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $text = (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 25).Content
        return Get-PromptAuxVersionFromConfigText -Text $text
    } catch {
        Write-Host "  Nao foi possivel consultar atualizacoes ($url)." -ForegroundColor DarkYellow
        return $null
    }
}

function Compare-PromptAuxVersion {
    param([string]$Local, [string]$Remote)

    if (-not $Remote) { return 0 }
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
    if ($ScriptDir -and $InstallRoot -and ((Resolve-Path $InstallRoot).Path -eq (Resolve-Path $ScriptDir).Path)) {
        if (Test-Path (Join-Path $InstallRoot '.git')) { return $true }
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
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $pattern = ($Path.TrimEnd('\') + '*')
    $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object { $_.ExecutablePath -and ($_.ExecutablePath -like $pattern) }
    return [bool]$procs
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

function Invoke-PromptAuxDeferredFolderSwap {
    param(
        [string]$StagingPath,
        [string]$Destination
    )
    $destEsc = $Destination.Replace("'", "''")
    $stageEsc = $StagingPath.Replace("'", "''")
    $ps1 = Join-Path ([System.IO.Path]::GetTempPath()) 'promptauxiliar-update-swap.ps1'
    $content = @"
# Prompt Auxiliar - troca de pasta apos atualizacao
`$ErrorActionPreference = 'SilentlyContinue'
`$dest = '$destEsc'
`$staging = '$stageEsc'
Start-Sleep -Seconds 2
for (`$w = 0; `$w -lt 90; `$w++) {
    `$pattern = (`$dest.TrimEnd('\') + '*')
    `$procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object { `$_.ExecutablePath -and (`$_.ExecutablePath -like `$pattern) }
    if (-not `$procs) { break }
    Start-Sleep -Seconds 1
}
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
"@
    Write-PromptAuxUtf8NoBom -Path $ps1 -Content $content
    Start-Process -FilePath 'powershell.exe' -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', $ps1
    ) -WindowStyle Hidden | Out-Null
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
    $needsDeferred = $false
    if ($destExists) {
        if (Test-PromptAuxRunningFromPath -InstallRoot $Destination -ScriptDir $ScriptDir) {
            $needsDeferred = $true
        } elseif (Test-PromptAuxPathInUse -Path $Destination) {
            $needsDeferred = $true
        }
    }

    if ($needsDeferred) {
        Write-Host '  Pasta em uso - atualizacao sera concluida ao fechar esta janela...' -ForegroundColor Cyan
        Invoke-PromptAuxDeferredFolderSwap -StagingPath $staging -Destination $Destination
        Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
        Remove-Item $tempExtract -Force -ErrorAction SilentlyContinue
        return @{ Deferred = $true }
    }

    if ($destExists) {
        Write-Host '  Substituindo arquivos da instalacao...' -ForegroundColor DarkGray
        Remove-Item $Destination -Recurse -Force
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

    if (-not $Force -and -not $missing -and $cmp -ge 0) {
        if ($local) {
            $msg = "  Versao local v$local (remota v$remote) - ja atualizado."
            Write-Host $msg -ForegroundColor DarkGray
        }
        return $false
    }

    if ($remote) {
        $msg = "  Atualizacao disponivel: v$local -> v$remote"
        Write-Host $msg -ForegroundColor Cyan
    } elseif ($missing) {
        Write-Host '  Instalacao nao encontrada - baixando...' -ForegroundColor Cyan
    }

    $zipResult = Install-PromptAuxiliarSourceZip -Destination $InstallRoot -Owner $repo.Owner -Name $repo.Name -Branch $repo.Branch -ScriptDir $ScriptDir
    if ($zipResult.Deferred) {
        Write-Host '  Feche esta janela (Enter). O app abrira atualizado em seguida.' -ForegroundColor Green
        return 'deferred'
    }
    Update-PromptAuxiliarRefreshShortcuts -InstallRoot $InstallRoot
    Write-Host "  Atualizado em: $InstallRoot" -ForegroundColor Green
    return $true
}
