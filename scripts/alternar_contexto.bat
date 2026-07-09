@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Menu de Contexto
:MENU
cls
echo   1 - Menu classico (Windows 10)
echo   2 - Menu moderno (Windows 11)
echo   0 - Sair
echo.
set "OP="
set /p OP="Opcao: "
if "!OP!"=="1" goto CLASSICO
if "!OP!"=="2" goto MODERNO
if "!OP!"=="0" exit /b 0
echo Opcao invalida.
timeout /t 2 >nul
goto MENU

:CLASSICO
echo Aplicando menu classico...
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve >nul
goto RESTART

:MODERNO
echo Aplicando menu moderno...
reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1
goto RESTART

:RESTART
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe
echo Pronto.
pause
exit /b 0
