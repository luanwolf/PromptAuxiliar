"""Regenera .bat com estilo uniforme (UTF-8 sem BOM). Executar: python scripts/_polish_bats.py"""
from __future__ import annotations

from pathlib import Path

HEADER = r"""@echo off
setlocal EnableExtensions EnableDelayedExpansion
"""

FOOTER = r"""
call "%~dp0_ui.bat" :sair %EXIT_CODE%
endlocal
exit /b %EXIT_CODE%
"""

CANCEL = r"""
call "%~dp0_ui.bat" :confirmar
if errorlevel 1 call "%~dp0_ui.bat" :sair 0 & exit /b 0
set "EXIT_CODE=0"
"""

CANCEL_PERIGO = r"""
call "%~dp0_ui.bat" :confirmar_perigo
if errorlevel 1 call "%~dp0_ui.bat" :sair 0 & exit /b 0
set "EXIT_CODE=0"
"""


def admin_ps_corpo(comando_ps: str, titulo_janela: str) -> str:
    """Gera .bat que eleva PowerShell e executa irm | iex (uso manual)."""
    cmd = comando_ps.replace("|", "^|")
    return rf"""
set "PA_PS=%TEMP%\pa_{titulo_janela}.ps1"
(
  echo $Host.UI.RawUI.WindowTitle = '{titulo_janela} ^| Prompt Auxiliar'
  echo {cmd}
)>"!PA_PS!"
echo   Abrindo PowerShell como administrador...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-NoExit','-File','!PA_PS!'"
"""


def script(
    nome: str,
    titulo: str,
    descricao: str,
    corpo: str,
    *,
    perigo: bool = False,
    sem_footer: bool = False,
) -> str:
    confirm = CANCEL_PERIGO if perigo else CANCEL
    intro = (
        f'call "%~dp0_ui.bat" :banner "{titulo}" "{descricao}"\n'
        + confirm
        + f"title {titulo}\n"
    )
    text = HEADER + intro + corpo.strip() + "\n"
    if not sem_footer:
        text += FOOTER
    return text


