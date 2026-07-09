#Requires -Version 5.1
. "$PSScriptRoot\_ui.ps1"

Show-PABanner "Atualizar programas" "Atualiza pacotes instalados via Winget (pode demorar varios minutos)."

if (-not (Confirm-PAAction)) { exit 0 }

$startTime = Get-Date
$results   = [System.Collections.ArrayList]::new()

Invoke-PAStep "Atualizando todos os pacotes via Winget" $results {
    winget upgrade --all --silent --accept-package-agreements --include-unknown
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "winget saiu com código $LASTEXITCODE"
    }
}

Write-PASummary -Results $results -StartTime $startTime -Titulo "atualizar_softwares"
