"""Remove pastas e atalhos do Prompt Auxiliar (após fechar o app)."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

from app.config import PASTA_BASE


def uninstall_paths() -> list[Path]:
    paths: list[Path] = [Path(PASTA_BASE)]
    local = os.environ.get("LOCALAPPDATA", "")
    if local:
        paths.append(Path(local) / "PromptAuxiliar")
    seen: set[str] = set()
    unique: list[Path] = []
    for p in paths:
        key = str(p).lower()
        if key not in seen:
            seen.add(key)
            unique.append(p)
    return unique


def paths_for_display() -> list[str]:
    return [str(p) for p in uninstall_paths()]


def schedule_uninstall() -> None:
    """Agenda exclusão em PowerShell após o processo encerrar."""
    parts = ["Start-Sleep -Seconds 2"]
    for p in uninstall_paths():
        escaped = str(p).replace("'", "''")
        parts.append(
            f"if (Test-Path -LiteralPath '{escaped}') {{ "
            f"Remove-Item -LiteralPath '{escaped}' -Recurse -Force -ErrorAction SilentlyContinue }}"
        )
    parts.extend(
        [
            "$desk = [Environment]::GetFolderPath('Desktop')",
            "$sm = Join-Path $env:APPDATA 'Microsoft\\Windows\\Start Menu\\Programs'",
            "Remove-Item (Join-Path $desk 'Prompt Auxiliar.lnk') -Force -ErrorAction SilentlyContinue",
            "Remove-Item (Join-Path $sm 'Prompt Auxiliar.lnk') -Force -ErrorAction SilentlyContinue",
        ]
    )
    script = "; ".join(parts)
    kwargs: dict = {"shell": False}
    if sys.platform == "win32" and hasattr(subprocess, "CREATE_NO_WINDOW"):
        kwargs["creationflags"] = subprocess.CREATE_NO_WINDOW  # type: ignore[attr-defined]
    subprocess.Popen(
        [
            "powershell.exe",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-Command",
            script,
        ],
        **kwargs,
    )
