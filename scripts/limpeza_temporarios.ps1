# Limpeza de temporarios — chamado por limpeza_temporarios.bat
$ErrorActionPreference = 'SilentlyContinue'

Write-Host "   [1/4] Esvaziando Lixeira..."
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Host "         Concluido."

Write-Host "   [2/4] Temp dos usuarios (AppData\Local\Temp)..."
Get-ChildItem -Path 'C:\Users' -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $tempPath = Join-Path $_.FullName 'AppData\Local\Temp'
    if (Test-Path $tempPath) {
        Write-Host "         Usuario: $($_.Name)"
        Get-ChildItem -Path $tempPath -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "         Concluido."

Write-Host "   [3/4] C:\Windows\Temp..."
if (Test-Path 'C:\Windows\Temp') {
    Get-ChildItem -Path 'C:\Windows\Temp' -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "         Concluido."

Write-Host "   [4/4] TEMP da sessao ($env:TEMP)..."
if (Test-Path $env:TEMP) {
    Get-ChildItem -Path $env:TEMP -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "         Concluido."
