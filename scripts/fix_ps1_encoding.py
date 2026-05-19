"""Remove BOM e caracteres problematicos dos .ps1 (Windows PowerShell 5.1)."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

REPLACEMENTS = {
    "\ufeff": "",
    "\u2014": "-",
    "\u2013": "-",
    "\u2026": "...",
    "\u2192": "->",
}


def normalize_ps1(text: str) -> str:
    for old, new in REPLACEMENTS.items():
        text = text.replace(old, new)
    if text.startswith("\ufeff"):
        text = text.lstrip("\ufeff")
    return text.replace("\r\n", "\n").replace("\n", "\r\n")


def main() -> None:
    for path in ROOT.rglob("*.ps1"):
        if ".git" in path.parts:
            continue
        raw = path.read_bytes()
        if raw.startswith(b"\xef\xbb\xbf"):
            raw = raw[3:]
        text = raw.decode("utf-8", errors="replace")
        text = normalize_ps1(text)
        path.write_bytes(text.encode("utf-8"))
        print(f"OK {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
