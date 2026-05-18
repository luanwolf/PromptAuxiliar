"""Interface nativa WebView2 (Edge) — substitui CustomTkinter."""

from __future__ import annotations

import os
import sys

from app.api import PromptAuxiliarApi
from app.config import APP_VERSION


def _base_projeto() -> str:
    if getattr(sys, "frozen", False):
        return sys._MEIPASS
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _caminho_web_index() -> str:
    return os.path.join(_base_projeto(), "web", "index.html")


def iniciar_webview() -> None:
    try:
        import webview
    except ImportError as e:
        raise SystemExit(
            "Dependência 'pywebview' não instalada.\n"
            "Execute: pip install -r requirements.txt\n"
            "No Windows, instale também o WebView2 Runtime se necessário."
        ) from e

    index = _caminho_web_index()
    if not os.path.isfile(index):
        raise SystemExit(f"Interface web não encontrada: {index}")

    api = PromptAuxiliarApi()
    titulo = f"Prompt Auxiliar v{APP_VERSION}"

    window = webview.create_window(
        titulo,
        url=index,
        js_api=api,
        width=1180,
        height=760,
        min_size=(940, 640),
        background_color="#0c0f14",
        text_select=True,
    )

    webview.start(gui="edgechromium", debug=False)
