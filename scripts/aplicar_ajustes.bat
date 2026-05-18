@echo off
chcp 65001 >nul
title Aplicar Ajustes - Prompt Auxiliar
cls
echo ========================================
echo   APLICAR AJUSTES DE REGISTRO (.REG)
echo   Prompt Auxiliar
echo ========================================
echo.
set "PASTA=C:\PromptAuxiliar\registros"
if not exist "%PASTA%" (
    echo Pasta nao encontrada: %PASTA%
    pause
    exit /b 1
)
echo Importando arquivos de %PASTA% ...
for %%F in ("%PASTA%\*.reg") do (
    echo Importando: %%~nxF
    reg import "%%F"
    if errorlevel 1 (
        echo   AVISO: Falha ao importar %%~nxF
    ) else (
        echo   OK.
    )
)
echo.
echo Processo concluido.
pause
