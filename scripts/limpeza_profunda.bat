chcp 65001 >nul 2>&1
@echo off
setlocal EnableExtensions EnableDelayedExpansion
call "%~dp0_ui.bat" :banner "Limpeza profunda do Windows" "Limpa TEMP e Prefetch, flush DNS, cleanmgr, SFC e DISM - operação longa."

call "%~dp0_ui.bat" :confirmar
if errorlevel 1 call "%~dp0_ui.bat" :sair 0 & exit /b 0
set "EXIT_CODE=0"
title Limpeza profunda do Windows
echo   [1/6] Pastas TEMP...
del /q /f /s "%TEMP%\*" >nul 2>&1
del /q /f /s "%SystemRoot%\Temp\*" >nul 2>&1
echo   [2/6] Prefetch...
del /q /f /s "%SystemRoot%\Prefetch\*" >nul 2>&1
echo   [3/6] Cache DNS...
ipconfig /flushdns
echo   [4/6] Limpeza de disco (cleanmgr)...
cleanmgr /sageset:1 >nul 2>&1
cleanmgr /sagerun:1
echo   [5/6] Verificação de arquivos do sistema (SFC)...
sfc /scannow
echo   [6/6] Reparo de imagem (DISM)...
Dism /online /cleanup-image /restorehealth

call "%~dp0_ui.bat" :sair %EXIT_CODE%
endlocal
exit /b %EXIT_CODE%
