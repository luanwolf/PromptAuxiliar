"""Tweaks do Windows — detecção de estado e aplicação via PowerShell."""

from __future__ import annotations

import ctypes
import json
import os
import subprocess
import sys
import uuid
from pathlib import Path
from typing import Any

from app.config import PASTA_LOGS
from app.runner import PS_CONSOLE_INIT

_PS_RUN = Path(os.environ.get("TEMP", ".")) / "PromptAuxiliar" / "run"
_CATALOG_REL = Path(__file__).parent / "data" / "tweaks_catalog.json"


def _catalog_path() -> Path:
    if getattr(sys, "frozen", False):
        return Path(sys._MEIPASS) / "app" / "data" / "tweaks_catalog.json"
    return _CATALOG_REL


def _load_catalog() -> dict[str, Any]:
    with open(_catalog_path(), encoding="utf-8") as f:
        return json.load(f)


def get_tweaks_catalog() -> dict[str, Any]:
    """Retorna o catálogo sem executar detecção (resposta imediata)."""
    catalog = _load_catalog()
    items = [
        {
            "id": tw["id"],
            "label": tw["label"],
            "descricao": tw.get("descricao", ""),
            "categoria": tw.get("categoria", ""),
            "aplicado": None,
            "requer_admin": bool(tw.get("requer_admin", False)),
            "requer_reiniciar": bool(tw.get("requer_reiniciar", False)),
        }
        for tw in catalog["tweaks"]
    ]
    return {
        "ok": True,
        "categorias": catalog["categorias"],
        "tweaks": items,
    }


def _build_detect_script(tweaks: list[dict[str, Any]]) -> str:
    lines = ["$ErrorActionPreference = 'SilentlyContinue'", "$r = @{}"]
    for tw in tweaks:
        tid = tw["id"]
        detect = tw.get("detect", "")
        if detect:
            lines.append(
                f"try {{ $r['{tid}'] = [bool]({detect}) }} catch {{ $r['{tid}'] = $false }}"
            )
        else:
            lines.append(f"$r['{tid}'] = $null")
    lines.append("$r | ConvertTo-Json -Compress")
    return "\n".join(lines)


def detect_all() -> dict[str, Any]:
    """Executa PowerShell para detectar o estado atual de todos os tweaks."""
    catalog = _load_catalog()
    tweaks = catalog["tweaks"]

    ps_script = _build_detect_script(tweaks)

    _PS_RUN.mkdir(parents=True, exist_ok=True)
    ps1 = _PS_RUN / f"detect_{uuid.uuid4().hex}.ps1"
    try:
        ps1.write_text(ps_script, encoding="utf-8-sig")
        result = subprocess.run(
            [
                "powershell.exe",
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ps1),
            ],
            capture_output=True,
            text=True,
            timeout=25,
        )
        raw = result.stdout.strip()
        if result.returncode == 0 and raw:
            states: dict[str, bool | None] = json.loads(raw)
            return {"ok": True, "states": states}
        return {"ok": True, "states": {tw["id"]: None for tw in tweaks}}
    except Exception as exc:
        return {"ok": False, "message": str(exc), "states": {tw["id"]: None for tw in tweaks}}
    finally:
        try:
            ps1.unlink(missing_ok=True)
        except OSError:
            pass


