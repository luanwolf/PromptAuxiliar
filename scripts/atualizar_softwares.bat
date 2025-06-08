@echo off
title Atualizar Programas via Winget
mode con: cols=85 lines=20
chcp 65001 >nul
setlocal enabledelayedexpansion

cls
echo =================================================================
echo             ATUALIZAR PROGRAMAS VIA WINGET
echo =================================================================
echo.
echo Este script ira tentar atualizar todos os programas instalados
echo no seu sistema que sao gerenciados pelo Winget.
echo.
echo Isso pode levar alguns minutos, dependendo da quantidade de
echo atualizacoes disponiveis.
echo.
echo =================================================================
echo.
echo Pressione qualquer tecla para iniciar a atualizacao...
pause >nul

echo.
echo Iniciando a verificacao e atualizacao de programas com Winget...
echo.

winget upgrade --all --silent --accept-package-agreements

echo.
echo =================================================================
echo         ATUALIZACAO DE PROGRAMAS CONCLUIDA!
echo =================================================================
echo.
echo Por favor, verifique a saida do Winget acima para detalhes.
echo.
pause
exit