#Requires -Version 5.1
. "$PSScriptRoot\_ui.ps1"

Show-PABanner "Criar atalhos (GodMode e BIOS)" "Cria a pasta GodMode na Area de Trabalho e atalho para reiniciar no BIOS."

if (-not (Confirm-PAAction)) { exit 0 }

$startTime = Get-Date
$results   = [System.Collections.ArrayList]::new()
$desktop   = [Environment]::GetFolderPath("Desktop")

Invoke-PAStep "Criando pasta GodMode" $results {
    $gm = Join-Path $desktop "GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"
    if (-not (Test-Path $gm)) {
        New-Item -Path $gm -ItemType Directory -Force | Out-Null
    }
}

Invoke-PAStep "Criando atalho 'Reiniciar no BIOS'" $results {
    $wsh = New-Object -ComObject WScript.Shell
    $lnk = $wsh.CreateShortcut((Join-Path $desktop "Reiniciar BIOS.lnk"))
    $lnk.TargetPath  = "shutdown.exe"
    $lnk.Arguments   = "/r /fw /t 0"
    $lnk.Description = "Reiniciar diretamente no firmware UEFI/BIOS"
    $lnk.Save()
}

Write-PASummary -Results $results -StartTime $startTime -Titulo "criar_atalhos"
