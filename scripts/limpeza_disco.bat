@echo off
setlocal EnableExtensions EnableDelayedExpansion
call "%~dp0_ui.bat" :banner "Limpeza de armazenamento" "Abre a ferramenta Limpeza de Disco do Windows (cleanmgr)."

call "%~dp0_ui.bat" :confirmar
if errorlevel 1 call "%~dp0_ui.bat" :sair 0 & exit /b 0
set "EXIT_CODE=0"
title Limpeza de armazenamento
echo   Abrindo Limpeza de Disco...
start "" "%SystemRoot%\System32\cleanmgr.exe"
echo   Selecione os itens a remover na janela aberta.

call "%~dp0_ui.bat" :sair %EXIT_CODE%
endlocal
exit /b %EXIT_CODE%
