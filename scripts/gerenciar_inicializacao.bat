@echo off
title Abrir Gerenciador de Inicializacao
mode con: cols=100 lines=30
chcp 65001 >nul
setlocal enabledelayedexpansion

cls
echo ======================================================
echo         ABRIR GERENCIADOR DE INICIALIZACAO
echo ======================================================
echo.
start ms-settings:startupapps
echo.
echo Gerenciador aberto com sucesso!
pause
exit