#Requires -Version 5.1
. "$PSScriptRoot\_ui.ps1"

Show-PABanner "Ativar Windows (slmgr)" "Executa slmgr /ato para tentar ativacao online do Windows."

if (-not (Confirm-PAAction -Perigo)) { exit 0 }

$startTime = Get-Date
$results   = [System.Collections.ArrayList]::new()

Invoke-PAStep "Executando slmgr /ato" $results {
    $proc = Start-Process -FilePath "cscript.exe" `
        -ArgumentList "//nologo `"$env:SystemRoot\System32\slmgr.vbs`" /ato" `
        -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -ne 0) {
        throw "slmgr saiu com codigo $($proc.ExitCode)"
    }
}

Write-PASummary -Results $results -StartTime $startTime -Titulo "ativar_windows_slmgr"
