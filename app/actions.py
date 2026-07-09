"""Catálogo de ações — Web UI, CLI e scripts .ps1/.bat."""

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
    interativo: str | None = None  # "util" = modal URL, pasta e opções no app


_ACOES: tuple[Acao, ...] = (
    Acao("atualizar-programas", "Atualizar programas", "atualizar_softwares.ps1", "Instalação", "Atualiza programas via Winget.", "arrow-sync"),
    Acao("instalar-software", "Instalar da pasta Software", "instalar_software.ps1", "Instalação", "Instala .exe, .msi e .lnk da pasta softwares.", "folder-open"),
    Acao(
        "instalar-vcredist-aio",
        "Visual C++ Runtimes (All-in-One)",
        "instalar_runtimes.ps1",
        "Instalação",
        "Instala o pacote AIO de Visual C++ Redistributables (abbodi1406) via Winget.",
        "package",
    ),
    Acao("limpeza-temporarios", "Limpeza de temporários", "limpeza_temporarios.ps1", "Limpeza", "Remove temporários, lixeira e cache.", "broom"),
    Acao("limpeza-disco", "Limpeza de armazenamento", "limpeza_disco.ps1", "Limpeza", "Abre a Limpeza de Disco do Windows.", "storage"),
    Acao("limpeza-malware", "Limpeza MRT (malware)", "limpeza_malware.ps1", "Limpeza", "Executa a Ferramenta MRT.", "shield"),
    Acao("limpeza-profunda", "Limpeza profunda do Windows", "limpeza_profunda.ps1", "Limpeza", "TEMP, prefetch, DNS, cleanmgr, SFC e DISM.", "sparkle"),
    Acao("aplicar-registro", "Aplicar ajustes de registro", "aplicar_ajustes.ps1", "Otimização", "Aplica .reg da pasta registros.", "registry", "aviso"),
    Acao("utilitario-externo", "Utilitário Windows (externo)", "windows_utility.bat", "Otimização", "WinUtil Chris Titus (terceiros).", "plug", "perigo"),
    Acao("ativar-office-kms", "Ativar Office (KMS)", "ativar_office_kms.bat", "Sistema", "Ativação Office — use por sua conta e risco.", "key", "perigo"),
    Acao("ativar-windows-kms", "Ativar Windows (KMS)", "ativar_windows_kms.bat", "Sistema", "Ativação Windows — use por sua conta e risco.", "key", "perigo"),
    Acao("ativar-windows-slmgr", "Ativar Windows (slmgr)", "ativar_windows.ps1", "Sistema", "slmgr /ato.", "key", "perigo"),
    Acao("criar-atalhos", "Criar atalhos (GodMode e BIOS)", "criar_atalhos.ps1", "Sistema", "GodMode e atalho reinício BIOS.", "desktop"),
    Acao("gerenciar-inicializacao", "Apps de inicialização", "gerenciar_inicializacao.ps1", "Sistema", "Configurações de inicialização.", "rocket"),
    Acao("reparar-rede", "Reparar conexão de rede", "reparar_rede.ps1", "Sistema", "IP, DNS, Winsock e TCP/IP.", "wifi"),
    Acao(
        "baixar-ytdlp",
        "Baixar com yt-dlp",
        "baixar_ytdlp.ps1",
        "Utilitários",
        "Baixa vídeo ou música de YouTube e outros sites (yt-dlp).",
        "download",
        interativo="util",
    ),
    Acao(
        "baixar-spotdl",
        "Baixar do Spotify (spotdl)",
        "baixar_spotdl.ps1",
        "Utilitários",
        "Baixa música ou playlist do Spotify em MP3 (spotdl).",
        "music",
        interativo="util",
    ),
    Acao(
        "converter-imagem",
        "Converter imagem (ImageMagick)",
        "converter_imagem.ps1",
        "Utilitários",
        "Converte imagens entre JPEG, PNG, WebP, GIF, PDF, ICO e outros formatos.",
        "image",
        interativo="util-imagem",
    ),
)

_POR_ID = {a.id: a for a in _ACOES}
_POR_SCRIPT = {a.script: a for a in _ACOES}

_META_CATEGORIAS: dict[str, dict[str, str]] = {
    "Instalação": {"slug": "instalacao", "icone": "install", "descricao": "Atualização e instaladores locais"},
    "Limpeza": {"slug": "limpeza", "icone": "clean", "descricao": "Temporários, disco e segurança"},
    "Otimização": {"slug": "otimizacao", "icone": "tune", "descricao": "Registro e ajustes"},
    "Sistema": {"slug": "sistema", "icone": "system", "descricao": "Rede, atalhos e configurações"},
    "Utilitários": {"slug": "utilitarios", "icone": "tool", "descricao": "Downloads, conversão de imagens e ferramentas"},
}


def obter_acao(identificador: str) -> Acao | None:
    chave = identificador.strip().lower()
    if chave in _POR_ID:
        return _POR_ID[chave]
    # Busca direta pelo nome do script (qualquer extensão)
    if chave in _POR_SCRIPT:
        return _POR_SCRIPT[chave]
    # Tenta derivar o nome do script a partir do ID (ex: "reparar-rede" → "reparar_rede")
    base = chave.replace("-", "_")
    for ext in (".ps1", ".bat"):
        resultado = _POR_SCRIPT.get(f"{base}{ext}")
        if resultado:
            return resultado
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
        "interativo": acao.interativo,
    }


def _chave_nome(item: dict[str, Any] | Acao) -> str:
    nome = item.nome if isinstance(item, Acao) else str(item.get("nome", ""))
    return nome.casefold()


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
    acoes = sorted([acao_para_dict(a) for a in _ACOES], key=_chave_nome)
    return {"categorias": categorias, "acoes": acoes}
