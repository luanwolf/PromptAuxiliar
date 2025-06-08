@echo off
title Ferramenta de Reparo de Rede
mode con: cols=100 lines=30
chcp 65001 >nul
setlocal enabledelayedexpansion

cls
echo ======================================================
echo           FERRAMENTA DE REPARO DE REDE
echo ======================================================
echo.
echo Este script executara os seguintes comandos para tentar
echo resolver problemas de conectividade de rede:
echo.
echo  - Liberar e renovar o endereco IP
echo  - Limpar o cache DNS
echo  - Redefinir o Winsock
echo  - Redefinir as configuracoes de IP
echo.
echo Pressione qualquer tecla para iniciar o reparo...
pause >nul
cls

echo.
echo [1/5] Liberando e renovando o endereco IP...
ipconfig /release
ipconfig /renew
timeout /t 2 /nobreak >nul

echo.
echo [2/5] Limpando o cache DNS...
ipconfig /flushdns
timeout /t 2 /nobreak >nul

echo.
echo [3/5] Redefinindo o catalogo Winsock...
netsh winsock reset
timeout /t 2 /nobreak >nul

echo.
echo [4/5] Redefinindo as configuracoes de IP (TCP/IP)...
netsh int ip reset
timeout /t 2 /nobreak >nul

echo.
echo [5/5] Registrando o DNS novamente...
ipconfig /registerdns
timeout /t 2 /nobreak >nul

echo.
echo ======================================================
echo         REPARO DE REDE CONCLUIDO!
echo ======================================================
echo.
echo Se o problema persistir, pode ser necessario reiniciar
echo o computador. Alguns dos comandos podem exigir reinicio.
echo.
pause
exit