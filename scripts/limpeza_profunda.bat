@echo off
chcp 65001 >nul
title Limpeza Profunda - Prompt Auxiliar
cls
echo ========================================
echo   LIMPEZA PROFUNDA DO SISTEMA
echo   Prompt Auxiliar
echo ========================================
echo.
echo [1/8] Removendo arquivos temporarios do usuario...
del /f /s /q "%TEMP%\*" 2>nul
for /d %%i in ("%TEMP%\*") do rd /s /q "%%i" 2>nul
echo Concluido.
pause
echo.
echo [2/8] Limpando Prefetch...
del /f /q "C:\Windows\Prefetch\*.*" 2>nul
echo Concluido.
pause
echo.
echo [3/8] Limpando cache DNS...
ipconfig /flushdns
echo Concluido.
pause
echo.
echo [4/8] Configurando perfil de limpeza de disco (sageset:1)...
cleanmgr /sageset:1
echo.
echo [5/8] Executando limpeza de disco (sagerun:1)...
cleanmgr /sagerun:1
echo Concluido.
pause
echo.
echo [6/8] Verificando integridade dos arquivos do sistema (SFC)...
sfc /scannow
echo Concluido.
pause
echo.
echo [7/8] Reparando imagem do Windows (DISM)...
DISM /Online /Cleanup-Image /RestoreHealth
echo Concluido.
pause
echo.
echo [8/8] Limpeza profunda finalizada.
pause
