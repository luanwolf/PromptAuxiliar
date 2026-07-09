# Limpeza de Temporarios - Prompt Auxiliar
$ErrorActionPreference = 'SilentlyContinue'

Write-Host "========================================"
Write-Host "  LIMPEZA DE ARQUIVOS TEMPORARIOS"
Write-Host "  Prompt Auxiliar"
Write-Host "========================================"
Write-Host ""

Write-Host "[1/4] Esvaziando Lixeira..."
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Host "      Concluido."
Write-Host ""

Write-Host "[2/4] Limpando pastas Temp dos usuarios (AppData\Local\Temp)..."
Get-ChildItem -Path 'C:\Users' -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $tempPath = Join-Path $_.FullName 'AppData\Local\Temp'
    if (Test-Path $tempPath) {
        Write-Host "      Usuario: $($_.Name)"
        Get-ChildItem -Path $tempPath -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "      Concluido."
Write-Host ""

Write-Host "[3/4] Limpando C:\Windows\Temp..."
if (Test-Path 'C:\Windows\Temp') {
    Get-ChildItem -Path 'C:\Windows\Temp' -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "      Concluido."
Write-Host ""

Write-Host "[4/4] Limpando pasta TEMP da sessao atual ($env:TEMP)..."
if (Test-Path $env:TEMP) {
    Get-ChildItem -Path $env:TEMP -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "      Concluido."
Write-Host ""
Write-Host "Limpeza finalizada."
Read-Host "Pressione Enter para sair"
