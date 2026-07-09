#Requires -Version 5.1
. "$PSScriptRoot\_ui.ps1"

Show-PABanner "Apps de inicialização" "Abre as Configurações do Windows para gerenciar programas que iniciam com o sistema."

if (-not (Confirm-PAAction)) { exit 0 }

$startTime = Get-Date
$results   = [System.Collections.ArrayList]::new()

Invoke-PAStep "Abrindo Configurações > Apps de inicialização" $results {
    Start-Process "ms-settings:startupapps"
}

Write-Host "  Ajuste os apps desejados na janela de Configurações." -ForegroundColor DarkGray

Write-PASummary -Results $results -StartTime $startTime -Titulo "gerenciar_inicializacao"
