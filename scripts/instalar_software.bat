@echo off
title Instalador Local - EXE / MSI / LNK - Prompt Auxiliar
mode con: cols=70 lines=20
chcp 65001 >nul
setlocal enabledelayedexpansion

set "PASTA=C:\PromptAuxiliar\softwares"
set "CONTADOR=0"

echo =========================================================
echo         INSTALADOR DE PROGRAMAS .EXE / .MSI / .LNK
echo =========================================================
echo.
echo Este script ira executar arquivos .exe, .msi e .lnk encontrados na
echo pasta "C:\PromptAuxiliar\softwares".
echo.
echo.
echo.
echo Verificando a pasta:
echo !PASTA!
echo.

if not exist "!PASTA!" (
    echo Pasta de instaladores nao encontrada!
    timeout /t 5 >nul
    exit /b
)

pushd "!PASTA!"

:: Verifica se ha arquivos a serem instalados
for %%f in (*.exe *.msi *.lnk) do (
    set /a CONTADOR+=1
)

if !CONTADOR! EQU 0 (
    echo Nenhum arquivo .exe, .msi ou .lnk encontrado na pasta.
    echo.
    echo Abrindo a pasta para que voce possa adicionar os programas.
    timeout /t 3 >nul
    start "" "!PASTA!"
    popd
    exit
)

:: Instalar cada arquivo encontrado
for %%f in (*.exe *.msi *.lnk) do (
    echo Executando: %%f
    start /wait "" "%%f"
    echo.
)

echo Instalacoes finalizadas.
pause
exit