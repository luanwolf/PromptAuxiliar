"""Preparação de C:\\PromptAuxiliar."""

from __future__ import annotations

import os
from typing import Callable

from app.config import PASTA_BASE, PASTAS_NECESSARIAS

ProgressCallback = Callable[[int, str, int], None]


def preparar_ambiente(on_progress: ProgressCallback | None = None) -> bool:
    criou_algo = False

    def progresso(etapa: int, msg: str, pct: int) -> None:
        if on_progress:
            on_progress(etapa, msg, pct)

    progresso(1, "Verificando diretório base...", 15)
    if not os.path.exists(PASTA_BASE):
        os.makedirs(PASTA_BASE)
        criou_algo = True

    progresso(2, "Verificando subpastas...", 50)
    for pasta in PASTAS_NECESSARIAS:
        caminho = os.path.join(PASTA_BASE, pasta)
        if not os.path.exists(caminho):
            os.makedirs(caminho)
            criou_algo = True

    progresso(3, "Pronto.", 100)
    return criou_algo
