@echo off
title Executar Script PowerShell - ChristTitus
mode con: cols=100 lines=30
chcp 65001 >nul
setlocal enabledelayedexpansion

cls
echo =================================================================
echo        EXECUTANDO SCRIPT DE OTIMIZACAO DO CHRIST TITUS
echo =================================================================
echo.
echo Este script abrira o PowerShell e executara o comando:
echo "irm -useb christitus.com/win | iex"
echo.
echo Pressione qualquer tecla para continuar...
pause >nul

cls
echo Abrindo PowerShell e executando o script...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm -useb https://christitus.com/win | iex"
echo.
echo O script PowerShell foi iniciado. Siga as instrucoes na janela do PowerShell.
echo.
echo. Finalizando CMD
timeout /t 5 >nul
exit