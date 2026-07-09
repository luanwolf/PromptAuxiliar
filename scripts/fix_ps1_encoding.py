"""Garante UTF-8-BOM e restaura acentos comuns nos .ps1/.bat (Windows PowerShell 5.1 e CMD)."""

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

# ponytail: substituições de palavras — só termos de interface, não URLs/comandos.
WORD_FIXES: tuple[tuple[str, str], ...] = (
    (r"\bATENCAO\b", "ATENÇÃO"),
    (r"\bNao\b", "Não"),
    (r"\bnao\b", "não"),
    (r"\boperacao\b", "operação"),
    (r"\bOperacao\b", "Operação"),
    (r"\bOpcao\b", "Opção"),
    (r"\bcodigo\b", "código"),
    (r"\bmusica\b", "música"),
    (r"\balteracoes\b", "alterações"),
    (r"\bconcluido\b", "concluído"),
    (r"\bConcluido\b", "Concluído"),
    (r"\bconcluida\b", "concluída"),
    (r"\binvalida\b", "inválida"),
    (r"\bVerificacao\b", "Verificação"),
    (r"\bConfiguracoes\b", "Configurações"),
    (r"\bconfiguracoes\b", "configurações"),
    (r"\bexecucao\b", "execução"),
    (r"\bExecucao\b", "Execução"),
    (r"\bsensivel\b", "sensível"),
    (r"\bDuracao\b", "Duração"),
    (r"\bUsuario\b", "Usuário"),
    (r"\binstalacao\b", "instalação"),
    (r"\bInstalacao\b", "Instalação"),
    (r"\btemporarios\b", "temporários"),
    (r"\bconexao\b", "conexão"),
    (r"\bativacao\b", "ativação"),
    (r"\binicializacao\b", "inicialização"),
    (r"\bpos-troca\b", "pós-troca"),
    (r"\bPos-troca\b", "Pós-troca"),
    (r"\bversao\b", "versão"),
    (r"\batualizacao\b", "atualização"),
    (r"\bdisponivel\b", "disponível"),
    (r"\bfaca\b", "faça"),
    (r"\bsessao\b", "sessão"),
    (r"\bSessao\b", "Sessão"),
    (r"\btecnica\b", "técnica"),
)


def normalize_ps1(text: str) -> str:
    for old, new in REPLACEMENTS.items():
        text = text.replace(old, new)
    for pattern, repl in WORD_FIXES:
        text = re.sub(pattern, repl, text)
    if text.startswith("\ufeff"):
        text = text.lstrip("\ufeff")
    return text.replace("\r\n", "\n").replace("\n", "\r\n")


def main() -> None:
    targets: list[Path] = []
    for pattern in ("*.ps1", "*.bat"):
        targets.extend(
            p for p in ROOT.rglob(pattern) if ".git" not in p.parts
        )
    for path in sorted(set(targets)):
        raw = path.read_bytes()
        if raw.startswith(b"\xef\xbb\xbf"):
            raw = raw[3:]
        text = normalize_ps1(raw.decode("utf-8", errors="replace"))
        encoded = text.encode("utf-8")
        if path.suffix.lower() == ".ps1":
            path.write_bytes(b"\xef\xbb\xbf" + encoded)
        else:
            path.write_bytes(encoded)
        print(f"OK {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
