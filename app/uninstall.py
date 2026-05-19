"""Remove pastas e atalhos do Prompt Auxiliar (após fechar o app)."""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile
from pathlib import Path

from app.config import PASTA_BASE


def uninstall_paths() -> list[Path]:
    paths: list[Path] = [Path(PASTA_BASE)]
    local = os.environ.get("LOCALAPPDATA", "")
    if local:
        paths.append(Path(local) / "PromptAuxiliar")
    if getattr(sys, "frozen", False):
        paths.append(Path(sys.executable).resolve().parent)
    else:
        root = Path(__file__).resolve().parent.parent
        if (root / "main.py").is_file():
            paths.append(root)
    seen: set[str] = set()
    unique: list[Path] = []
    for p in paths:
        key = str(p.resolve()).lower() if p.exists() else str(p).lower()
        if key not in seen:
            seen.add(key)
            unique.append(p)
    return unique


def paths_for_display() -> list[str]:
    return [str(p) for p in uninstall_paths()]


def _write_utf8_no_bom(path: Path, content: str) -> None:
    path.write_bytes(content.encode("utf-8"))


def schedule_uninstall() -> None:
    """Script em arquivo temporário: aguarda o app encerrar e remove as pastas."""
    targets = uninstall_paths()
    quoted = ",\n".join(
        "    '" + str(p).replace("'", "''") + "'" for p in targets
    )
    script = f"""# Prompt Auxiliar - desinstalacao
$ErrorActionPreference = 'SilentlyContinue'
$targets = @(
{quoted}
)
Start-Sleep -Seconds 3
for ($w = 0; $w -lt 90; $w++) {{
    $busy = $false
    foreach ($root in $targets) {{
        if (-not $root) {{ continue }}
        $pattern = ($root.TrimEnd('\\') + '*')
        $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
            Where-Object {{ $_.ExecutablePath -and ($_.ExecutablePath -like $pattern) }}
        if ($procs) {{
            $busy = $true
            break
        }}
    }}
    if (-not $busy) {{ break }}
    Start-Sleep -Seconds 1
}}
foreach ($root in $targets) {{
    if (-not $root) {{ continue }}
    if (Test-Path -LiteralPath $root) {{
        Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
    }}
    if (Test-Path -LiteralPath $root) {{
        cmd /c "rd /s /q `"$root`""
    }}
}}
$desk = [Environment]::GetFolderPath('Desktop')
$sm = Join-Path $env:APPDATA 'Microsoft\\Windows\\Start Menu\\Programs'
foreach ($dir in @($desk, $sm)) {
    if (-not (Test-Path -LiteralPath $dir)) { continue }
    Get-ChildItem -LiteralPath $dir -Filter 'Prompt Auxiliar*.lnk' -File -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
}
"""
    ps1 = Path(tempfile.gettempdir()) / "promptauxiliar-uninstall.ps1"
    _write_utf8_no_bom(ps1, script)

    kwargs: dict = {"shell": False}
    if sys.platform == "win32" and hasattr(subprocess, "CREATE_NO_WINDOW"):
        kwargs["creationflags"] = subprocess.CREATE_NO_WINDOW  # type: ignore[attr-defined]
    subprocess.Popen(
        [
            "powershell.exe",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-WindowStyle",
            "Hidden",
            "-File",
            str(ps1),
        ],
        **kwargs,
    )
