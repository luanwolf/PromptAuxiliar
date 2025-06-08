@echo off
title Instalador Winget - Prompt Auxiliar
mode con: cols=70 lines=15
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ======================================================
echo           INSTALADOR DE PROGRAMAS VIA WINGET
echo ======================================================
echo.
echo Este script vai instalar todos os programas via winget definidos no
echo arquivo "C:\PromptAuxiliar\winget.txt".
echo.
echo Voce deve incluir os codigos winget no '.txt' da seguinte forma: Valve.Steam
echo para localizar estes codigos, baste procurar no google "Winget XXX programa"
echo e informar o ID.
echo.
echo IMPORTANTE - O APP ignora todas as linhas que se iniciam com '#'.
echo.
echo =================================================================
echo.
echo Pressione qualquer tecla para iniciar a aplicacao dos arquivos .reg...
pause >nul

set "ARQUIVO=C:\PromptAuxiliar\winget.txt"

if not exist "!ARQUIVO!" (
    echo Arquivo !ARQUIVO! nao encontrado.
    pause
    exit /b
)

echo Iniciando instalacao dos programas listados...
echo (linhas com # serao ignoradas)
echo.

for /f "usebackq delims=" %%i in ("!ARQUIVO!") do (
    set "linha=%%i"
    if not "!linha!"=="" (
        echo !linha! | findstr /b /c:"#">nul
        if errorlevel 1 (
            echo Instalando: !linha!
            winget install --id=!linha! --accept-source-agreements --accept-package-agreements -h
            echo.
        ) else (
            echo Ignorado: !linha!
        )
    )
)

echo.
echo Todas as instalacoes foram processadas.
pause
exit