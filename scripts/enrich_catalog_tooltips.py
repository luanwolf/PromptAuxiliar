"""Atualiza descricao_detalhada nos catálogos (só texto sobre o programa)."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "app" / "data"
TOOLTIPS_FILE = DATA / "catalog_tooltips.json"


def _load_tooltips() -> dict[str, str]:
    if not TOOLTIPS_FILE.is_file():
        return {}
    return json.loads(TOOLTIPS_FILE.read_text(encoding="utf-8"))


def _detail(item: dict, tooltips: dict[str, str]) -> str:
    pid = item["id"]
    if pid in tooltips:
        return tooltips[pid].strip()
    return item.get("descricao", item.get("nome", "")).strip()


def _enrich_file(path: Path, tooltips: dict[str, str]) -> None:
    data = json.loads(path.read_text(encoding="utf-8"))
    for item in data["itens"]:
        item["descricao_detalhada"] = _detail(item, tooltips)
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"{path.name}: {len(data['itens'])} itens")


if __name__ == "__main__":
    tips = _load_tooltips()
    _enrich_file(DATA / "winget_catalog.json", tips)
    _enrich_file(DATA / "debloat_catalog.json", tips)
