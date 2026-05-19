"""Executa scripts .bat com console elegante."""

from __future__ import annotations

import os
import subprocess
import sys
import uuid
from pathlib import Path

from app.actions import Acao, obter_acao
from app.config import PASTA_BASE

_PS_RUN = Path(os.environ.get("TEMP", ".")) / "PromptAuxiliar" / "run"

# Apos confirmacao no app: PowerShell elevado (sem .bat intermediario).
_COMANDOS_PS_ADMIN: dict[str, str] = {
    "utilitario-externo": 'irm "https://christitus.com/win" | iex',
    "ativar-windows-kms": "irm https://get.activated.win | iex",
    "ativar-office-kms": "irm https://get.activated.win | iex",
}


class ScriptNaoEncontradoError(FileNotFoundError):
    pass


def _raiz_projeto() -> Path:
    return Path(__file__).resolve().parent.parent


def resolver_script(nome_arquivo: str) -> str:
    candidatos: list[Path] = []
    if getattr(sys, "frozen", False):
        candidatos.append(Path(sys._MEIPASS) / "scripts" / nome_arquivo)
    candidatos.append(_raiz_projeto() / "scripts" / nome_arquivo)
    custom = Path(PASTA_BASE) / "scripts" / nome_arquivo
    if custom not in candidatos:
        candidatos.append(custom)
    for caminho in candidatos:
        if caminho.is_file():
            return str(caminho.resolve())
    raise ScriptNaoEncontradoError(f"Script '{nome_arquivo}' não encontrado.")


def _escape_ps(s: str) -> str:
    return s.replace("'", "''")


def _executar_ps_admin(comando: str, titulo: str) -> None:
    """Abre PowerShell como administrador com o comando remoto."""
    _PS_RUN.mkdir(parents=True, exist_ok=True)
    titulo_esc = _escape_ps(titulo)
    script_admin = _PS_RUN / f"admin_{uuid.uuid4().hex}.ps1"
    script_admin.write_text(
        f"$Host.UI.RawUI.WindowTitle = '{titulo_esc} | Prompt Auxiliar'\n{comando}\n",
        encoding="utf-8-sig",
    )
    script_path = _escape_ps(str(script_admin.resolve()))
    elevador = _PS_RUN / f"elevate_{uuid.uuid4().hex}.ps1"
    elevador.write_text(
        f"""$p = '{script_path}'
Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @(
  '-NoProfile', '-ExecutionPolicy', 'Bypass', '-NoExit', '-File', $p
)
""",
        encoding="utf-8-sig",
    )
    flags = getattr(subprocess, "CREATE_NEW_CONSOLE", 0)
    subprocess.Popen(
        [
            "powershell.exe",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-WindowStyle",
            "Hidden",
            "-File",
            str(elevador),
        ],
        creationflags=flags,
        cwd=str(_PS_RUN),
    )


def _abrir_console_script(script: str, titulo: str) -> None:
    script_path = Path(script).resolve()
    script_dir = _escape_ps(str(script_path.parent))
    script_name = _escape_ps(script_path.name)
    titulo_esc = _escape_ps(titulo)

    ps_body = f"""
$OutputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$Host.UI.RawUI.WindowTitle = '{titulo_esc} | Prompt Auxiliar'
try {{
  $b = $Host.UI.RawUI.BufferSize
  $Host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(100, 9999)
  $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(100, [Math]::Min(40, $b.Height))
}} catch {{}}

Set-Location -LiteralPath '{script_dir}'
$proc = Start-Process -FilePath 'cmd.exe' `
  -ArgumentList '/c','chcp 65001>nul & call ""{script_name}""' `
  -Wait -PassThru -NoNewWindow
exit $proc.ExitCode
"""

    _PS_RUN.mkdir(parents=True, exist_ok=True)
    ps1 = _PS_RUN / f"run_{uuid.uuid4().hex}.ps1"
    ps1.write_text(ps_body.strip() + "\n", encoding="utf-8-sig")

    flags = getattr(subprocess, "CREATE_NEW_CONSOLE", 0)
    subprocess.Popen(
        [
            "powershell.exe",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ps1),
        ],
        creationflags=flags,
        cwd=str(_PS_RUN),
    )


def usa_powershell_admin(action_id: str) -> bool:
    return action_id in _COMANDOS_PS_ADMIN


def executar_acao(acao: Acao, *, aguardar: bool = True) -> subprocess.Popen | int:
    comando = _COMANDOS_PS_ADMIN.get(acao.id)
    if comando:
        _executar_ps_admin(comando, acao.nome)
        return 0
    caminho = resolver_script(acao.script)
    _abrir_console_script(caminho, acao.nome)
    return 0


def executar_por_id(identificador: str, *, aguardar: bool = True) -> subprocess.Popen | int:
    acao = obter_acao(identificador)
    if not acao:
        raise ValueError(f"Ação desconhecida: {identificador}")
    return executar_acao(acao, aguardar=aguardar)
