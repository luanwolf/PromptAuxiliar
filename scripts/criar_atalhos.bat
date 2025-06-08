@echo off
title Criar Atalhos GodMode e BIOS
mode con: cols=100 lines=30
chcp 65001 >nul
setlocal enabledelayedexpansion

echo =================================================================
echo             CRIAR ATALHOS GODMODE E REINICIAR BIOS
echo =================================================================
echo.
echo Este script ira criar dois atalhos na sua area de trabalho:
echo  1. Pasta "GodMode" (para configuracoes avancadas do Windows)
echo  2. Atalho "Reiniciar BIOS" (para reiniciar o computador direto na BIOS/UEFI)
echo.
echo =================================================================
echo.
echo Pressione qualquer tecla para iniciar a criacao dos atalhos...
pause >nul
cls

echo.
echo [1/2] Criando a Pasta GodMode...
md "%USERPROFILE%\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" 2>nul
if exist "%USERPROFILE%\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" (
    echo Pasta GodMode criada com sucesso!
) else (
    echo Nao foi possivel criar a Pasta GodMode ou ja existe.
)
timeout /t 2 /nobreak >nul

echo.
echo [2/2] Criando o atalho "Reiniciar BIOS"...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$desktop = [Environment]::GetFolderPath('Desktop'); try { $s = (New-Object -ComObject WScript.Shell).CreateShortcut(\"$desktop\\Reiniciar BIOS.lnk\"); $s.TargetPath = 'shutdown.exe'; $s.Arguments = '/r /fw /t 0'; $s.IconLocation = \"$env:SystemRoot\\System32\\setupapi.dll,57\"; $s.Save(); Write-Host 'Atalho BIOS criado com sucesso!'; } catch { Write-Host 'Falha ao criar o atalho BIOS.'; }"
echo.
echo Processo de criacao do atalho BIOS concluido. Verifique a area de trabalho.
timeout /t 2 /nobreak >nul

echo.
echo =================================================================
echo                 TODOS OS ATALHOS FORAM CRIADOS!
echo =================================================================
echo.
echo Pressione qualquer tecla para sair.
pause >nul
exit