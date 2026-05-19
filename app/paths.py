"""Caminhos do projeto (dev, frozen, instalado)."""

from __future__ import annotations

import os
import sys
from pathlib import Path


def raiz_projeto() -> Path:
    if getattr(sys, "frozen", False):
        return Path(sys._MEIPASS)
    return Path(__file__).resolve().parent.parent


def caminho_icone() -> Path:
    raiz = raiz_projeto()
    for rel in ("imagens/logo.ico", "web/assets/logo-mark.png"):
        p = raiz / rel
        if p.is_file():
            return p
    return raiz / "imagens" / "logo.ico"
