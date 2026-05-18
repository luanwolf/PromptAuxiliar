@echo off
chcp 65001 >nul
title Reparar Rede - Prompt Auxiliar
cls
echo ========================================
echo   REPARAR CONFIGURACOES DE REDE
echo   Prompt Auxiliar
echo ========================================
echo.
echo [1/6] Liberando endereco IP...
ipconfig /release
echo.
echo [2/6] Renovando endereco IP...
ipconfig /renew
echo.
echo [3/6] Limpando cache DNS...
ipconfig /flushdns
echo.
echo [4/6] Redefinindo Winsock...
netsh winsock reset
echo.
echo [5/6] Redefinindo pilha TCP/IP...
netsh int ip reset
echo.
echo [6/6] Registrando DNS...
ipconfig /registerdns
echo.
echo Concluido. Reinicie o computador para aplicar todas as alteracoes.
pause
