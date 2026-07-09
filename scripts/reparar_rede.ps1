#Requires -Version 5.1
. "$PSScriptRoot\_ui.ps1"

Show-PABanner "Reparar conexão de rede" "Libera e renova o IP, limpa o cache DNS, redefine Winsock e a pilha TCP/IP."

if (-not (Confirm-PAAction)) { exit 0 }

$startTime = Get-Date
$results   = [System.Collections.ArrayList]::new()

Invoke-PAStep "Liberando IP (ipconfig /release)" $results {
    ipconfig /release | Out-Null
}

Invoke-PAStep "Renovando IP (ipconfig /renew)" $results {
    ipconfig /renew | Out-Null
}

Invoke-PAStep "Limpando cache DNS (ipconfig /flushdns)" $results {
    ipconfig /flushdns | Out-Null
}

Invoke-PAStep "Redefinindo Winsock (netsh winsock reset)" $results {
    netsh winsock reset | Out-Null
}

Invoke-PAStep "Redefinindo pilha TCP/IP (netsh int ip reset)" $results {
    netsh int ip reset | Out-Null
}

Invoke-PAStep "Registrando DNS (ipconfig /registerdns)" $results {
    ipconfig /registerdns | Out-Null
}

Write-Host ""
Write-Host "  Reinicie o PC se o problema de conexão persistir." -ForegroundColor DarkGray

Write-PASummary -Results $results -StartTime $startTime -Titulo "reparar_rede" -NeedRestart
