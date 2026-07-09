chcp 65001 >nul 2>&1
@echo off
setlocal EnableExtensions EnableDelayedExpansion
call "%~dp0_ui.bat" :banner "Ativar Windows (slmgr)" "Executa slmgr /ato para tentar ativação online do Windows."

call "%~dp0_ui.bat" :confirmar_perigo
if errorlevel 1 call "%~dp0_ui.bat" :sair 0 & exit /b 0
set "EXIT_CODE=0"
title Ativar Windows (slmgr)
echo   Executando slmgr /ato ...
cscript //nologo "%SystemRoot%\System32\slmgr.vbs" /ato
if errorlevel 1 set "EXIT_CODE=1"

call "%~dp0_ui.bat" :sair %EXIT_CODE%
endlocal
exit /b %EXIT_CODE%
