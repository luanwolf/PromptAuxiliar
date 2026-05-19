@echo off
setlocal EnableExtensions EnableDelayedExpansion
call "%~dp0_ui.bat" :banner "Ativar Windows (KMS)" "Executa irm https://get.activated.win | iex no PowerShell como administrador."

call "%~dp0_ui.bat" :confirmar_perigo
if errorlevel 1 call "%~dp0_ui.bat" :sair 0 & exit /b 0
set "EXIT_CODE=0"
title Ativar Windows (KMS)
set "PA_PS=%TEMP%\pa_KMS_Windows.ps1"
(
  echo $Host.UI.RawUI.WindowTitle = 'KMS_Windows ^| Prompt Auxiliar'
  echo irm https://get.activated.win | iex
)>"!PA_PS!"
echo   Abrindo PowerShell como administrador...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-NoExit','-File','!PA_PS!'"

call "%~dp0_ui.bat" :sair %EXIT_CODE%
endlocal
exit /b %EXIT_CODE%
