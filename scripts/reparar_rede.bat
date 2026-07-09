@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Reparar Rede
echo [1/6] Liberando IP...
ipconfig /release >nul 2>&1
echo [2/6] Renovando IP...
ipconfig /renew
echo [3/6] Limpando DNS...
ipconfig /flushdns
echo [4/6] Redefinindo Winsock...
netsh winsock reset
echo [5/6] Redefinindo TCP/IP...
netsh int ip reset
echo [6/6] Registrando DNS...
ipconfig /registerdns
echo.
echo Reinicie o PC se o problema continuar.
pause

endlocal
exit /b 0
