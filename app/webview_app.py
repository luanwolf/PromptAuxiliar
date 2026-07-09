"""Interface nativa WebView2 (Edge)."""

from __future__ import annotations

import os
import sys

from app.api import PromptAuxiliarApi
from app.paths import caminho_icone
from app.updater import get_local_version


def _base_projeto() -> str:
    if getattr(sys, "frozen", False):
        return sys._MEIPASS
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _caminho_web_index() -> str:
    return os.path.join(_base_projeto(), "web", "index.html")


def _definir_aumid() -> None:
    """Sets the App User Model ID so Windows shows the app icon instead of python.exe."""
    if sys.platform != "win32":
        return
    try:
        import ctypes
        ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(
            "PromptAuxiliar.App.1"
        )
    except Exception:
        pass


def iniciar_webview() -> None:
    try:
        import webview
    except ImportError as e:
        raise SystemExit(
            "Dependência 'pywebview' não instalada.\n"
            "Execute: pip install -r requirements.txt"
        ) from e

    _definir_aumid()

    index = _caminho_web_index()
    if not os.path.isfile(index):
        raise SystemExit(f"Interface web não encontrada: {index}")

    api = PromptAuxiliarApi()
    titulo = f"Prompt Auxiliar v{get_local_version()}"

    webview.create_window(
        titulo,
        url=index,
        js_api=api,
        width=1180,
        height=760,
        min_size=(940, 640),
        background_color="#0c0f14",
        text_select=True,
    )

    webview.start(gui="edgechromium", debug=False, icon=str(caminho_icone()))
