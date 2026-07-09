"""Verifica atualização no GitHub (branch main). Aplicação via win.ps1 / atalho."""

from __future__ import annotations

import base64
import json
import os
import re
import subprocess
import sys
import time
import urllib.request
from pathlib import Path
from typing import Any

from app.config import APP_VERSION, GITHUB_BRANCH, GITHUB_OWNER, GITHUB_RAW_WIN, GITHUB_REPO


def _parse_version(text: str) -> str | None:
    m = re.search(r'APP_VERSION\s*=\s*"([^"]+)"', text)
    return m.group(1).strip() if m else None


def _version_tuple(v: str) -> tuple[int, ...]:
    parts: list[int] = []
    for piece in v.strip().split("."):
        digits = re.match(r"(\d+)", piece)
        parts.append(int(digits.group(1)) if digits else 0)
    return tuple(parts)


def compare_versions(local: str, remote: str) -> int:
    a, b = _version_tuple(local), _version_tuple(remote)
    n = max(len(a), len(b))
    for i in range(n):
        va = a[i] if i < len(a) else 0
        vb = b[i] if i < len(b) else 0
        if va < vb:
            return -1
        if va > vb:
            return 1
    return 0


def _read_version_from_config_file(cfg: Path) -> str | None:
    try:
        if cfg.is_file():
            return _parse_version(cfg.read_text(encoding="utf-8"))
    except OSError:
        pass
    return None


def _repo_settings() -> tuple[str, str, str]:
    """Owner, repo e branch usados na consulta remota (do config carregado)."""
    try:
        from app import config as cfg_mod

        owner = getattr(cfg_mod, "GITHUB_OWNER", GITHUB_OWNER)
        repo = getattr(cfg_mod, "GITHUB_REPO", GITHUB_REPO)
        branch = getattr(cfg_mod, "GITHUB_BRANCH", GITHUB_BRANCH)
        return str(owner), str(repo), str(branch)
    except ImportError:
        return GITHUB_OWNER, GITHUB_REPO, GITHUB_BRANCH


def _remote_config_url() -> str:
    owner, repo, branch = _repo_settings()
    return (
        f"https://raw.githubusercontent.com/{owner}/{repo}/{branch}/app/config.py"
    )


def get_local_version() -> str:
    """Versão do config.py que o processo Python carregou (código em execução)."""
    try:
        from app import config as cfg_mod

        v = _read_version_from_config_file(Path(cfg_mod.__file__))
        if v:
            return v
    except (OSError, ImportError):
        pass
    return APP_VERSION


def get_installed_version() -> str | None:
    """Versão em %LOCALAPPDATA%\\PromptAuxiliar (ou PROMPTAUX_HOME), se existir."""
    roots: list[Path] = []
    home = os.environ.get("PROMPTAUX_HOME", "").strip()
    if home:
        roots.append(Path(home))
    default = _default_install_root()
    if default and default not in roots:
        roots.append(default)
    for root in roots:
        v = _read_version_from_config_file(root / "app" / "config.py")
        if v:
            return v
    return None


def get_update_compare_version() -> str:
    """Versão usada na checagem de update (instalação real, não só o clone de dev)."""
    return get_installed_version() or get_local_version()


def _default_install_root() -> Path | None:
    localappdata = os.environ.get("LOCALAPPDATA", "").strip()
    if not localappdata:
        return None
    root = Path(localappdata) / "PromptAuxiliar"
    return root if (root / "main.py").is_file() else None


