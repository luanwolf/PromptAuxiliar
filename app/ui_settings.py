"""Preferências de interface (tema) em C:\\PromptAuxiliar\\ui_settings.json."""

from __future__ import annotations

import json
import os
from typing import Any

from app.config import PASTA_BASE

_SETTINGS_NAME = "ui_settings.json"
_VALID_THEMES = frozenset({"light", "dark"})


def _settings_path() -> str:
    return os.path.join(PASTA_BASE, _SETTINGS_NAME)


def read_ui_settings() -> dict[str, Any]:
    path = _settings_path()
    if not os.path.isfile(path):
        return {"theme": "dark"}
    try:
        with open(path, encoding="utf-8") as f:
            raw = json.load(f)
    except (OSError, json.JSONDecodeError):
        return {"theme": "dark"}
    theme = str(raw.get("theme", "dark")).strip().lower()
    if theme not in _VALID_THEMES:
        theme = "dark"
    return {"theme": theme}


def write_ui_settings(data: dict[str, Any]) -> None:
    os.makedirs(PASTA_BASE, exist_ok=True)
    theme = str(data.get("theme", "dark")).strip().lower()
    if theme not in _VALID_THEMES:
        theme = "dark"
    payload = {"theme": theme}
    with open(_settings_path(), "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, ensure_ascii=False)
        f.write("\n")


def get_theme() -> str:
    return read_ui_settings()["theme"]


def set_theme(theme: str) -> str:
    normalized = theme.strip().lower()
    if normalized not in _VALID_THEMES:
        normalized = "dark"
    write_ui_settings({"theme": normalized})
    return normalized
