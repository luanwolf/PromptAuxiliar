@echo off
chcp 65001 >nul
title Instalar Software - Prompt Auxiliar
cls
echo ========================================
echo   INSTALAR SOFTWARES
echo   Prompt Auxiliar
echo ========================================
echo.
set "PASTA=C:\PromptAuxiliar\softwares"
if not exist "%PASTA%" (
    echo Pasta nao encontrada: %PASTA%
    pause
    exit /b 1
)
echo Instalando executaveis (.exe)...
for %%F in ("%PASTA%\*.exe") do (
    echo Executando: %%~nxF
    start /wait "" "%%F"
)
echo.
echo Instalando pacotes MSI (.msi)...
for %%F in ("%PASTA%\*.msi") do (
    echo Executando: %%~nxF
    start /wait msiexec /i "%%F"
)
echo.
echo Abrindo atalhos (.lnk)...
for %%F in ("%PASTA%\*.lnk") do (
    echo Abrindo: %%~nxF
    start /wait "" "%%F"
)
echo.
echo Processo concluido.
pause
