"""Caminhos do projeto (dev, frozen, instalado)."""

from __future__ import annotations

import struct
import sys
from pathlib import Path


def raiz_projeto() -> Path:
    if getattr(sys, "frozen", False):
        return Path(sys._MEIPASS)
    return Path(__file__).resolve().parent.parent


def _gerar_ico(png: Path, ico: Path) -> bool:
    """Wraps a PNG inside a minimal ICO container (Windows Vista+ supports PNG-ICO)."""
    try:
        data = png.read_bytes()
        w = struct.unpack(">I", data[16:20])[0]
        h = struct.unpack(">I", data[20:24])[0]
        # ICO header: reserved=0, type=1 (icon), count=1
        header = struct.pack("<HHH", 0, 1, 1)
        # ICONDIRENTRY: width, height (0 = 256), colorCount, reserved, planes, bitCount, size, offset
        entry = struct.pack(
            "<BBBBHHII",
            0 if w == 256 else w,
            0 if h == 256 else h,
            0, 0, 1, 32, len(data), 22,
        )
        ico.parent.mkdir(parents=True, exist_ok=True)
        ico.write_bytes(header + entry + data)
        return True
    except Exception:
        return False


def caminho_icone() -> Path:
    raiz = raiz_projeto()
    # Prefer an already-generated .ico file
    for rel in ("imagens/logo.ico", "web/assets/logo.ico"):
        p = raiz / rel
        if p.is_file():
            return p
    # Generate .ico on the fly from the PNG (no external dependencies)
    png = raiz / "web" / "assets" / "logo-mark.png"
    ico = raiz / "web" / "assets" / "logo.ico"
    if png.is_file() and _gerar_ico(png, ico):
        return ico
    return raiz / "imagens" / "logo.ico"
