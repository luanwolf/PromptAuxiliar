#Requires -Version 5.1
. "$PSScriptRoot\_ui.ps1"

Show-PABanner "Instalar da pasta Software" "Executa instaladores .exe, .msi e atalhos .lnk de C:\PromptAuxiliar\softwares."

if (-not (Confirm-PAAction)) { exit 0 }

$startTime = Get-Date
$results   = [System.Collections.ArrayList]::new()
$pasta     = "C:\PromptAuxiliar\softwares"

Invoke-PAStep "Verificando pasta de instaladores" $results {
    if (-not (Test-Path $pasta)) {
        New-Item $pasta -ItemType Directory -Force | Out-Null
    }
}

$arquivos = @(Get-Item "$pasta\*.exe" -EA 0) +
            @(Get-Item "$pasta\*.msi" -EA 0) +
            @(Get-Item "$pasta\*.lnk" -EA 0)

if ($arquivos.Count -eq 0) {
    Write-Host ""
    Write-Host "  Nenhum instalador encontrado. Abrindo a pasta..." -ForegroundColor Yellow
    Start-Process $pasta
} else {
    Write-Host "  $($arquivos.Count) instalador(es) encontrado(s)." -ForegroundColor DarkGray
    Write-Host ""
    foreach ($arq in $arquivos) {
        Invoke-PAStep "Executando $($arq.Name)" $results {
            Start-Process -FilePath $arq.FullName -Wait
        }
    }
}

Write-PASummary -Results $results -StartTime $startTime -Titulo "instalar_software"
