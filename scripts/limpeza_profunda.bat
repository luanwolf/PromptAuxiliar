@echo off
title Limpeza Profunda do Windows
mode con: cols=85 lines=35
chcp 65001 >nul
setlocal enabledelayedexpansion

echo =================================================================
echo                 FERRAMENTA DE LIMPEZA PROFUNDA
echo =================================================================
echo.
echo Este script executara uma serie de comandos para realizar uma
echo limpeza profunda no seu sistema, incluindo:
echo.
echo  - Limpeza de arquivos temporarios de usuario e sistema.
echo  - Limpeza do cache de prefetch.
echo  - Limpeza do cache DNS.
echo  - Execucao da Ferramenta de Limpeza de Disco (Disk Cleanup).
echo  - Verificacao e reparo de arquivos do sistema (SFC).
echo  - Verificacao e reparo da imagem do sistema (DISM).
echo.
echo Este processo pode levar tempo e alguns comandos podem
echo requerer a sua interacao ou reinicio do sistema.
echo.
echo =================================================================
echo.
echo Pressione qualquer tecla para iniciar a limpeza profunda...
pause >nul

echo.
echo [1/6] Limpando arquivos temporarios de usuario e sistema...
del /q /f /s "%TEMP%\*" >nul 2>&1
del /q /f /s "%TMP%\*" >nul 2>&1
del /q /f /s "C:\Windows\Temp\*" >nul 2>&1
echo Concluido.
timeout /t 2 /nobreak >nul

echo.
echo [2/6] Limpando o cache de prefetch...
REM Para evitar erros, exclui apenas se o diretorio existe e eh acessivel
if exist "C:\Windows\Prefetch" (
    del /q /f /s "C:\Windows\Prefetch\*" >nul 2>&1
    echo Concluido.
) else (
    echo Pasta Prefetch nao encontrada ou inacessivel. Ignorando.
)
timeout /t 2 /nobreak >nul

echo.
echo [3/6] Limpando o cache DNS...
ipconfig /flushdns
echo Concluido.
timeout /t 2 /nobreak >nul

echo.
echo [4/6] Executando a Ferramenta de Limpeza de Disco (Disk Cleanup)...
echo Isso pode levar alguns minutos e pode requerer interacao.
REM Configura o Disk Cleanup para incluir todas as opcoes de limpeza
cleanmgr /sageset:65535
REM Executa o Disk Cleanup com as opcoes configuradas
cleanmgr /sagerun:65535
echo Concluido.
timeout /t 5 /nobreak >nul

echo.
echo [5/6] Executando verificacao e reparo de arquivos do sistema (SFC)...
echo Este processo pode demorar. Nao feche a janela.
sfc /scannow
echo Concluido.
timeout /t 5 /nobreak >nul

echo.
echo [6/6] Executando verificacao e reparo da imagem do sistema (DISM)...
echo Este processo pode demorar. Nao feche a janela.
Dism /online /cleanup-image /restorehealth
echo Concluido.
timeout /t 5 /nobreak >nul

echo.
echo =================================================================
echo            LIMPEZA PROFUNDA CONCLUIDA!
echo =================================================================
echo.
echo Recomenda-se reiniciar o computador para que todas as alteracoes
echo tenham efeito completo.
echo.
pause
exit