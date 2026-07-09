@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Limpeza de Disco
echo Abrindo cleanmgr...
start "" "%SystemRoot%\System32\cleanmgr.exe"
timeout /t 2 >nul

endlocal
exit /b 0
