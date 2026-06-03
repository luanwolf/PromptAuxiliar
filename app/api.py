"""Bridge Python ↔ WebView — painéis Winget, Debloat e Tweaks."""

from __future__ import annotations

import os
import threading
import webbrowser
from typing import Any

from app.actions import catalogo_para_json, obter_acao
from app.config import APP_VERSION, CREDITOS_URL, PASTA_BASE, PASTA_LOGS
from app.environment import preparar_ambiente
from app.uninstall import paths_for_display, schedule_uninstall
from app.updater import check_for_update, get_local_version, launch_win_ps1_update
from app.panels import get_panel, run_panel, write_selected_ids
from app.tweaks import apply_tweaks, detect_all, get_tweaks_catalog
from app.ui_settings import (
    get_scripts_layout,
    get_theme,
    get_utils_layout,
    set_scripts_layout,
    set_theme,
    set_utils_layout,
)
from app.winget_installed import prefetch_installed_scan
from app.runner import ScriptNaoEncontradoError, executar_acao, usa_powershell_admin


class PromptAuxiliarApi:
    def __init__(self) -> None:
        self._busy = False
        self._lock = threading.Lock()

    def initialize(self) -> dict[str, Any]:
        try:
            primeira_vez = preparar_ambiente()
            prefetch_installed_scan()
            local = get_local_version()
            return {
                "ok": True,
                "version": local,
                "pasta": PASTA_BASE,
                "primeira_vez": primeira_vez,
                "message": "Ambiente pronto.",
                "theme": get_theme(),
                "scripts_layout": get_scripts_layout(),
                "utils_layout": get_utils_layout(),
                "update_available": False,
                "update_message": "",
                "remote_version": None,
                "local_version": local,
            }
        except Exception as e:
            return {"ok": False, "message": str(e)}

    def open_data_folder(self) -> dict[str, Any]:
        if os.path.isdir(PASTA_BASE):
            os.startfile(PASTA_BASE)
            return {"ok": True, "message": "Pasta aberta."}
        return {"ok": False, "message": f"Pasta não encontrada: {PASTA_BASE}"}

    def open_logs_folder(self) -> dict[str, Any]:
        os.makedirs(PASTA_LOGS, exist_ok=True)
        os.startfile(PASTA_LOGS)
        return {"ok": True, "message": "Pasta de logs aberta."}

    def get_catalog(self) -> dict[str, Any]:
        data = catalogo_para_json()
        data["meta"] = {
            "version": get_local_version(),
            "pasta": PASTA_BASE,
            "creditos": CREDITOS_URL,
        }
        return data

    def pick_folder(self) -> dict[str, Any]:
        """Abre seletor nativo de pasta do Windows."""
        try:
            import tkinter as tk
            from tkinter import filedialog

            root = tk.Tk()
            root.withdraw()
            root.attributes("-topmost", True)
            root.update()
            pasta = filedialog.askdirectory(title="Escolha a pasta de destino")
            root.destroy()
            if pasta:
                return {"ok": True, "path": pasta}
            return {"ok": False, "message": "Nenhuma pasta selecionada."}
        except Exception as e:
            return {"ok": False, "message": str(e)}

    def run_action(self, action_id: str) -> dict[str, Any]:
        return self._run_action_impl(action_id, None)

    def run_action_params(self, action_id: str, params: dict[str, Any]) -> dict[str, Any]:
        """Executa ação com parâmetros (URL, pasta, modo) vindos do modal Utilitários."""
        clean: dict[str, str] = {}
        if isinstance(params, dict):
            for key in ("url", "dest", "mode"):
                val = params.get(key)
                if val is not None and str(val).strip():
                    clean[key] = str(val).strip()
        return self._run_action_impl(action_id, clean or None)

    def _run_action_impl(
        self, action_id: str, params: dict[str, str] | None
    ) -> dict[str, Any]:
        acao = obter_acao(action_id)
        if not acao:
            return {"ok": False, "message": f"Ação desconhecida: {action_id}"}
        if params and acao.interativo != "util":
            return {"ok": False, "message": "Esta ação não aceita parâmetros."}
        if acao.interativo == "util":
            if not params or not params.get("url") or not params.get("dest"):
                return {
                    "ok": False,
                    "message": "Informe o link e a pasta de destino.",
                }
            if acao.id == "baixar-ytdlp" and params.get("mode") not in ("video", "audio"):
                return {"ok": False, "message": "Escolha vídeo ou áudio."}

        with self._lock:
            if self._busy:
                return {"ok": False, "message": "Aguarde — outra operação em execução."}
            self._busy = True

        def worker() -> None:
            try:
                executar_acao(acao, aguardar=False, params=params)
            finally:
                with self._lock:
                    self._busy = False

        try:
            threading.Thread(target=worker, daemon=True).start()
            msg = (
                f"{acao.nome} — PowerShell (admin) iniciado."
                if usa_powershell_admin(acao.id)
                else f"{acao.nome} iniciado."
            )
            return {"ok": True, "message": msg, "action": acao.id}
        except ScriptNaoEncontradoError as e:
            with self._lock:
                self._busy = False
            return {"ok": False, "message": str(e)}

    def get_ui_settings(self) -> dict[str, Any]:
        try:
            preparar_ambiente()
            return {
                "ok": True,
                "theme": get_theme(),
                "scripts_layout": get_scripts_layout(),
                "utils_layout": get_utils_layout(),
            }
        except Exception as e:
            return {
                "ok": False,
                "message": str(e),
                "theme": "dark",
                "scripts_layout": "grid",
                "utils_layout": "grid",
            }

    def save_ui_theme(self, theme: str) -> dict[str, Any]:
        try:
            preparar_ambiente()
            saved = set_theme(theme)
            return {"ok": True, "theme": saved}
        except Exception as e:
            return {"ok": False, "message": str(e)}

    def save_scripts_layout(self, layout: str) -> dict[str, Any]:
        try:
            preparar_ambiente()
            saved = set_scripts_layout(layout)
            return {"ok": True, "scripts_layout": saved}
        except Exception as e:
            return {"ok": False, "message": str(e)}

    def save_utils_layout(self, layout: str) -> dict[str, Any]:
        try:
            preparar_ambiente()
            saved = set_utils_layout(layout)
            return {"ok": True, "utils_layout": saved}
        except Exception as e:
            return {"ok": False, "message": str(e)}

    def check_for_updates(self) -> dict[str, Any]:
        """Consulta APP_VERSION no GitHub (branch main) e compara com a instalação local."""
        try:
            return check_for_update()
        except Exception as e:
            return {"ok": False, "message": str(e)}

    def launch_app_update(self) -> dict[str, Any]:
        """Inicia win.ps1 remoto no PowerShell e fecha o app."""
        try:
            launch_win_ps1_update()
            threading.Timer(0.5, self._quit_app).start()
            return {
                "ok": True,
                "message": "Atualização iniciada no PowerShell. Esta janela será fechada.",
            }
        except Exception as e:
            return {"ok": False, "message": str(e)}

    def get_uninstall_preview(self) -> dict[str, Any]:
        return {"ok": True, "paths": paths_for_display()}

    def uninstall_prompt_auxiliar(self) -> dict[str, Any]:
        try:
            threading.Timer(0.2, self._quit_app).start()
            schedule_uninstall()
            return {
                "ok": True,
                "message": "Exclusão agendada. O aplicativo será fechado em instantes.",
            }
        except Exception as e:
            return {"ok": False, "message": str(e)}

    def _quit_app(self) -> None:
        try:
            import webview

            for window in webview.windows:
                window.destroy()
        except Exception:
            pass

    def open_link(self, kind: str) -> dict[str, Any]:
        urls = {"creditos": CREDITOS_URL}
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

    def get_tweaks(self) -> dict[str, Any]:
        """Retorna catálogo de tweaks sem detecção (resposta imediata)."""
        try:
            return get_tweaks_catalog()
        except Exception as e:
            return {"ok": False, "message": str(e)}

    def detect_tweaks(self) -> dict[str, Any]:
        """Executa PowerShell para detectar o estado atual de cada tweak."""
        try:
            return detect_all()
        except Exception as e:
            return {"ok": False, "message": str(e), "states": {}}

    def apply_tweaks(self, ids: list[str]) -> dict[str, Any]:
        """Aplica os tweaks selecionados via PS1 temporário em nova janela."""
        try:
            return apply_tweaks(ids)
        except Exception as e:
            return {"ok": False, "message": str(e)}

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
