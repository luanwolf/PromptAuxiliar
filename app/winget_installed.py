"""Detecção de pacotes instalados via `winget list` (cache em memória)."""

from __future__ import annotations

import re
import subprocess
import threading
import time

_CACHE_TTL = 300.0
_lock = threading.Lock()
_cache_blob = ""
_cache_ids: set[str] | None = None
_cache_time = 0.0
_scanning = False

_ID_IN_LINE = re.compile(
    r"\s([A-Za-z0-9][A-Za-z0-9_.-]*\.[A-Za-z0-9][A-Za-z0-9_.-]*)\s"
)
_STORE_ID = re.compile(r"\b(9[A-Z0-9]{10,})\b", re.IGNORECASE)


def _run_winget_list(timeout: int = 120) -> str:
    kwargs: dict = {
        "capture_output": True,
        "text": True,
        "encoding": "utf-8",
        "errors": "replace",
        "timeout": timeout,
        "shell": False,
    }
    if hasattr(subprocess, "CREATE_NO_WINDOW"):
        kwargs["creationflags"] = subprocess.CREATE_NO_WINDOW  # type: ignore[attr-defined]
    proc = subprocess.run(
        ["winget", "list", "--accept-source-agreements", "--disable-interactivity"],
        **kwargs,
    )
    return (proc.stdout or "") + "\n" + (proc.stderr or "")


def _parse_ids(blob: str) -> set[str]:
    ids: set[str] = set()
    lower = blob.lower()
    for line in blob.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("-") or "---" in stripped:
            continue
        if re.match(r"^nome\s+id", stripped, re.I):
            continue
        for m in _ID_IN_LINE.finditer(" " + line + " "):
            ids.add(m.group(1).lower())
        for m in _STORE_ID.finditer(line):
            ids.add(m.group(1).lower())
    # fallback: qualquer id winget mencionado no texto completo
    for m in re.finditer(
        r"\b([a-z][a-z0-9]*(?:\.[a-z][a-z0-9_-]*){1,})\b",
        lower,
    ):
        token = m.group(1)
        if "." in token and len(token) > 4:
            ids.add(token)
    return ids


def refresh_installed(*, force: bool = False, wait: bool = True) -> dict:
    """Atualiza cache. Com wait=False, retorna imediatamente se já houver scan em curso."""
    global _cache_blob, _cache_ids, _cache_time, _scanning

    with _lock:
        if (
            not force
            and _cache_ids is not None
            and (time.time() - _cache_time) < _CACHE_TTL
        ):
            return {"ok": True, "count": len(_cache_ids), "cached": True}
        if _scanning and not wait:
            return {
                "ok": True,
                "count": len(_cache_ids or []),
                "pending": True,
            }
        if _scanning and wait:
            scanning = True
        else:
            _scanning = True
            scanning = False

    if scanning:
        while True:
            with _lock:
                if not _scanning:
                    return {
                        "ok": True,
                        "count": len(_cache_ids or []),
                        "cached": True,
                    }
            time.sleep(0.15)

    try:
        blob = _run_winget_list()
        ids = _parse_ids(blob)
        with _lock:
            _cache_blob = blob.lower()
            _cache_ids = ids
            _cache_time = time.time()
        return {"ok": True, "count": len(ids), "cached": False}
    except Exception as e:
        return {"ok": False, "message": str(e)}
    finally:
        with _lock:
            _scanning = False


def is_installed(catalog_id: str) -> bool:
    cid = catalog_id.strip().lower()
    if not cid:
        return False

    with _lock:
        ids = _cache_ids
        blob = _cache_blob

    if ids is None:
        refresh_installed(wait=True)
        with _lock:
            ids = _cache_ids or set()
            blob = _cache_blob

    if cid in ids:
        return True
    if cid in blob:
        return True

    if "_" in cid:
        stem = cid.split("_8wekyb3d8bbwe")[0].split("_")[0]
        if stem and stem in blob:
            return True

    return False


def prefetch_installed_scan() -> None:
    """Dispara leitura do winget list em segundo plano (boot do app)."""

    def _worker() -> None:
        refresh_installed(force=False, wait=True)

    threading.Thread(target=_worker, daemon=True).start()
