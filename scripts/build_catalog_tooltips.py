"""Gera app/data/catalog_tooltips.json com descricoes detalhadas dos programas."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "app" / "data"

sys.path.insert(0, str(ROOT))
from scripts.catalog_tooltip_texts import TOOLTIPS  # noqa: E402


def main() -> None:
    out: dict[str, str] = dict(TOOLTIPS)

    for name, path in (
        ("winget", DATA / "winget_catalog.json"),
        ("debloat", DATA / "debloat_catalog.json"),
    ):
        data = json.loads(path.read_text(encoding="utf-8"))
        for item in data["itens"]:
            pid = item["id"]
            if pid not in out:
                out[pid] = item.get("descricao", item.get("nome", "")).strip()

    (DATA / "catalog_tooltips.json").write_text(
        json.dumps(out, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"catalog_tooltips.json: {len(out)} entradas")


if __name__ == "__main__":
    main()
