@echo off
title Aplicar Arquivos .REG
mode con: cols=100 lines=30
chcp 65001 >nul
setlocal enabledelayedexpansion

cls
echo =================================================================
echo           APLICAR ARQUIVOS .REG DO REGISTRO
echo =================================================================
echo.
echo Este script ira aplicar todos os arquivos .reg encontrados na
echo pasta "C:\PromptAuxiliar\registros".
echo.
echo =================================================================
echo.
echo Pressione qualquer tecla para iniciar a aplicacao dos arquivos .reg...
pause >nul
cls

set "REG_FOLDER=C:\PromptAuxiliar\registros"

if not exist "!REG_FOLDER!" (
    cls
    echo.
    echo ERRO CRITICO: A pasta "!REG_FOLDER!" nao foi encontrada.
    echo Por favor, crie esta pasta e coloque seus arquivos .reg nela.
    echo Certifique-se de que o caminho esta correto.
    echo.
    pause
    exit /b
)

cls
echo.
echo Iniciando aplicacao dos arquivos .reg...
echo.

set "REG_COUNT=0"
set "FILE_FOUND=0"
for %%f in ("!REG_FOLDER!\*.reg") do (
    set "FILE_FOUND=1"
    echo Aplicando: "%%f"
    reg import "%%f"
    if !ERRORLEVEL! equ 0 (
        cls
        echo Aplicado com sucesso.
        set /a REG_COUNT+=1
    ) else (
        cls
        echo FALHA ao aplicar. Verifique o arquivo .reg para erros.
    )
    REM Pausa para permitir que voce veja a saida de cada arquivo
    timeout /t 3 /nobreak >nul
    echo.
)

if !FILE_FOUND! equ 0 (
    cls
    echo.
    echo Nenhum arquivo .reg encontrado na pasta "!REG_FOLDER!".
    echo Abrindo a pasta para que voce possa adicionar os arquivos .reg.
    timeout /t 3 >nul
    start "" "!REG_FOLDER!"
    exit
)

cls
echo.
echo =================================================================
echo           APLICACAO DE ARQUIVOS .REG CONCLUIDA!
echo =================================================================
echo.
echo Total de arquivos .reg processados com sucesso: !REG_COUNT!
echo.
echo Pressione qualquer tecla para sair.
pause >nul
exit