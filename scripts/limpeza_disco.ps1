#Requires -Version 5.1
. "$PSScriptRoot\_ui.ps1"

Show-PABanner "Limpeza de armazenamento" "Abre a ferramenta Limpeza de Disco do Windows (cleanmgr)."

if (-not (Confirm-PAAction)) { exit 0 }

$startTime = Get-Date
$results   = [System.Collections.ArrayList]::new()

Invoke-PAStep "Abrindo Limpeza de Disco (cleanmgr)" $results {
    Start-Process "$env:SystemRoot\System32\cleanmgr.exe"
}

Write-Host "  Selecione os itens a remover na janela aberta." -ForegroundColor DarkGray

Write-PASummary -Results $results -StartTime $startTime -Titulo "limpeza_disco"
