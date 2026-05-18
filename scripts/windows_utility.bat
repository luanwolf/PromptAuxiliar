@echo off
chcp 65001 >nul
title Windows Utility - Prompt Auxiliar
cls
echo ========================================
echo   CHRIS TITUS TECH - WINDOWS UTILITY
echo   Prompt Auxiliar
echo ========================================
echo.
echo AVISO: Executa script remoto (christitus.com/win).
echo.
set /p CONFIRMA="Digite S para continuar ou qualquer tecla para cancelar: "
if /i not "%CONFIRMA%"=="S" exit /b 0
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://christitus.com/win | iex"
echo.
pause
