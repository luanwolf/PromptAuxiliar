#Requires -Version 5.1
. "$PSScriptRoot\_ui.ps1"

Show-PABanner "Visual C++ Runtimes (All-in-One)" "Instala Visual C++ Redistributable AIO (abbodi1406) via Winget — pacotes 2005 a 2022."

if (-not (Confirm-PAAction)) { exit 0 }

$startTime = Get-Date
$results   = [System.Collections.ArrayList]::new()

Invoke-PAStep "Instalando abbodi1406.vcredist via Winget" $results {
    winget install --id abbodi1406.vcredist --accept-source-agreements --accept-package-agreements -h
    if ($LASTEXITCODE -and $LASTEXITCODE -notin @(0, -1978335189)) {
        throw "winget saiu com codigo $LASTEXITCODE"
    }
}

Write-PASummary -Results $results -StartTime $startTime -Titulo "instalar_runtimes"
