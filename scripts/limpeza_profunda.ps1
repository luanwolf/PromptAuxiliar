#Requires -Version 5.1
. "$PSScriptRoot\_ui.ps1"

Show-PABanner "Limpeza profunda do Windows" "Limpa TEMP e Prefetch, flush DNS, cleanmgr, SFC e DISM — operacao longa."

if (-not (Confirm-PAAction)) { exit 0 }

$startTime = Get-Date
$results   = [System.Collections.ArrayList]::new()

Invoke-PAStep "Limpando pastas TEMP" $results {
    Get-ChildItem $env:TEMP -Recurse -Force -EA 0 | Remove-Item -Recurse -Force -EA 0
    Get-ChildItem "$env:SystemRoot\Temp" -Recurse -Force -EA 0 | Remove-Item -Recurse -Force -EA 0
}

Invoke-PAStep "Limpando Prefetch" $results {
    Get-ChildItem "$env:SystemRoot\Prefetch" -Force -EA 0 | Remove-Item -Force -EA 0
}

Invoke-PAStep "Limpando cache DNS" $results {
    ipconfig /flushdns | Out-Null
}

Invoke-PAStep "Limpeza de disco (cleanmgr /sagerun)" $results {
    Start-Process -FilePath "$env:SystemRoot\System32\cleanmgr.exe" -ArgumentList "/sageset:65535" -Wait -EA 0
    Start-Process -FilePath "$env:SystemRoot\System32\cleanmgr.exe" -ArgumentList "/sagerun:65535" -Wait
}

Invoke-PAStep "Verificacao de arquivos do sistema (SFC /scannow)" $results {
    $proc = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -and $proc.ExitCode -ne 0) {
        throw "SFC saiu com codigo $($proc.ExitCode)"
    }
}

Invoke-PAStep "Reparo de imagem do Windows (DISM /RestoreHealth)" $results {
    $proc = Start-Process -FilePath "Dism.exe" `
        -ArgumentList "/online /cleanup-image /restorehealth" `
        -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -and $proc.ExitCode -ne 0) {
        throw "DISM saiu com codigo $($proc.ExitCode)"
    }
}

Write-PASummary -Results $results -StartTime $startTime -Titulo "limpeza_profunda"
