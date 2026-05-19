@echo off
setlocal EnableExtensions EnableDelayedExpansion
call "%~dp0_ui.bat" :banner "Apps de inicializacao" "Abre as Configuracoes do Windows para gerenciar programas que iniciam com o sistema."

call "%~dp0_ui.bat" :confirmar
if errorlevel 1 call "%~dp0_ui.bat" :sair 0 & exit /b 0
set "EXIT_CODE=0"
title Apps de inicializacao
echo   Abrindo Configuracoes...
start ms-settings:startupapps
echo   Janela aberta. Ajuste os apps desejados.

call "%~dp0_ui.bat" :sair %EXIT_CODE%
endlocal
exit /b %EXIT_CODE%
