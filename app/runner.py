"""Executa scripts .ps1/.bat com console elegante."""

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



def _install_script_candidates(nome_arquivo: str) -> list[Path]:
    candidatos: list[Path] = []
    vistos: set[str] = set()

    def add(base: Path | None) -> None:
        if base is None:
            return
        p = (base / "scripts" / nome_arquivo).resolve()
        key = str(p).lower()
        if key not in vistos:
            vistos.add(key)
            candidatos.append(p)

    home = os.environ.get("PROMPTAUX_HOME", "").strip()
    if home:
        add(Path(home))
    localappdata = os.environ.get("LOCALAPPDATA", "").strip()
    if localappdata:
        add(Path(localappdata) / "PromptAuxiliar")
    if getattr(sys, "frozen", False):
        add(Path(sys._MEIPASS))
    add(Path(PASTA_BASE))
    return candidatos


def resolver_script(nome_arquivo: str) -> str:
    for caminho in _install_script_candidates(nome_arquivo):
        if caminho.is_file():
            return str(caminho)
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


def _build_ps1_run_file(script_path: Path) -> Path:
    """Constrói arquivo temporário PS1 com _ui.ps1 embutido (UTF-8-BOM).

    Isso garante que as funções visuais estejam disponíveis independente
    de onde _ui.ps1 esteja instalado e resolve problemas de encoding.
    O arquivo temp é escrito com BOM para o PowerShell 5.1 ler corretamente.
    """
    _PS_RUN.mkdir(parents=True, exist_ok=True)
    run_path = _PS_RUN / f"run_{uuid.uuid4().hex}.ps1"

    ui_path = script_path.parent / "_ui.ps1"
    util_path = script_path.parent / "_util_install.ps1"
    try:
        ui_src = ui_path.read_text(encoding="utf-8-sig") if ui_path.is_file() else ""
        util_src = util_path.read_text(encoding="utf-8-sig") if util_path.is_file() else ""
        sc_src = script_path.read_text(encoding="utf-8-sig")
    except OSError:
        return script_path  # fallback: rodar original

    def _is_dotsource_line(ln: str) -> bool:
        s = ln.strip()
        return (
            "_ui.ps1" in s
            or "_util_install.ps1" in s
        ) and s.startswith(".")

    sc_lines = [ln for ln in sc_src.splitlines() if not _is_dotsource_line(ln)]
    chunks = [c for c in (ui_src.strip(), util_src.strip(), "\n".join(sc_lines).strip()) if c]
    combined = "\n\n".join(chunks) + "\n"
    run_path.write_text(combined, encoding="utf-8-sig")
    return run_path


def _params_to_env(params: dict[str, str] | None) -> dict[str, str]:
    """Converte parâmetros do app para variáveis de ambiente lidas pelos scripts."""
    if not params:
        return {}
    key_map = {
        "url": "PA_UTIL_URL",
        "dest": "PA_UTIL_DEST",
        "mode": "PA_UTIL_MODE",
        "playlist": "PA_UTIL_PLAYLIST",
    }
    out: dict[str, str] = {}
    for k, v in params.items():
        env_key = key_map.get(k.lower())
        if env_key and v is not None:
            out[env_key] = str(v)
    return out


def _abrir_console_script(
    script: str,
    titulo: str,
    extra_env: dict[str, str] | None = None,
) -> None:
    """Abre o script em nova janela — .ps1 via PowerShell, .bat via CMD."""
    script_path = Path(script).resolve()
    if not script_path.is_file():
        raise ScriptNaoEncontradoError(f"Script não encontrado: {script_path}")

    flags = getattr(subprocess, "CREATE_NEW_CONSOLE", 0)
    env = os.environ.copy()
    if extra_env:
        env.update(extra_env)

    if script_path.suffix.lower() == ".ps1":
        # Gera arquivo temp com _ui.ps1 embutido e encoding UTF-8-BOM
        run_path = _build_ps1_run_file(script_path)
        subprocess.Popen(
            [
                "powershell.exe",
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(run_path),
            ],
            cwd=str(script_path.parent),
            creationflags=flags,
            env=env,
        )
    else:
        # Passar string (não lista) evita list2cmdline que converte " em \"
        subprocess.Popen(
            f'cmd.exe /c "{script_path}"',
            cwd=str(script_path.parent),
            creationflags=flags,
            env=env,
        )


def usa_powershell_admin(action_id: str) -> bool:
    return action_id in _COMANDOS_PS_ADMIN


def executar_acao(
    acao: Acao,
    *,
    aguardar: bool = True,
    params: dict[str, str] | None = None,
) -> subprocess.Popen | int:
    comando = _COMANDOS_PS_ADMIN.get(acao.id)
    if comando:
        _executar_ps_admin(comando, acao.nome)
        return 0
    caminho = resolver_script(acao.script)
    _abrir_console_script(caminho, acao.nome, extra_env=_params_to_env(params))
    return 0


def executar_por_id(identificador: str, *, aguardar: bool = True) -> subprocess.Popen | int:
    acao = obter_acao(identificador)
    if not acao:
        raise ValueError(f"Ação desconhecida: {identificador}")
    return executar_acao(acao, aguardar=aguardar)
