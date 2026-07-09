@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Apps de Inicializacao
echo Abrindo configuracoes...
start ms-settings:startupapps
timeout /t 2 >nul

endlocal
exit /b 0
