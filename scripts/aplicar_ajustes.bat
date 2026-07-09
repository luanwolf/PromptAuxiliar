@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Aplicar .REG
set "REG_FOLDER=C:\PromptAuxiliar\registros"
if not exist "!REG_FOLDER!" mkdir "!REG_FOLDER!"
set COUNT=0
pushd "!REG_FOLDER!" 2>nul
if errorlevel 1 (
  echo Pasta nao encontrada.
  pause
  exit /b 1
)
for %%f in (*.reg) do (
  echo Aplicando: %%~nxf
  reg import "%%f"
  if !ERRORLEVEL! equ 0 set /a COUNT+=1
)
popd
if !COUNT! equ 0 (
  echo Nenhum .reg encontrado. Abrindo pasta...
  start "" "!REG_FOLDER!"
) else (
  echo Total aplicados: !COUNT!
)
pause

endlocal
exit /b 0
