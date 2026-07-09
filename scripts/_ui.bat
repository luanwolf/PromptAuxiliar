chcp 65001 >nul 2>&1
@echo off
setlocal DisableDelayedExpansion
rem Biblioteca de interface - não executar diretamente.
if /i "%~1"==":banner" goto :banner
if /i "%~1"==":confirmar" goto :confirmar
if /i "%~1"==":confirmar_perigo" goto :confirmar_perigo
if /i "%~1"==":sair" goto :sair
exit /b 0

:banner
cls
echo.
echo   ==============================================================
echo     %~2
echo     Prompt Auxiliar
echo   ==============================================================
echo.
echo   %~3
echo.
exit /b 0

:confirmar
call :_pergunta_sn
exit /b %ERRORLEVEL%

:confirmar_perigo
echo   ATENÇÃO: operação sensível - use por sua conta e risco.
echo.
call :_pergunta_sn
exit /b %ERRORLEVEL%

:_pergunta_sn
echo   Pressione S para continuar ou N para cancelar:
set "PA_SN="
set /p "PA_SN=  Opção: "
if /i "%PA_SN%"=="N" exit /b 1
if /i "%PA_SN%"=="S" exit /b 0
echo   Opção inválida. Use S ou N.
exit /b 1

:sair
set "_ec=%~1"
if not defined _ec set "_ec=0"
echo.
if not "%_ec%"=="0" (
  echo   Finalizado com código %_ec%.
) else (
  echo   Concluído.
)
echo.
echo   Pressione qualquer tecla para sair...
pause >nul
exit /b %_ec%
