@echo off
setlocal EnableExtensions EnableDelayedExpansion
title WinUtil
echo Script de terceiros. USE POR SUA CONTA E RISCO.
pause
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm -useb https://christitus.com/win | iex"

endlocal
exit /b 0
