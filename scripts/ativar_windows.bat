@echo off
title Ativar Windows (slmgr)
mode con: cols=100 lines=30
chcp 65001 >nul
setlocal enabledelayedexpansion

echo =================================================================
echo                 ATIVAR WINDOWS (SLMGR /ATO)
echo =================================================================
echo.
echo Este script ira tentar ativar sua copia do Windows online
echo usando o comando "slmgr /ato".
echo.
echo =================================================================
echo.
echo Pressione qualquer tecla para tentar ativar o Windows...
pause >nul

cls
echo.
echo Executando slmgr /ato...
slmgr /ato

cls
echo.
echo =================================================================
echo         PROCESSO DE ATIVACAO CONCLUIDO!
echo =================================================================
echo.
echo Por favor, verifique o pop-up para o status da ativacao.
echo.
pause
exit