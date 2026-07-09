@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Limpeza Profunda
echo [1/6] TEMP...
del /q /f /s "%TEMP%\*" >nul 2>&1
del /q /f /s "%SystemRoot%\Temp\*" >nul 2>&1
echo [2/6] Prefetch...
del /q /f /s "%SystemRoot%\Prefetch\*" >nul 2>&1
echo [3/6] DNS...
ipconfig /flushdns
echo [4/6] Limpeza de disco...
cleanmgr /sageset:1 >nul 2>&1
cleanmgr /sagerun:1
echo [5/6] SFC (demora)...
sfc /scannow
echo [6/6] DISM...
Dism /online /cleanup-image /restorehealth
echo.
pause

endlocal
exit /b 0
