chcp 65001 >nul 2>&1
@echo off
setlocal EnableExtensions EnableDelayedExpansion
call "%~dp0_ui.bat" :banner "Aplicar ajustes de registro" "Importa todos os arquivos .reg da pasta C:\PromptAuxiliar\registros."

call "%~dp0_ui.bat" :confirmar_perigo
if errorlevel 1 call "%~dp0_ui.bat" :sair 0 & exit /b 0
set "EXIT_CODE=0"
title Aplicar ajustes de registro
set "REG_FOLDER=C:\PromptAuxiliar\registros"
if not exist "!REG_FOLDER!" mkdir "!REG_FOLDER!"
set "COUNT=0"
pushd "!REG_FOLDER!" 2>nul
if errorlevel 1 (
  echo   Pasta não encontrada: !REG_FOLDER!
  set "EXIT_CODE=1"
  goto :fim_reg
)
for %%f in (*.reg) do (
  echo   Aplicando: %%~nxf
  reg import "%%f"
  if !ERRORLEVEL! equ 0 set /a COUNT+=1
)
popd
:fim_reg
if !COUNT! equ 0 (
  echo   Nenhum .reg encontrado. Abrindo pasta...
  start "" "!REG_FOLDER!"
) else (
  echo   Total aplicados: !COUNT!
)

call "%~dp0_ui.bat" :sair %EXIT_CODE%
endlocal
exit /b %EXIT_CODE%
