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
    LR_LOADFROMFILE = 0x10
    IMAGE_ICON = 1
    WM_SETICON = 0x80
    ICON_SMALL = 0
    ICON_BIG = 1

    # Load big icon (32x32 or best match) for alt-tab / title bar
    hicon_big = user32.LoadImageW(0, path, IMAGE_ICON, 32, 32, LR_LOADFROMFILE)
    # Load small icon (16x16) for taskbar
    hicon_small = user32.LoadImageW(0, path, IMAGE_ICON, 16, 16, LR_LOADFROMFILE)

    if not hicon_big and not hicon_small:
        return False

    if hicon_big:
        user32.SendMessageW(hwnd, WM_SETICON, ICON_BIG, hicon_big)
    if hicon_small:
        user32.SendMessageW(hwnd, WM_SETICON, ICON_SMALL, hicon_small)
    return True


def aplicar_icone_por_titulo(titulo_contem: str = "Prompt Auxiliar", atraso_s: float = 1.2) -> None:
    if sys.platform != "win32":
        return

    def worker() -> None:
        for _ in range(20):
            time.sleep(atraso_s / 10)
            hwnd = _enum_windows(titulo_contem)
            if hwnd and aplicar_icone_janela(hwnd):
                return

    threading.Thread(target=worker, daemon=True).start()
