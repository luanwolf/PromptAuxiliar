@echo off
chcp 65001 >nul
title Ativar Windows - Prompt Auxiliar
cls
echo ========================================
echo   ATIVAR WINDOWS (slmgr /ato)
echo   Prompt Auxiliar
echo ========================================
echo.
echo Tentando ativar o Windows com a chave instalada...
cscript //nologo "%SystemRoot%\System32\slmgr.vbs" /ato
echo.
pause
