@echo off
setlocal EnableExtensions EnableDelayedExpansion
call "%~dp0_ui.bat" :banner "Criar atalhos (GodMode e BIOS)" "Cria a pasta GodMode na Area de Trabalho e atalho para reiniciar no BIOS."

call "%~dp0_ui.bat" :confirmar
if errorlevel 1 call "%~dp0_ui.bat" :sair 0 & exit /b 0
set "EXIT_CODE=0"
title Criar atalhos (GodMode e BIOS)
set "GM=%USERPROFILE%\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"
if not exist "!GM!" mkdir "!GM!"
echo   Pasta GodMode criada na Area de Trabalho.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$d=[Environment]::GetFolderPath('Desktop');$s=(New-Object -ComObject WScript.Shell).CreateShortcut(\"$d\Reiniciar BIOS.lnk\");$s.TargetPath='shutdown.exe';$s.Arguments='/r /fw /t 0';$s.Save();Write-Host '   Atalho Reiniciar BIOS criado.'"

call "%~dp0_ui.bat" :sair %EXIT_CODE%
endlocal
exit /b %EXIT_CODE%
