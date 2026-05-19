@echo off
setlocal EnableExtensions EnableDelayedExpansion
call "%~dp0_ui.bat" :banner "Atualizar programas" "Atualiza pacotes instalados via Winget (pode demorar varios minutos)."

call "%~dp0_ui.bat" :confirmar
if errorlevel 1 call "%~dp0_ui.bat" :sair 0 & exit /b 0
set "EXIT_CODE=0"
title Atualizar programas
echo   Iniciando winget upgrade --all ...
winget upgrade --all --silent --accept-package-agreements --include-unknown
if errorlevel 1 set "EXIT_CODE=1"

call "%~dp0_ui.bat" :sair %EXIT_CODE%
endlocal
exit /b %EXIT_CODE%
