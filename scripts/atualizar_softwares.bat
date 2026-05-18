@echo off
chcp 65001 >nul
title Atualizar Softwares - Prompt Auxiliar
cls
echo ========================================
echo   ATUALIZAR SOFTWARES (WINGET)
echo   Prompt Auxiliar
echo ========================================
echo.
echo Atualizando todos os pacotes instalados. Aguarde...
winget upgrade --all --silent --accept-package-agreements --include-unknown
echo.
echo Processo finalizado.
pause
