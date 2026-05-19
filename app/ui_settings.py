"""Preferências de interface (tema) em C:\\PromptAuxiliar\\ui_settings.json."""

from __future__ import annotations

import json
import os
from typing import Any

from app.config import PASTA_BASE

_SETTINGS_NAME = "ui_settings.json"
_VALID_THEMES = frozenset({"light", "dark"})
_VALID_SCRIPTS_LAYOUTS = frozenset({"grid", "list"})


def _settings_path() -> str:
    return os.path.join(PASTA_BASE, _SETTINGS_NAME)


def read_ui_settings() -> dict[str, Any]:
    path = _settings_path()
    if not os.path.isfile(path):
        return {"theme": "dark", "scripts_layout": "grid"}
    try:
        with open(path, encoding="utf-8") as f:
            raw = json.load(f)
    except (OSError, json.JSONDecodeError):
        return {"theme": "dark", "scripts_layout": "grid"}
    theme = str(raw.get("theme", "dark")).strip().lower()
    if theme not in _VALID_THEMES:
        theme = "dark"
    layout = str(raw.get("scripts_layout", "grid")).strip().lower()
    if layout not in _VALID_SCRIPTS_LAYOUTS:
        layout = "grid"
    return {"theme": theme, "scripts_layout": layout}


def write_ui_settings(data: dict[str, Any]) -> None:
    os.makedirs(PASTA_BASE, exist_ok=True)
    current = read_ui_settings()
    theme = str(data.get("theme", current["theme"])).strip().lower()
    if theme not in _VALID_THEMES:
        theme = "dark"
    layout = str(data.get("scripts_layout", current["scripts_layout"])).strip().lower()
    if layout not in _VALID_SCRIPTS_LAYOUTS:
        layout = "grid"
    payload = {"theme": theme, "scripts_layout": layout}
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


def get_scripts_layout() -> str:
    return read_ui_settings()["scripts_layout"]


def set_scripts_layout(layout: str) -> str:
    normalized = layout.strip().lower()
    if normalized not in _VALID_SCRIPTS_LAYOUTS:
        normalized = "grid"
    write_ui_settings({"scripts_layout": normalized})
    return normalized