def _fetch_remote_version_via_api(
    owner: str, repo: str, branch: str, timeout: float
) -> str | None:
    api_url = (
        f"https://api.github.com/repos/{owner}/{repo}/contents/app/config.py?ref={branch}"
    )
    req = urllib.request.Request(
        api_url,
        headers={
            "User-Agent": "PromptAuxiliar",
            "Accept": "application/vnd.github+json",
        },
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        payload = json.loads(resp.read().decode("utf-8", errors="replace"))
    content = payload.get("content")
    if not content:
        return None
    text = base64.b64decode(content).decode("utf-8", errors="replace")
    return _parse_version(text)


def fetch_remote_version(timeout: float = 20.0) -> str | None:
    """Consulta GitHub (API + raw); se divergirem, usa a versão mais recente."""
    owner, repo, branch = _repo_settings()
    api_v: str | None = None
    raw_v: str | None = None

    try:
        api_v = _fetch_remote_version_via_api(owner, repo, branch, timeout)
    except OSError:
        pass

    url = f"{_remote_config_url()}?_={int(time.time())}"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "PromptAuxiliar"})
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            text = resp.read().decode("utf-8", errors="replace")
        raw_v = _parse_version(text)
    except OSError:
        pass

    if api_v and raw_v:
        return api_v if compare_versions(api_v, raw_v) >= 0 else raw_v
    return api_v or raw_v


def install_root() -> Path | None:
    """Raiz da instalação real — nunca o repositório de desenvolvimento."""
    home = os.environ.get("PROMPTAUX_HOME", "").strip()
    if home:
        root = Path(home)
        # Ignorar se for um repositório git (clone de dev)
        if (root / "main.py").is_file() and not (root / ".git").is_dir():
            return root
    localappdata = os.environ.get("LOCALAPPDATA", "").strip()
    if localappdata:
        root = Path(localappdata) / "PromptAuxiliar"
        if (root / "main.py").is_file():
            return root
    return None


def launch_win_ps1_update() -> None:
    """Abre win.ps1 local com -Update; fallback para irm remoto se não encontrado."""
    flags = getattr(subprocess, "CREATE_NEW_CONSOLE", 0)

    root = install_root()
    win_local = (root / "win.ps1") if root else None

    if win_local and win_local.is_file():
        # CWD = TEMP para que $PWD no win.ps1 não aponte para AppData
        # (caso contrário Test-PromptAuxShouldDeferFolderSwap sempre adia)
        neutral_cwd = os.environ.get("TEMP", os.environ.get("SystemRoot", "C:\\Windows"))
        subprocess.Popen(
            [
                "powershell.exe",
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(win_local),
                "-Update",
            ],
            creationflags=flags,
            cwd=neutral_cwd,
        )
        return

    # Fallback: baixa do GitHub (sem $ScriptDir, mas funciona)
    url = GITHUB_RAW_WIN.replace("'", "''")
    subprocess.Popen(
        [
            "powershell.exe",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-Command",
            f"$env:PROMPTAUX_UPDATE='1'; irm '{url}' | iex",
        ],
        creationflags=flags,
    )


def check_for_update() -> dict[str, Any]:
    """Retorna status da versão remota (não substitui arquivos — use win.ps1)."""
    running = get_local_version()
    installed = get_installed_version()
    local = get_update_compare_version()
    remote = fetch_remote_version()
    owner, repo, branch = _repo_settings()
    check_url = _remote_config_url()

    if not remote:
        return {
            "ok": True,
            "local": local,
            "running_version": running,
            "installed_version": installed,
            "remote": None,
            "update_available": False,
            "check_url": check_url,
            "message": (
                f"Não foi possível consultar {owner}/{repo} (branch {branch}). "
                "Verifique sua conexão."
            ),
        }

    cmp = compare_versions(local, remote)
    available = cmp < 0
    running_note = ""
    if installed and running != installed:
        running_note = f" Código em execução: v{running}."

    if available:
        msg = (
            f"Nova versão v{remote} disponível (instalação v{local}). "
            "Use o botão Atualizar ou abra pelo atalho."
            f"{running_note}"
        )
    elif cmp > 0:
        msg = (
            f"A instalação (v{local}) é mais recente que a publicada no GitHub (v{remote}). "
            "Confirme se fez push do app/config.py na branch main."
            f"{running_note}"
        )
    else:
        msg = f"Você está na versão mais recente (v{local}).{running_note}"

    return {
        "ok": True,
        "local": local,
        "running_version": running,
        "installed_version": installed,
        "remote": remote,
        "update_available": available,
        "check_url": check_url,
        "message": msg,
    }
