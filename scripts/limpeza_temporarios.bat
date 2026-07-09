@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Limpeza de Temporarios
if exist "%~dp0limpeza_temporarios.ps1" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0limpeza_temporarios.ps1"
) else (
  echo Limpando...
  del /q /f /s "%TEMP%\*" >nul 2>&1
  echo Concluido.
  pause
)

endlocal
exit /b 0
