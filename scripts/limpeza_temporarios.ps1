#Requires -Version 5.1
. "$PSScriptRoot\_ui.ps1"

Show-PABanner "Limpeza de temporarios" "Remove temporarios do usuario e do sistema, esvazia a Lixeira e limpa caches de pastas Temp."

if (-not (Confirm-PAAction)) { exit 0 }

$startTime = Get-Date
$results   = [System.Collections.ArrayList]::new()

Invoke-PAStep "Limpando TEMP do usuario ($env:TEMP)" $results {
    Get-ChildItem $env:TEMP -Recurse -Force -EA 0 |
        Remove-Item -Recurse -Force -EA 0
}

Invoke-PAStep "Limpando TEMP do sistema ($env:SystemRoot\Temp)" $results {
    Get-ChildItem "$env:SystemRoot\Temp" -Recurse -Force -EA 0 |
        Remove-Item -Recurse -Force -EA 0
}

Invoke-PAStep "Esvaziando Lixeira" $results {
    Clear-RecycleBin -Force -EA 0
}

Invoke-PAStep "Limpando cache DNS" $results {
    ipconfig /flushdns | Out-Null
}

Write-PASummary -Results $results -StartTime $startTime -Titulo "limpeza_temporarios"
