# Pos-troca da instalacao (atualizacao adiada): corrige pasta, recria atalhos e abre o app.
#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)]
    [string]$Destination
)

$ErrorActionPreference = 'Stop'
$Destination = (Resolve-Path -LiteralPath $Destination).Path
$env:PROMPTAUX_HOME = $Destination

function Repair-PromptAuxNestedInstall {
    param([string]$Root)
    $main = Join-Path $Root 'main.py'
    if (Test-Path -LiteralPath $main) { return }
    $nested = Join-Path $Root 'PromptAuxiliar'
    $nestedMain = Join-Path $nested 'main.py'
    if (-not (Test-Path -LiteralPath $nestedMain)) { return }
    Write-Host '  Corrigindo estrutura da pasta de instalacao...' -ForegroundColor DarkYellow
    Get-ChildItem -LiteralPath $nested -Force | ForEach-Object {
        $target = Join-Path $Root $_.Name
        if (Test-Path -LiteralPath $target) {
            Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue
        }
        Move-Item -LiteralPath $_.FullName -Destination $Root -Force
    }
    Remove-Item -LiteralPath $nested -Recurse -Force -ErrorAction SilentlyContinue
}

Repair-PromptAuxNestedInstall -Root $Destination

$main = Join-Path $Destination 'main.py'
if (-not (Test-Path -LiteralPath $main)) {
    Write-Host "ERRO: Instalacao incompleta em $Destination (main.py ausente)." -ForegroundColor Red
    Write-Host 'Execute: irm "https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/win.ps1" | iex'
    Read-Host 'Pressione Enter para fechar'
    exit 1
}

$criar = Join-Path $Destination 'powershell\Criar-Atalho.ps1'
if (Test-Path -LiteralPath $criar) {
    Write-Host '  Atualizando atalhos...' -ForegroundColor DarkGray
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $criar -ProjectRoot $Destination
}

$win = Join-Path $Destination 'win.ps1'
if (-not (Test-Path -LiteralPath $win)) {
    Write-Host "ERRO: win.ps1 nao encontrado em $Destination" -ForegroundColor Red
    Read-Host 'Pressione Enter para fechar'
    exit 1
}

Write-Host '  Abrindo Prompt Auxiliar...' -ForegroundColor Gray
Start-Process -FilePath 'powershell.exe' -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $win
) -WindowStyle Normal
