@echo off
setlocal EnableExtensions EnableDelayedExpansion
call "%~dp0_ui.bat" :banner "Visual C++ Runtimes (All-in-One)" "Instala Visual C++ Redistributable AIO (abbodi1406) via Winget — pacotes 2005 a 2022."

call "%~dp0_ui.bat" :confirmar
if errorlevel 1 call "%~dp0_ui.bat" :sair 0 & exit /b 0
set "EXIT_CODE=0"
title Visual C++ Runtimes (All-in-One)
echo   Instalando abbodi1406.vcredist ...
winget install --id abbodi1406.vcredist --accept-source-agreements --accept-package-agreements -h
if errorlevel 1 set "EXIT_CODE=1"

call "%~dp0_ui.bat" :sair %EXIT_CODE%
endlocal
exit /b %EXIT_CODE%
