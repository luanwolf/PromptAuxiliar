"""Verifica atualização no GitHub (branch main). Aplicação via win.ps1 / atalho."""

from __future__ import annotations

import os
import re
import sys
import time
import urllib.request
from pathlib import Path
from typing import Any

from app.config import APP_VERSION, GITHUB_BRANCH, GITHUB_OWNER, GITHUB_REPO

_CONFIG_URL = (
    f"https://raw.githubusercontent.com/{GITHUB_OWNER}/{GITHUB_REPO}"
    f"/{GITHUB_BRANCH}/app/config.py"
)


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


def get_local_version() -> str:
    """Versão do config.py que o processo Python carregou (instalação em execução)."""
    try:
        from app import config as cfg_mod

        cfg_path = Path(cfg_mod.__file__)
        if cfg_path.is_file():
            v = _parse_version(cfg_path.read_text(encoding="utf-8"))
            if v:
                return v
    except (OSError, ImportError):
        pass
    return APP_VERSION


def _default_install_root() -> Path | None:
    localappdata = os.environ.get("LOCALAPPDATA", "").strip()
    if not localappdata:
        return None
    root = Path(localappdata) / "PromptAuxiliar"
    return root if (root / "main.py").is_file() else None


def fetch_remote_version(timeout: float = 20.0) -> str | None:
    try:
        url = f"{_CONFIG_URL}?_={int(time.time())}"
        req = urllib.request.Request(url, headers={"User-Agent": "PromptAuxiliar"})
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            text = resp.read().decode("utf-8", errors="replace")
        return _parse_version(text)
    except OSError:
        return None


def install_root() -> Path | None:
    if os.environ.get("PROMPTAUX_HOME"):
        root = Path(os.environ["PROMPTAUX_HOME"])
        if (root / "main.py").is_file():
            return root
    if getattr(sys, "frozen", False):
        return None
    root = Path(__file__).resolve().parent.parent
    if (root / "main.py").is_file():
        return root
    return None


def should_skip_auto_update() -> bool:
    if os.environ.get("PROMPTAUX_SKIP_AUTO_UPDATE") == "1":
        return True
    root = install_root()
    if not root or not (root / ".git").is_dir():
        return False
    default = _default_install_root()
    if default:
        try:
            if root.resolve() == default.resolve():
                return False
        except OSError:
            pass
    return True


def check_for_update() -> dict[str, Any]:
    """Retorna status da versão remota (não substitui arquivos — use win.ps1)."""
    local = get_local_version()
    remote = fetch_remote_version()
    if not remote:
        return {
            "ok": True,
            "local": local,
            "remote": None,
            "update_available": False,
            "message": "Não foi possível verificar atualizações online.",
        }
    cmp = compare_versions(local, remote)
    available = cmp < 0
    if available:
        msg = (
            f"Nova versão v{remote} disponível (você está na v{local}). "
            "Feche o app e abra pelo atalho ou execute o instalador irm novamente."
        )
    elif cmp > 0:
        msg = (
            f"Sua instalação (v{local}) é mais recente que a publicada no GitHub (v{remote}). "
            "Aguarde a publicação no repositório ou use o clone de desenvolvimento."
        )
    else:
        msg = f"Você está na versão mais recente (v{local})."
    return {
        "ok": True,
        "local": local,
        "remote": remote,
        "update_available": available,
        "message": msg,
    }
