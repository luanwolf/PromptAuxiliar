#Requires -Version 5.1
. "$PSScriptRoot\_ui.ps1"

Show-PABanner "Aplicar ajustes de registro" "Importa todos os arquivos .reg da pasta C:\PromptAuxiliar\registros."

if (-not (Confirm-PAAction -Perigo)) { exit 0 }

$startTime = Get-Date
$results   = [System.Collections.ArrayList]::new()
$pasta     = "C:\PromptAuxiliar\registros"

Invoke-PAStep "Verificando pasta de registros" $results {
    if (-not (Test-Path $pasta)) {
        New-Item $pasta -ItemType Directory -Force | Out-Null
    }
}

$regFiles = @(Get-Item "$pasta\*.reg" -EA 0)

if ($regFiles.Count -eq 0) {
    Write-Host ""
    Write-Host "  Nenhum arquivo .reg encontrado. Abrindo a pasta..." -ForegroundColor Yellow
    Start-Process $pasta
} else {
    Write-Host "  $($regFiles.Count) arquivo(s) .reg encontrado(s)." -ForegroundColor DarkGray
    Write-Host ""
    foreach ($reg in $regFiles) {
        Invoke-PAStep "Importando $($reg.Name)" $results {
            $proc = Start-Process -FilePath "reg.exe" `
                -ArgumentList "import `"$($reg.FullName)`"" `
                -Wait -PassThru -NoNewWindow
            if ($proc.ExitCode -ne 0) {
                throw "reg import saiu com codigo $($proc.ExitCode)"
            }
        }
    }
}

Write-PASummary -Results $results -StartTime $startTime -Titulo "aplicar_ajustes"
