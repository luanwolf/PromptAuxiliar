@echo off
chcp 65001 >nul
title Ativar Windows KMS - Prompt Auxiliar
cls
echo ========================================
echo   ATIVACAO WINDOWS (SCRIPT EXTERNO)
echo   Prompt Auxiliar
echo ========================================
echo.
echo AVISO: Este script executa codigo baixado da Internet.
echo Use apenas se confiar na origem e entender os riscos.
echo Origem: get.activated.win
echo.
set /p CONFIRMA="Digite S para continuar ou qualquer tecla para cancelar: "
if /i not "%CONFIRMA%"=="S" exit /b 0
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://get.activated.win | iex"
echo.
pause