def _build_apply_script(
    selected: list[dict[str, Any]],
    needs_restart: bool,
) -> str:
    """Gera o script PowerShell para aplicar os tweaks selecionados.
    A elevação de admin é feita pelo Python antes de chamar este script.
    """
    lines: list[str] = [PS_CONSOLE_INIT.strip(), ""]

    lines += [
        "$Host.UI.RawUI.WindowTitle = 'Prompt Auxiliar - Tweaks'",
        "$startTime = Get-Date",
        "$results   = [System.Collections.ArrayList]::new()",
        "$restart_explorer = $false",
        "",
        "Write-Host ''",
        "Write-Host '  ================================================' -ForegroundColor DarkCyan",
        "Write-Host '    PROMPT AUXILIAR  |  Tweaks Windows' -ForegroundColor Cyan",
        f"Write-Host '    {len(selected)} ajuste(s) selecionado(s)' -ForegroundColor DarkGray",
        "Write-Host '  ================================================' -ForegroundColor DarkCyan",
        "Write-Host ''",
        "",
    ]

    for tw in selected:
        safe_label = tw["label"].replace("'", "''")
        lines.append(f"# ---- {safe_label}")
        lines.append(f"Write-Host '  -> {safe_label}...' -ForegroundColor Gray")
        lines.append("$_twOk = $true; $_twMsg = ''")
        for step in tw.get("apply", []):
            lines.append(
                f"if ($_twOk) {{ try {{ {step} }}"
                f" catch {{ $_twOk = $false; $_twMsg = $_.Exception.Message;"
                f" Write-Host \"     ERRO: $_twMsg\" -ForegroundColor Red }} }}"
            )
        if tw.get("restart_explorer"):
            lines.append("$restart_explorer = $true")
        lines += [
            f"[void]$results.Add(@{{ Label='{safe_label}'; Ok=$_twOk; Msg=$_twMsg }})",
            "if ($_twOk) { Write-Host '     OK' -ForegroundColor DarkGreen }",
            "",
        ]

    lines += [
        "# ---- Explorer restart",
        "if ($restart_explorer) {",
        "    Write-Host ''",
        "    Write-Host '  Reiniciando Explorer...' -ForegroundColor DarkGray",
        "    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue",
        "    Start-Sleep -Milliseconds 800",
        "    Start-Process explorer",
        "    Write-Host '  Explorer reiniciado.' -ForegroundColor DarkGray",
        "}",
        "",
        "# ---- Log consolidado",
        "$elapsed  = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)",
        "$okCount  = ($results | Where-Object { $_.Ok }).Count",
        "$errCount = ($results | Where-Object { -not $_.Ok }).Count",
        "",
        "Write-Host ''",
        "Write-Host '  ================================================' -ForegroundColor DarkCyan",
        "Write-Host '   RESUMO DOS AJUSTES APLICADOS' -ForegroundColor Cyan",
        "Write-Host '  ================================================' -ForegroundColor DarkCyan",
        "foreach ($r in $results) {",
        "    if ($r.Ok) {",
        "        Write-Host \"   [OK]   $($r.Label)\" -ForegroundColor Green",
        "    } else {",
        "        Write-Host \"   [ERRO] $($r.Label)\" -ForegroundColor Red",
        "        if ($r.Msg) { Write-Host \"         $($r.Msg)\" -ForegroundColor DarkRed }",
        "    }",
        "}",
        "Write-Host '  ------------------------------------------------' -ForegroundColor DarkCyan",
        "if ($errCount -gt 0) {",
        "    Write-Host \"   Resultado: $okCount OK  |  $errCount erro(s)  |  Tempo: ${elapsed}s\" -ForegroundColor Yellow",
        "} else {",
        "    Write-Host \"   Resultado: $okCount ajuste(s) aplicado(s) com sucesso  |  Tempo: ${elapsed}s\" -ForegroundColor Green",
        "}",
        "Write-Host '  ================================================' -ForegroundColor DarkCyan",
        "",
        "# ---- Salvar log em arquivo",
        r"$logDir = 'C:\PromptAuxiliar\logs'",
        "if (-not (Test-Path $logDir)) { New-Item $logDir -ItemType Directory -Force | Out-Null }",
        "$logFile = Join-Path $logDir \"tweaks-$(Get-Date -Format 'yyyyMMdd-HHmmss').log\"",
        "$logLines = @(",
        "    'Prompt Auxiliar - Log de Tweaks'",
        "    \"Data   : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')\"",
        "    \"Duração: ${elapsed}s\"",
        "    \"Usuário: $env:USERNAME\"",
        "    ''",
        "    '---- Ajustes ----'",
        ")",
        "foreach ($r in $results) {",
        "    $st = if ($r.Ok) { '[OK]  ' } else { '[ERRO]' }",
        "    $logLines += \"$st  $($r.Label)\"",
        "    if (-not $r.Ok -and $r.Msg) { $logLines += \"       Detalhe: $($r.Msg)\" }",
        "}",
        "$logLines += ''",
        "$logLines += \"Total: $okCount OK  |  $errCount erro(s)\"",
        "$logLines | Out-File -FilePath $logFile -Encoding UTF8 -ErrorAction SilentlyContinue",
        "Write-Host ''",
        "Write-Host \"  Log salvo em: $logFile\" -ForegroundColor DarkGray",
    ]

    if needs_restart:
        lines += [
            "",
            "Write-Host ''",
            "Write-Host '  ATENÇÃO: reinicie o computador para que todos os ajustes tenham efeito.' -ForegroundColor Yellow",
        ]

    lines += [
        "",
        "Write-Host ''",
        "Read-Host '  Pressione Enter para fechar'",
    ]

    return "\n".join(lines)


def apply_tweaks(ids: list[str]) -> dict[str, Any]:
    """Cria um script PS1 temporário com os ajustes selecionados e o executa."""
    catalog = _load_catalog()
    by_id = {tw["id"]: tw for tw in catalog["tweaks"]}
    selected = [by_id[i] for i in ids if i in by_id]

    if not selected:
        return {"ok": False, "message": "Nenhum ajuste selecionado."}

    needs_admin   = any(tw.get("requer_admin")    for tw in selected)
    needs_restart = any(tw.get("requer_reiniciar") for tw in selected)

    ps_script = _build_apply_script(selected, needs_restart)

    _PS_RUN.mkdir(parents=True, exist_ok=True)
    Path(PASTA_LOGS).mkdir(parents=True, exist_ok=True)
    ps1 = _PS_RUN / f"tweaks_{uuid.uuid4().hex}.ps1"
    ps1.write_text(ps_script, encoding="utf-8-sig")

    ps_args = f'-NoProfile -ExecutionPolicy Bypass -File "{ps1}"'

    if needs_admin and sys.platform == "win32":
        # Solicita elevação diretamente do Python via ShellExecuteW (mais confiável que auto-elevação no PS1)
        ret = ctypes.windll.shell32.ShellExecuteW(
            None, "runas", "powershell.exe", ps_args, None, 1
        )
        if ret <= 32:
            return {
                "ok": False,
                "message": (
                    f"Não foi possível iniciar o PowerShell como administrador (código {ret}). "
                    "Verifique se o UAC está habilitado e tente novamente."
                ),
            }
    else:
        flags = getattr(subprocess, "CREATE_NEW_CONSOLE", 0x00000010)
        subprocess.Popen(f'powershell.exe {ps_args}', creationflags=flags)

    return {
        "ok": True,
        "message": f"{len(selected)} ajuste(s) em aplicação."
        + (" (UAC solicitado)" if needs_admin else ""),
    }
