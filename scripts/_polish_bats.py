"""Regenera .bat com estilo uniforme (UTF-8 sem BOM). Executar: python scripts/_polish_bats.py"""
from __future__ import annotations

from pathlib import Path

HEADER = r"""@echo off
setlocal EnableExtensions EnableDelayedExpansion
"""

FOOTER = r"""
endlocal
exit /b 0
"""

SCRIPTS: dict[str, str] = {
    "reparar_rede.bat": r"""
title Reparar Rede
echo [1/6] Liberando IP...
ipconfig /release >nul 2>&1
echo [2/6] Renovando IP...
ipconfig /renew
echo [3/6] Limpando DNS...
ipconfig /flushdns
echo [4/6] Redefinindo Winsock...
netsh winsock reset
echo [5/6] Redefinindo TCP/IP...
netsh int ip reset
echo [6/6] Registrando DNS...
ipconfig /registerdns
echo.
echo Reinicie o PC se o problema continuar.
pause
""",
    "gerenciar_inicializacao.bat": r"""
title Apps de Inicializacao
echo Abrindo configuracoes...
start ms-settings:startupapps
timeout /t 2 >nul
""",
    "atualizar_softwares.bat": r"""
title Atualizar via Winget
echo Atualizando pacotes (pode demorar)...
winget upgrade --all --silent --accept-package-agreements --include-unknown
echo.
pause
""",
    "limpeza_disco.bat": r"""
title Limpeza de Disco
echo Abrindo cleanmgr...
start "" "%SystemRoot%\System32\cleanmgr.exe"
timeout /t 2 >nul
""",
    "limpeza_malware.bat": r"""
title MRT
echo Abrindo Ferramenta de Remocao de Malware...
start "" "%SystemRoot%\System32\MRT.exe"
timeout /t 2 >nul
""",
    "limpeza_temporarios.bat": r"""
title Limpeza de Temporarios
if exist "%~dp0limpeza_temporarios.ps1" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0limpeza_temporarios.ps1"
) else (
  echo Limpando...
  del /q /f /s "%TEMP%\*" >nul 2>&1
  echo Concluido.
  pause
)
""",
    "limpeza_profunda.bat": r"""
title Limpeza Profunda
echo [1/6] TEMP...
del /q /f /s "%TEMP%\*" >nul 2>&1
del /q /f /s "%SystemRoot%\Temp\*" >nul 2>&1
echo [2/6] Prefetch...
del /q /f /s "%SystemRoot%\Prefetch\*" >nul 2>&1
echo [3/6] DNS...
ipconfig /flushdns
echo [4/6] Limpeza de disco...
cleanmgr /sageset:1 >nul 2>&1
cleanmgr /sagerun:1
echo [5/6] SFC (demora)...
sfc /scannow
echo [6/6] DISM...
Dism /online /cleanup-image /restorehealth
echo.
pause
""",
    "aplicar_ajustes.bat": r"""
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
""",
    "instalar_software.bat": r"""
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
""",
    "criar_atalhos.bat": r"""
title Criar Atalhos
set "GM=%USERPROFILE%\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"
if not exist "!GM!" mkdir "!GM!"
echo Pasta GodMode criada.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$d=[Environment]::GetFolderPath('Desktop');$s=(New-Object -ComObject WScript.Shell).CreateShortcut(\"$d\Reiniciar BIOS.lnk\");$s.TargetPath='shutdown.exe';$s.Arguments='/r /fw /t 0';$s.Save();Write-Host 'Atalho BIOS criado.'"
pause
""",
    "alternar_contexto.bat": r"""
title Menu de Contexto
:MENU
cls
echo   1 - Menu classico (Windows 10)
echo   2 - Menu moderno (Windows 11)
echo   0 - Sair
echo.
set "OP="
set /p OP="Opcao: "
if "!OP!"=="1" goto CLASSICO
if "!OP!"=="2" goto MODERNO
if "!OP!"=="0" exit /b 0
echo Opcao invalida.
timeout /t 2 >nul
goto MENU

:CLASSICO
echo Aplicando menu classico...
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve >nul
goto RESTART

:MODERNO
echo Aplicando menu moderno...
reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1
goto RESTART

:RESTART
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe
echo Pronto.
pause
exit /b 0
""",
    "ativar_windows.bat": r"""
title Ativar Windows (slmgr)
echo USE POR SUA CONTA E RISCO.
pause
cscript //nologo "%SystemRoot%\System32\slmgr.vbs" /ato
pause
""",
    "ativar_windows_kms.bat": r"""
title KMS Windows
echo USE POR SUA CONTA E RISCO. Tecle S para continuar ou outra tecla para cancelar.
pause
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://get.activated.win/ | iex"
""",
    "ativar_office_kms.bat": r"""
title KMS Office
echo USE POR SUA CONTA E RISCO. Tecle S para continuar ou outra tecla para cancelar.
pause
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://get.activated.win/ | iex"
""",
    "windows_utility.bat": r"""
title WinUtil
echo Script de terceiros. USE POR SUA CONTA E RISCO.
pause
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm -useb https://christitus.com/win | iex"
""",
}


def main() -> None:
    folder = Path(__file__).parent
    for name, body in SCRIPTS.items():
        text = HEADER + body.strip() + "\n"
        if name != "alternar_contexto.bat":
            text += FOOTER
        path = folder / name
        path.write_text(text, encoding="utf-8", newline="\r\n")
        print("OK", name)


if __name__ == "__main__":
    main()
