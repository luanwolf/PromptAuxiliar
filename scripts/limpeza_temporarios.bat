@echo off
setlocal EnableExtensions EnableDelayedExpansion
call "%~dp0_ui.bat" :banner "Limpeza de temporarios" "Remove temporarios, esvazia a Lixeira e limpa cache das pastas Temp."

call "%~dp0_ui.bat" :confirmar
if errorlevel 1 call "%~dp0_ui.bat" :sair 0 & exit /b 0
set "EXIT_CODE=0"
title Limpeza de temporarios
if exist "%~dp0limpeza_temporarios.ps1" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0limpeza_temporarios.ps1"
  if errorlevel 1 set "EXIT_CODE=1"
) else (
  echo   [1/1] Limpando TEMP da sessao...
  del /q /f /s "%TEMP%\*" >nul 2>&1
)

call "%~dp0_ui.bat" :sair %EXIT_CODE%
endlocal
exit /b %EXIT_CODE%
