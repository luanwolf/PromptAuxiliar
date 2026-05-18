@echo off
chcp 65001 >nul
title Alternar Menu de Contexto - Prompt Auxiliar
cls
echo ========================================
echo   ALTERNAR MENU DE CONTEXTO DO EXPLORADOR
echo   Prompt Auxiliar
echo ========================================
echo.
echo  1 - Menu de contexto classico (Windows 10)
echo  2 - Menu de contexto moderno (Windows 11)
echo  0 - Sair
echo.
set /p OPCAO="Escolha uma opcao: "
if "%OPCAO%"=="1" goto CLASSICO
if "%OPCAO%"=="2" goto MODERNO
if "%OPCAO%"=="0" exit /b 0
echo Opcao invalida.
pause
exit /b 1

:CLASSICO
echo Aplicando menu classico...
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
goto REINICIAR

:MODERNO
echo Aplicando menu moderno...
reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f 2>nul
goto REINICIAR

:REINICIAR
echo Reiniciando o Explorer...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
echo Concluido.
pause
