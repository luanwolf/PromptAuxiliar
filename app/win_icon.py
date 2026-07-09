"""Define icone da janela no Windows."""

from __future__ import annotations

import ctypes
import sys
import threading
import time
from ctypes import wintypes

from app.paths import caminho_icone


def _enum_windows(titulo_contem: str) -> int | None:
    user32 = ctypes.windll.user32
    encontrado: list[int] = []

    @ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
    def callback(hwnd: int, _lparam: int) -> bool:
        if not user32.IsWindowVisible(hwnd):
            return True
        length = user32.GetWindowTextLengthW(hwnd) + 1
        buf = ctypes.create_unicode_buffer(length)
        user32.GetWindowTextW(hwnd, buf, length)
        if titulo_contem.lower() in buf.value.lower():
            encontrado.append(hwnd)
            return False
        return True

    user32.EnumWindows(callback, 0)
    return encontrado[0] if encontrado else None


def aplicar_icone_janela(hwnd: int, ico: str | None = None) -> bool:
    path = str(ico or caminho_icone())
    if not __import__("os").path.isfile(path):
        return False
    user32 = ctypes.windll.user32
    LR_LOADFROMFILE = 0x0010
    LR_DEFAULTSIZE  = 0x0040
    IMAGE_ICON = 1
    WM_SETICON = 0x80
    ICON_SMALL = 0
    ICON_BIG   = 1

    # LR_DEFAULTSIZE lets Windows scale from whatever resolution is in the ICO
    # (works with PNG-in-ICO containers on Windows Vista+)
    flags = LR_LOADFROMFILE | LR_DEFAULTSIZE
    hicon = user32.LoadImageW(0, path, IMAGE_ICON, 0, 0, flags)
    if not hicon:
        # Last-resort: load without any size hint
        hicon = user32.LoadImageW(0, path, IMAGE_ICON, 0, 0, LR_LOADFROMFILE)
    if not hicon:
        return False

    user32.SendMessageW(hwnd, WM_SETICON, ICON_SMALL, hicon)
    user32.SendMessageW(hwnd, WM_SETICON, ICON_BIG,   hicon)
    return True


def aplicar_icone_por_titulo(titulo_contem: str = "Prompt Auxiliar", atraso_s: float = 0.25) -> None:
    if sys.platform != "win32":
        return

    def worker() -> None:
        # Retry for up to ~15 s (60 × 0.25 s) until the WebView2 window appears
        for _ in range(60):
            time.sleep(atraso_s)
            hwnd = _enum_windows(titulo_contem)
            if hwnd and aplicar_icone_janela(hwnd):
                return

    threading.Thread(target=worker, daemon=True).start()
