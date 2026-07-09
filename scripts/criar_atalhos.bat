@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Criar Atalhos
set "GM=%USERPROFILE%\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"
if not exist "!GM!" mkdir "!GM!"
echo Pasta GodMode criada.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$d=[Environment]::GetFolderPath('Desktop');$s=(New-Object -ComObject WScript.Shell).CreateShortcut(\"$d\Reiniciar BIOS.lnk\");$s.TargetPath='shutdown.exe';$s.Arguments='/r /fw /t 0';$s.Save();Write-Host 'Atalho BIOS criado.'"
pause

endlocal
exit /b 0
