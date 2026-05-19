@echo off
setlocal EnableExtensions EnableDelayedExpansion
call "%~dp0_ui.bat" :banner "Reparar conexao de rede" "Libera e renova o IP, limpa o cache DNS, redefine Winsock e a pilha TCP/IP."

call "%~dp0_ui.bat" :confirmar
if errorlevel 1 call "%~dp0_ui.bat" :sair 0 & exit /b 0
set "EXIT_CODE=0"
title Reparar conexao de rede
echo   [1/6] Liberando IP...
ipconfig /release >nul 2>&1
echo   [2/6] Renovando IP...
ipconfig /renew
echo   [3/6] Limpando cache DNS...
ipconfig /flushdns
echo   [4/6] Redefinindo Winsock...
netsh winsock reset
echo   [5/6] Redefinindo TCP/IP...
netsh int ip reset
echo   [6/6] Registrando DNS...
ipconfig /registerdns
echo.
echo   Reinicie o PC se o problema continuar.

call "%~dp0_ui.bat" :sair %EXIT_CODE%
endlocal
exit /b %EXIT_CODE%
