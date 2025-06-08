@echo off
title Alternar Menu de Contexto - Windows 10 / Windows 11
mode con: cols=100 lines=30
chcp 65001 >nul
setlocal enabledelayedexpansion

:MENU
cls
echo ======================================================
echo        ALTERAR MENU DE CONTEXTO DO WINDOWS 11
echo ======================================================
echo.
echo  [1] Usar menu de contexto do Windows 10 (classico)
echo  [2] Usar menu de contexto do Windows 11 (moderno)
echo  [0] Sair
echo.
set /p opcao=Escolha uma opcao e pressione Enter: 
cls

if "%opcao%"=="1" goto CLASSICO
if "%opcao%"=="2" goto MODERNO
if "%opcao%"=="0" exit
goto MENU

:CLASSICO
cls
echo.
echo Ativando menu de contexto estilo Windows 10...
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
timeout /t 1 /nobreak >nul
goto REINICIAR_EXPLORER

:MODERNO
cls
echo.
echo Restaurando menu de contexto moderno do Windows 11...
reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1
timeout /t 1 /nobreak >nul
goto REINICIAR_EXPLORER

:REINICIAR_EXPLORER
cls
echo.
echo Reiniciando o Windows Explorer para aplicar a mudanca...
taskkill /f /im explorer.exe >nul
timeout /t 2 /nobreak >nul
start explorer.exe
echo.
echo Alteracao aplicada com sucesso!
pause
exit