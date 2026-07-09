@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Instalar Software
set "PASTA=C:\PromptAuxiliar\softwares"
if not exist "!PASTA!" mkdir "!PASTA!"
set COUNT=0
for %%f in ("!PASTA!\*.exe" "!PASTA!\*.msi" "!PASTA!\*.lnk") do set /a COUNT+=1
if !COUNT! equ 0 (
  echo Nenhum instalador. Abrindo pasta...
  start "" "!PASTA!"
  exit /b 0
)
for %%f in ("!PASTA!\*.exe" "!PASTA!\*.msi" "!PASTA!\*.lnk") do (
  echo Executando: %%~nxf
  start /wait "" "%%f"
)
echo Concluido.
pause

endlocal
exit /b 0