SCRIPTS: dict[str, str] = {
    "reparar_rede.bat": script(
        "reparar_rede",
        "Reparar conexao de rede",
        "Libera e renova o IP, limpa o cache DNS, redefine Winsock e a pilha TCP/IP.",
        r"""
echo   [1/6] Liberando IP...
ipconfig /release >nul 2>&1
echo   [2/6] Renovando IP...
ipconfig /renew
echo   [3/6] Limpando cache DNS...
ipconfig /flushdns
echo   [4/6] Redefinindo Winsock...
netsh winsock reset
echo   [5/6] Redefinindo TCP/IP...
netsh int ip reset
echo   [6/6] Registrando DNS...
ipconfig /registerdns
echo.
echo   Reinicie o PC se o problema continuar.
""",
    ),
    "gerenciar_inicializacao.bat": script(
        "gerenciar_inicializacao",
        "Apps de inicializacao",
        "Abre as Configuracoes do Windows para gerenciar programas que iniciam com o sistema.",
        r"""
echo   Abrindo Configuracoes...
start ms-settings:startupapps
echo   Janela aberta. Ajuste os apps desejados.
""",
    ),
    "atualizar_softwares.bat": script(
        "atualizar_softwares",
        "Atualizar programas",
        "Atualiza pacotes instalados via Winget (pode demorar varios minutos).",
        r"""
echo   Iniciando winget upgrade --all ...
winget upgrade --all --silent --accept-package-agreements --include-unknown
if errorlevel 1 set "EXIT_CODE=1"
""",
    ),
    "limpeza_disco.bat": script(
        "limpeza_disco",
        "Limpeza de armazenamento",
        "Abre a ferramenta Limpeza de Disco do Windows (cleanmgr).",
        r"""
echo   Abrindo Limpeza de Disco...
start "" "%SystemRoot%\System32\cleanmgr.exe"
echo   Selecione os itens a remover na janela aberta.
""",
    ),
    "limpeza_malware.bat": script(
        "limpeza_malware",
        "Limpeza MRT (malware)",
        "Abre a Ferramenta de Remocao de Malware do Windows (MRT.exe).",
        r"""
echo   Abrindo MRT...
start "" "%SystemRoot%\System32\MRT.exe"
echo   Siga as instrucoes na janela da ferramenta.
""",
    ),
    "limpeza_temporarios.bat": script(
        "limpeza_temporarios",
        "Limpeza de temporarios",
        "Remove temporarios, esvazia a Lixeira e limpa cache das pastas Temp.",
        r"""
if exist "%~dp0limpeza_temporarios.ps1" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0limpeza_temporarios.ps1"
  if errorlevel 1 set "EXIT_CODE=1"
) else (
  echo   [1/1] Limpando TEMP da sessao...
  del /q /f /s "%TEMP%\*" >nul 2>&1
)
""",
    ),
    "limpeza_profunda.bat": script(
        "limpeza_profunda",
        "Limpeza profunda do Windows",
        "Limpa TEMP e Prefetch, flush DNS, cleanmgr, SFC e DISM - operacao longa.",
        r"""
echo   [1/6] Pastas TEMP...
del /q /f /s "%TEMP%\*" >nul 2>&1
del /q /f /s "%SystemRoot%\Temp\*" >nul 2>&1
echo   [2/6] Prefetch...
del /q /f /s "%SystemRoot%\Prefetch\*" >nul 2>&1
echo   [3/6] Cache DNS...
ipconfig /flushdns
echo   [4/6] Limpeza de disco (cleanmgr)...
cleanmgr /sageset:1 >nul 2>&1
cleanmgr /sagerun:1
echo   [5/6] Verificacao de arquivos do sistema (SFC)...
sfc /scannow
echo   [6/6] Reparo de imagem (DISM)...
Dism /online /cleanup-image /restorehealth
""",
    ),
    "aplicar_ajustes.bat": script(
        "aplicar_ajustes",
        "Aplicar ajustes de registro",
        "Importa todos os arquivos .reg da pasta C:\\PromptAuxiliar\\registros.",
        r"""
set "REG_FOLDER=C:\PromptAuxiliar\registros"
if not exist "!REG_FOLDER!" mkdir "!REG_FOLDER!"
set "COUNT=0"
pushd "!REG_FOLDER!" 2>nul
if errorlevel 1 (
  echo   Pasta nao encontrada: !REG_FOLDER!
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
""",
        perigo=True,
    ),
    "instalar_runtimes.bat": script(
        "instalar_runtimes",
        "Visual C++ Runtimes (All-in-One)",
        "Instala Visual C++ Redistributable AIO (abbodi1406) via Winget — pacotes 2005 a 2022.",
        r"""
echo   Instalando abbodi1406.vcredist ...
winget install --id abbodi1406.vcredist --accept-source-agreements --accept-package-agreements -h
if errorlevel 1 set "EXIT_CODE=1"
""",
    ),
    "instalar_software.bat": script(
        "instalar_software",
        "Instalar da pasta Software",
        "Executa instaladores .exe, .msi e atalhos .lnk de C:\\PromptAuxiliar\\softwares.",
        r"""
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
""",
    ),
    "criar_atalhos.bat": script(
        "criar_atalhos",
        "Criar atalhos (GodMode e BIOS)",
        "Cria a pasta GodMode na Area de Trabalho e atalho para reiniciar no BIOS.",
        r"""
set "GM=%USERPROFILE%\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"
if not exist "!GM!" mkdir "!GM!"
echo   Pasta GodMode criada na Area de Trabalho.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$d=[Environment]::GetFolderPath('Desktop');$s=(New-Object -ComObject WScript.Shell).CreateShortcut(\"$d\Reiniciar BIOS.lnk\");$s.TargetPath='shutdown.exe';$s.Arguments='/r /fw /t 0';$s.Save();Write-Host '   Atalho Reiniciar BIOS criado.'"
""",
    ),
    "ativar_windows.bat": script(
        "ativar_windows",
        "Ativar Windows (slmgr)",
        "Executa slmgr /ato para tentar ativacao online do Windows.",
        r"""
echo   Executando slmgr /ato ...
cscript //nologo "%SystemRoot%\System32\slmgr.vbs" /ato
if errorlevel 1 set "EXIT_CODE=1"
""",
        perigo=True,
    ),
    "ativar_windows_kms.bat": script(
        "ativar_windows_kms",
        "Ativar Windows (KMS)",
        "Executa irm https://get.activated.win | iex no PowerShell como administrador.",
        admin_ps_corpo("irm https://get.activated.win | iex", "KMS_Windows"),
        perigo=True,
    ),
    "ativar_office_kms.bat": script(
        "ativar_office_kms",
        "Ativar Office (KMS)",
        "Executa irm https://get.activated.win | iex no PowerShell como administrador.",
        admin_ps_corpo("irm https://get.activated.win | iex", "KMS_Office"),
        perigo=True,
    ),
    "windows_utility.bat": script(
        "windows_utility",
        "Utilitario Windows (WinUtil)",
        "Executa WinUtil (Chris Titus) no PowerShell como administrador.",
        admin_ps_corpo('irm "https://christitus.com/win" | iex', "WinUtil"),
        perigo=True,
    ),
}

ALTERNAR_CONTEXTO = (
    HEADER
    + r"""call "%~dp0_ui.bat" :banner "Alternar menu de contexto" "Escolha menu classico (estilo Windows 10) ou moderno (Windows 11). O Explorer sera reiniciado."
call "%~dp0_ui.bat" :confirmar
if errorlevel 1 call "%~dp0_ui.bat" :sair 0 & exit /b 0
set "EXIT_CODE=0"
title Alternar menu de contexto

:MENU
cls
echo.
echo   ==============================================================
echo     Alternar menu de contexto
echo     Prompt Auxiliar
echo   ==============================================================
echo.
echo     1  Menu classico (Windows 10)
echo     2  Menu moderno (Windows 11)
echo     0  Sair
echo.
set "OP="
set /p "OP=  Opcao: "
if "!OP!"=="1" goto CLASSICO
if "!OP!"=="2" goto MODERNO
if "!OP!"=="0" call "%~dp0_ui.bat" :sair 0 & exit /b 0
echo   Opcao invalida.
timeout /t 2 >nul
goto MENU

:CLASSICO
echo.
echo   Aplicando menu classico...
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve >nul
goto RESTART

:MODERNO
echo.
echo   Aplicando menu moderno...
reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1
goto RESTART

:RESTART
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe
echo   Explorer reiniciado.
"""
    + FOOTER
)


def main() -> None:
    folder = Path(__file__).parent
    all_scripts = dict(SCRIPTS)
    all_scripts["alternar_contexto.bat"] = ALTERNAR_CONTEXTO
    ui = folder / "_ui.bat"
    if not ui.is_file():
        raise SystemExit("Falta scripts/_ui.bat")

    for name, text in all_scripts.items():
        path = folder / name
        path.write_text(text, encoding="utf-8", newline="\r\n")
        print("OK", name)


if __name__ == "__main__":
    main()
