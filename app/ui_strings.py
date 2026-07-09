"""Carrega app/data/ui_strings.json (dev e bundle frozen)."""

from __future__ import annotations

import json
import sys
from functools import lru_cache
from pathlib import Path
from typing import Any

_CATALOG_REL = Path(__file__).parent / "data" / "ui_strings.json"


def _path() -> Path:
    if getattr(sys, "frozen", False):
        return Path(sys._MEIPASS) / "app" / "data" / "ui_strings.json"
    return _CATALOG_REL


@lru_cache(maxsize=1)
def load_ui_strings() -> dict[str, Any]:
    with open(_path(), encoding="utf-8") as f:
        return json.load(f)


def get_str(*keys: str, default: str = "") -> str:
    """Navega dict aninhado; retorna default se chave ausente."""
    cur: Any = load_ui_strings()
    for key in keys:
        if not isinstance(cur, dict):
            return default
        cur = cur.get(key)
    if cur is None:
        return default
    return str(cur)


if __name__ == "__main__":
    data = load_ui_strings()
    assert data.get("app", {}).get("nome"), "app.nome ausente"
    assert len(data.get("acoes", {})) >= 10, "catálogo de ações incompleto"
    print("ui_strings ok:", data["app"]["nome"])
