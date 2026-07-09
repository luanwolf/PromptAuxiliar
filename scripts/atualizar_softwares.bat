@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Atualizar via Winget
echo Atualizando pacotes (pode demorar)...
winget upgrade --all --silent --accept-package-agreements --include-unknown
echo.
pause

endlocal
exit /b 0
