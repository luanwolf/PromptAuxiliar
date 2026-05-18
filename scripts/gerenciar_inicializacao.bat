@echo off
chcp 65001 >nul
title Gerenciar Inicializacao - Prompt Auxiliar
cls
echo ========================================
echo   GERENCIAR PROGRAMAS NA INICIALIZACAO
echo   Prompt Auxiliar
echo ========================================
echo.
echo Abrindo Configuracoes do Windows (Aplicativos de inicializacao)...
start ms-settings:startupapps
echo.
pause
