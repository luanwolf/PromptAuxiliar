"""Executa scripts .bat do projeto."""

from __future__ import annotations

import os
import subprocess
import sys

from app.actions import Acao, obter_acao
from app.config import PASTA_BASE


class ScriptNaoEncontradoError(FileNotFoundError):
    pass


def _raiz_projeto() -> str:
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def resolver_script(nome_arquivo: str) -> str:
    candidatos: list[str] = []
    if getattr(sys, "frozen", False):
        candidatos.append(os.path.join(sys._MEIPASS, "scripts", nome_arquivo))
    candidatos.append(os.path.join(_raiz_projeto(), "scripts", nome_arquivo))
    custom = os.path.join(PASTA_BASE, "scripts", nome_arquivo)
    if custom not in candidatos:
        candidatos.append(custom)
    for caminho in candidatos:
        if os.path.isfile(caminho):
            return caminho
    raise ScriptNaoEncontradoError(f"Script '{nome_arquivo}' não encontrado.")


def executar_acao(acao: Acao, *, aguardar: bool = True) -> subprocess.Popen | int:
    caminho = resolver_script(acao.script)
    proc = subprocess.Popen(["cmd", "/c", "start", "", caminho], shell=True)
    if aguardar:
        proc.wait()
        return proc.returncode or 0
    return proc


def executar_por_id(identificador: str, *, aguardar: bool = True) -> subprocess.Popen | int:
    acao = obter_acao(identificador)
    if not acao:
        raise ValueError(f"Ação desconhecida: {identificador}")
    return executar_acao(acao, aguardar=aguardar)
