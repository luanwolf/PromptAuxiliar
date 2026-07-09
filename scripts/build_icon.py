"""Gera imagens/logo.ico a partir de web/assets/logo.png."""

from __future__ import annotations

from pathlib import Path


def main() -> None:
    try:
        from PIL import Image
    except ImportError as e:
        raise SystemExit("Instale Pillow: pip install Pillow") from e

    root = Path(__file__).resolve().parent.parent
    src = root / "web" / "assets" / "logo.png"
    if not src.is_file():
        src = root / "web" / "assets" / "logo-mark.png"
    if not src.is_file():
        raise SystemExit(f"Logo PNG nao encontrado em web/assets/")

    img = Image.open(src).convert("RGBA")
    sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]

    for folder in (root / "imagens", root / "web" / "assets"):
        folder.mkdir(parents=True, exist_ok=True)
        dst = folder / "logo.ico"
        img.save(dst, format="ICO", sizes=sizes)
        print(f"OK {dst}")


if __name__ == "__main__":
    main()
