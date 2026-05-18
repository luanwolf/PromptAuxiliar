@echo off
chcp 65001 >nul
title Criar Atalhos - Prompt Auxiliar
cls
echo ========================================
echo   CRIAR ATALHOS UTEIS
echo   Prompt Auxiliar
echo ========================================
echo.
set "DESKTOP=%USERPROFILE%\Desktop"
echo [1/2] Criando pasta GodMode na Area de Trabalho...
if not exist "%DESKTOP%\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" (
    mkdir "%DESKTOP%\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"
    echo Pasta GodMode criada.
) else (
    echo Pasta GodMode ja existe.
)
echo.
echo [2/2] Criando atalho para reiniciar e entrar na BIOS/UEFI...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s = (New-Object -ComObject WScript.Shell).CreateShortcut('%DESKTOP%\Reiniciar para BIOS.lnk'); $s.TargetPath = 'powershell.exe'; $s.Arguments = '-NoProfile -ExecutionPolicy Bypass -Command \"shutdown /r /fw /t 0\"'; $s.WorkingDirectory = '%USERPROFILE%'; $s.Description = 'Reinicia o PC diretamente na firmware (BIOS/UEFI)'; $s.Save()"
echo Atalho criado: Reiniciar para BIOS.lnk
echo.
pause
