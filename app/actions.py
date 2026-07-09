"""Catálogo de ações — Web UI, CLI e scripts .bat."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Iterator, Literal

NivelRisco = Literal["normal", "aviso", "perigo"]


@dataclass(frozen=True)
class Acao:
    id: str
    nome: str
    script: str
    categoria: str
    descricao: str
    icone: str
    nivel_risco: NivelRisco = "normal"


_ACOES: tuple[Acao, ...] = (
    Acao("atualizar-programas", "Atualizar programas", "atualizar_softwares.bat", "Instalação", "Atualiza programas via Winget.", "arrow-sync"),
    Acao("instalar-software", "Instalar da pasta Software", "instalar_software.bat", "Instalação", "Instala .exe, .msi e .lnk da pasta softwares.", "folder-open"),
    Acao("limpeza-temporarios", "Limpeza de temporários", "limpeza_temporarios.bat", "Limpeza", "Remove temporários, lixeira e cache.", "broom"),
    Acao("limpeza-disco", "Limpeza de armazenamento", "limpeza_disco.bat", "Limpeza", "Abre a Limpeza de Disco do Windows.", "storage"),
    Acao("limpeza-malware", "Limpeza MRT (malware)", "limpeza_malware.bat", "Limpeza", "Executa a Ferramenta MRT.", "shield"),
    Acao("limpeza-profunda", "Limpeza profunda do Windows", "limpeza_profunda.bat", "Limpeza", "TEMP, prefetch, DNS, cleanmgr, SFC e DISM.", "sparkle"),
    Acao("aplicar-registro", "Aplicar ajustes de registro", "aplicar_ajustes.bat", "Otimização", "Aplica .reg da pasta registros.", "registry", "aviso"),
    Acao("utilitario-externo", "Utilitário Windows (externo)", "windows_utility.bat", "Otimização", "WinUtil Chris Titus (terceiros).", "plug", "perigo"),
    Acao("ativar-office-kms", "Ativar Office (KMS)", "ativar_office_kms.bat", "Sistema", "Ativação Office — use por sua conta e risco.", "key", "perigo"),
    Acao("ativar-windows-kms", "Ativar Windows (KMS)", "ativar_windows_kms.bat", "Sistema", "Ativação Windows — use por sua conta e risco.", "key", "perigo"),
    Acao("ativar-windows-slmgr", "Ativar Windows (slmgr)", "ativar_windows.bat", "Sistema", "slmgr /ato.", "key", "perigo"),
    Acao("criar-atalhos", "Criar atalhos (GodMode e BIOS)", "criar_atalhos.bat", "Sistema", "GodMode e atalho reinício BIOS.", "desktop"),
    Acao("alternar-contexto", "Alternar menu de contexto", "alternar_contexto.bat", "Sistema", "Menu clássico Win10 ou moderno Win11.", "cursor"),
    Acao("gerenciar-inicializacao", "Apps de inicialização", "gerenciar_inicializacao.bat", "Sistema", "Configurações de inicialização.", "rocket"),
    Acao("reparar-rede", "Reparar conexão de rede", "reparar_rede.bat", "Sistema", "IP, DNS, Winsock e TCP/IP.", "wifi"),
)

_POR_ID = {a.id: a for a in _ACOES}
_POR_SCRIPT = {a.script: a for a in _ACOES}

_META_CATEGORIAS: dict[str, dict[str, str]] = {
    "Instalação": {"slug": "instalacao", "icone": "install", "descricao": "Atualização e instaladores locais"},
    "Limpeza": {"slug": "limpeza", "icone": "clean", "descricao": "Temporários, disco e segurança"},
    "Otimização": {"slug": "otimizacao", "icone": "tune", "descricao": "Registro e ajustes"},
    "Sistema": {"slug": "sistema", "icone": "system", "descricao": "Rede, atalhos e configurações"},
}


def listar_acoes() -> list[Acao]:
    return list(_ACOES)


def obter_acao(identificador: str) -> Acao | None:
    chave = identificador.strip().lower()
    if chave in _POR_ID:
        return _POR_ID[chave]
    if chave.endswith(".bat") and chave in _POR_SCRIPT:
        return _POR_SCRIPT[chave]
    if not chave.endswith(".bat"):
        script = f"{chave.replace('-', '_')}.bat"
        return _POR_SCRIPT.get(script)
    return None


def obter_acoes_por_categoria(categoria: str) -> list[Acao]:
    return [a for a in _ACOES if a.categoria == categoria]


def iterar_categorias() -> Iterator[str]:
    vistos: set[str] = set()
    for acao in _ACOES:
        if acao.categoria not in vistos:
            vistos.add(acao.categoria)
            yield acao.categoria


def acao_para_dict(acao: Acao) -> dict[str, Any]:
    return {
        "id": acao.id,
        "nome": acao.nome,
        "script": acao.script,
        "categoria": acao.categoria,
        "descricao": acao.descricao,
        "icone": acao.icone,
        "risco": acao.nivel_risco,
    }


def catalogo_para_json() -> dict[str, Any]:
    categorias = []
    for nome in iterar_categorias():
        meta = _META_CATEGORIAS.get(nome, {})
        categorias.append(
            {
                "nome": nome,
                "slug": meta.get("slug", nome.lower()),
                "icone": meta.get("icone", "grid"),
                "descricao": meta.get("descricao", ""),
                "total": len(obter_acoes_por_categoria(nome)),
            }
        )
    return {"categorias": categorias, "acoes": [acao_para_dict(a) for a in _ACOES]}
