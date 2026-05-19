#Requires -Version 5.1
. "$PSScriptRoot\_ui.ps1"

Show-PABanner "Apps de inicializacao" "Abre as Configuracoes do Windows para gerenciar programas que iniciam com o sistema."

if (-not (Confirm-PAAction)) { exit 0 }

$startTime = Get-Date
$results   = [System.Collections.ArrayList]::new()

Invoke-PAStep "Abrindo Configuracoes > Apps de inicializacao" $results {
    Start-Process "ms-settings:startupapps"
}

Write-Host "  Ajuste os apps desejados na janela de Configuracoes." -ForegroundColor DarkGray

Write-PASummary -Results $results -StartTime $startTime -Titulo "gerenciar_inicializacao"
