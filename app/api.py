"""Bridge Python ↔ WebView — painéis Winget e Debloat."""

from __future__ import annotations

import os
import threading
import webbrowser
from typing import Any

from app.actions import catalogo_para_json, obter_acao
from app.config import APP_VERSION, CREDITOS_URL, GITHUB_RELEASES, PASTA_BASE
from app.environment import preparar_ambiente
from app.panels import get_panel, run_panel, write_selected_ids
from app.runner import ScriptNaoEncontradoError, executar_acao


class PromptAuxiliarApi:
    def __init__(self) -> None:
        self._busy = False
        self._lock = threading.Lock()

    def initialize(self) -> dict[str, Any]:
        try:
            primeira_vez = preparar_ambiente()
            return {
                "ok": True,
                "version": APP_VERSION,
                "pasta": PASTA_BASE,
                "primeira_vez": primeira_vez,
                "message": "Ambiente pronto.",
            }
        except Exception as e:
            return {"ok": False, "message": str(e)}

    def open_data_folder(self) -> dict[str, Any]:
        if os.path.isdir(PASTA_BASE):
            os.startfile(PASTA_BASE)
            return {"ok": True, "message": "Pasta aberta."}
        return {"ok": False, "message": f"Pasta não encontrada: {PASTA_BASE}"}

    def get_catalog(self) -> dict[str, Any]:
        data = catalogo_para_json()
        data["meta"] = {
            "version": APP_VERSION,
            "pasta": PASTA_BASE,
            "creditos": CREDITOS_URL,
            "releases": GITHUB_RELEASES,
        }
        return data

    def run_action(self, action_id: str) -> dict[str, Any]:
        acao = obter_acao(action_id)
        if not acao:
            return {"ok": False, "message": f"Ação desconhecida: {action_id}"}
        with self._lock:
            if self._busy:
                return {"ok": False, "message": "Aguarde — outra operação em execução."}
            self._busy = True

        def worker() -> None:
            try:
                executar_acao(acao, aguardar=False)
            finally:
                with self._lock:
                    self._busy = False

        try:
            threading.Thread(target=worker, daemon=True).start()
            return {"ok": True, "message": f"{acao.nome} iniciado.", "action": acao.id}
        except ScriptNaoEncontradoError as e:
            with self._lock:
                self._busy = False
            return {"ok": False, "message": str(e)}

    def open_link(self, kind: str) -> dict[str, Any]:
        urls = {"releases": GITHUB_RELEASES, "creditos": CREDITOS_URL}
        url = urls.get(kind)
        if not url:
            return {"ok": False, "message": "Link inválido."}
        webbrowser.open(url)
        return {"ok": True, "message": "Link aberto no navegador."}

    def get_winget_panel(self) -> dict[str, Any]:
        try:
            preparar_ambiente()
            return {"ok": True, **get_panel("winget")}
        except Exception as e:
            return {"ok": False, "message": str(e)}

    def get_debloat_panel(self) -> dict[str, Any]:
        try:
            preparar_ambiente()
            return {"ok": True, **get_panel("debloat")}
        except Exception as e:
            return {"ok": False, "message": str(e)}

    def save_winget_selection(self, ids: list[str]) -> dict[str, Any]:
        try:
            write_selected_ids("winget", ids)
            return {"ok": True, "message": f"{len(ids)} pacote(s) salvos."}
        except Exception as e:
            return {"ok": False, "message": str(e)}

    def save_debloat_selection(self, ids: list[str]) -> dict[str, Any]:
        try:
            write_selected_ids("debloat", ids)
            return {"ok": True, "message": f"{len(ids)} app(s) salvos."}
        except Exception as e:
            return {"ok": False, "message": str(e)}

    def run_winget_install(self, ids: list[str] | None = None) -> dict[str, Any]:
        with self._lock:
            if self._busy:
                return {"ok": False, "message": "Aguarde — outra operação em execução."}
            self._busy = True
        try:
            if ids:
                write_selected_ids("winget", ids)
            return run_panel("winget", ids)
        except Exception as e:
            return {"ok": False, "message": str(e)}
        finally:
            with self._lock:
                self._busy = False

    def run_debloat(self, ids: list[str] | None = None) -> dict[str, Any]:
        with self._lock:
            if self._busy:
                return {"ok": False, "message": "Aguarde — outra operação em execução."}
            self._busy = True
        try:
            if ids:
                write_selected_ids("debloat", ids)
            return run_panel("debloat", ids)
        except Exception as e:
            return {"ok": False, "message": str(e)}
        finally:
            with self._lock:
                self._busy = False
