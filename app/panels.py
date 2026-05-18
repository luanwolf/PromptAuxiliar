"""Painéis Winget e Debloat — catálogo, seleção e execução."""

from __future__ import annotations

import json
import os
import subprocess
import threading
from pathlib import Path
from typing import Any, Literal

from app.config import PASTA_BASE

PanelKind = Literal["winget", "debloat"]
_SELECTION_FILE = "panels.json"
_LEGACY_TXT = {"winget": "winget.txt", "debloat": "bloatware.txt"}


def _catalog_path(kind: PanelKind) -> Path:
    import sys

    if getattr(sys, "frozen", False):
        return Path(sys._MEIPASS) / "app" / "data" / f"{kind}_catalog.json"
    return Path(__file__).parent / "data" / f"{kind}_catalog.json"


def _selection_path() -> Path:
    return Path(PASTA_BASE) / _SELECTION_FILE


def _load_catalog(kind: PanelKind) -> dict[str, Any]:
    with open(_catalog_path(kind), encoding="utf-8") as f:
        return json.load(f)


def _read_store() -> dict[str, list[str]]:
    _migrate_legacy_txt()
    path = _selection_path()
    if not path.is_file():
        return {"winget": [], "debloat": []}
    with open(path, encoding="utf-8") as f:
        raw = json.load(f)
    return {
        "winget": [str(x) for x in raw.get("winget", [])],
        "debloat": [str(x) for x in raw.get("debloat", [])],
    }


def _write_store(store: dict[str, list[str]]) -> None:
    os.makedirs(PASTA_BASE, exist_ok=True)
    path = _selection_path()
    path.write_text(
        json.dumps(store, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def _migrate_legacy_txt() -> None:
    if _selection_path().is_file():
        return
    store: dict[str, list[str]] = {"winget": [], "debloat": []}
    found = False
    for kind, name in _LEGACY_TXT.items():
        leg = Path(PASTA_BASE) / name
        if not leg.is_file():
            continue
        found = True
        ids: list[str] = []
        for line in leg.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#"):
                ids.append(line)
        store[kind] = ids
    if found:
        _write_store(store)


def read_selected_ids(kind: PanelKind) -> set[str]:
    return set(_read_store().get(kind, []))


def write_selected_ids(kind: PanelKind, ids: list[str]) -> None:
    catalog = _load_catalog(kind)
    valid = {item["id"] for item in catalog["itens"]}
    clean = [i for i in ids if i in valid]
    store = _read_store()
    store[kind] = clean
    _write_store(store)


def get_panel(kind: PanelKind) -> dict[str, Any]:
    catalog = _load_catalog(kind)
    selected = read_selected_ids(kind)
    primeira_carga = not _selection_path().is_file()

    itens = []
    for item in catalog["itens"]:
        pid = item["id"]
        if pid in selected:
            sel = True
        elif primeira_carga and kind == "debloat" and item.get("padrao"):
            sel = True
        else:
            sel = False
        itens.append(
            {
                "id": pid,
                "nome": item["nome"],
                "categoria": item["categoria"],
                "descricao": item.get("descricao", ""),
                "selecionado": sel,
            }
        )

    return {
        "kind": kind,
        "titulo": "Instalar via Winget" if kind == "winget" else "Debloat Windows 11",
        "subtitulo": (
            "Selecione os programas para instalar"
            if kind == "winget"
            else "Selecione apps pré-instalados para remover"
        ),
        "categorias": catalog["categorias"],
        "itens": itens,
        "total_selecionados": sum(1 for i in itens if i["selecionado"]),
    }


def _executar_winget_terminal(kind: PanelKind, ids: list[str]) -> None:
    titulo = "Prompt Auxiliar - Winget" if kind == "winget" else "Prompt Auxiliar - Debloat"
    lines = [
        f"$Host.UI.RawUI.WindowTitle = '{titulo}'",
        f"Write-Host '===== {titulo} =====' -ForegroundColor Cyan",
        "Write-Host ''",
    ]
    for pkg in ids:
        safe = pkg.replace("'", "''")
        if kind == "winget":
            lines.append(f"Write-Host '[INSTALAR] {pkg}' -ForegroundColor Green")
            lines.append(
                f"winget install --id '{safe}' "
                "--accept-source-agreements --accept-package-agreements -h"
            )
        else:
            lines.append(f"Write-Host '[REMOVER] {pkg}' -ForegroundColor Yellow")
            lines.append(f"winget uninstall --id '{safe}' -h")
        lines.append("Write-Host ''")
    lines.append("Write-Host 'Processo concluido.' -ForegroundColor Green")
    lines.append("Read-Host 'Pressione Enter para fechar'")

    script = "\n".join(lines)
    subprocess.Popen(
        [
            "cmd",
            "/c",
            "start",
            titulo,
            "powershell.exe",
            "-NoProfile",
            "-NoExit",
            "-ExecutionPolicy",
            "Bypass",
            "-Command",
            script,
        ],
        shell=False,
    )


def run_panel(kind: PanelKind, ids: list[str] | None = None) -> dict[str, Any]:
    if ids is None:
        ids = list(read_selected_ids(kind))
    else:
        write_selected_ids(kind, ids)

    if not ids:
        return {"ok": False, "message": "Nenhum item selecionado."}

    def worker() -> None:
        _executar_winget_terminal(kind, ids)

    threading.Thread(target=worker, daemon=True).start()
    acao = "Instalação" if kind == "winget" else "Remoção"
    return {
        "ok": True,
        "message": f"{acao} de {len(ids)} item(ns) iniciada no terminal.",
        "total": len(ids),
    }
