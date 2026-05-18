@echo off
chcp 65001 >nul
title Limpeza de Temporarios - Prompt Auxiliar
cls
echo ========================================
echo   LIMPEZA DE ARQUIVOS TEMPORARIOS
echo   Prompt Auxiliar
echo ========================================
echo.
set "SCRIPT=%~dp0limpeza_temporarios.ps1"
if exist "%SCRIPT%" (
    echo Executando script PowerShell...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
) else (
    echo Script PS1 nao encontrado. Executando limpeza basica...
    del /f /s /q "%TEMP%\*" 2>nul
    for /d %%i in ("%TEMP%\*") do rd /s /q "%%i" 2>nul
    del /f /s /q "C:\Windows\Temp\*" 2>nul
    for /d %%i in ("C:\Windows\Temp\*") do rd /s /q "%%i" 2>nul
    ipconfig /flushdns >nul
    echo Limpeza basica concluida.
    pause
)
