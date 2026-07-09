@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Ativar Windows (slmgr)
echo USE POR SUA CONTA E RISCO.
pause
cscript //nologo "%SystemRoot%\System32\slmgr.vbs" /ato
pause

endlocal
exit /b 0
