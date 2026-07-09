chcp 65001 >nul 2>&1
@echo off
setlocal EnableExtensions EnableDelayedExpansion
call "%~dp0_ui.bat" :banner "Instalar da pasta Software" "Executa instaladores .exe, .msi e atalhos .lnk de C:\PromptAuxiliar\softwares."

call "%~dp0_ui.bat" :confirmar
if errorlevel 1 call "%~dp0_ui.bat" :sair 0 & exit /b 0
set "EXIT_CODE=0"
title Instalar da pasta Software
set "PASTA=C:\PromptAuxiliar\softwares"
if not exist "!PASTA!" mkdir "!PASTA!"
set "COUNT=0"
for %%f in ("!PASTA!\*.exe" "!PASTA!\*.msi" "!PASTA!\*.lnk") do set /a COUNT+=1
if !COUNT! equ 0 (
  echo   Nenhum instalador encontrado. Abrindo pasta...
  start "" "!PASTA!"
  goto :fim_inst
)
for %%f in ("!PASTA!\*.exe" "!PASTA!\*.msi" "!PASTA!\*.lnk") do (
  echo   Executando: %%~nxf
  start /wait "" "%%f"
)
:fim_inst

call "%~dp0_ui.bat" :sair %EXIT_CODE%
endlocal
exit /b %EXIT_CODE%
