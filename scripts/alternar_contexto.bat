chcp 65001 >nul 2>&1
@echo off
setlocal EnableExtensions EnableDelayedExpansion
call "%~dp0_ui.bat" :banner "Alternar menu de contexto" "Escolha menu clássico (estilo Windows 10) ou moderno (Windows 11). O Explorer será reiniciado."
call "%~dp0_ui.bat" :confirmar
if errorlevel 1 call "%~dp0_ui.bat" :sair 0 & exit /b 0
set "EXIT_CODE=0"
title Alternar menu de contexto

:MENU
cls
echo.
echo   ==============================================================
echo     Alternar menu de contexto
echo     Prompt Auxiliar
echo   ==============================================================
echo.
echo     1  Menu clássico (Windows 10)
echo     2  Menu moderno (Windows 11)
echo     0  Sair
echo.
set "OP="
set /p "OP=  Opção: "
if "!OP!"=="1" goto CLASSICO
if "!OP!"=="2" goto MODERNO
if "!OP!"=="0" call "%~dp0_ui.bat" :sair 0 & exit /b 0
echo   Opção inválida.
timeout /t 2 >nul
goto MENU

:CLASSICO
echo.
echo   Aplicando menu clássico...
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve >nul
goto RESTART

:MODERNO
echo.
echo   Aplicando menu moderno...
reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1
goto RESTART

:RESTART
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe
echo   Explorer reiniciado.

call "%~dp0_ui.bat" :sair %EXIT_CODE%
endlocal
exit /b %EXIT_CODE%
