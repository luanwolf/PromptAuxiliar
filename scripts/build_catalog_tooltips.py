"""Gera app/data/catalog_tooltips.json com descrições só do programa."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "app" / "data"

# Textos detalhados (só sobre o software / app — sem Winget, IDs ou Prompt Auxiliar)
EXTRA: dict[str, str] = {
    "Foxit.FoxitReader": (
        "É uma popular família de softwares e ferramentas para criar, visualizar, editar e "
        "gerenciar arquivos PDF. O Foxit PDF Reader é a versão gratuita: leve, rápida e "
        "adequada para leitura diária de documentos."
    ),
    "Adobe.Acrobat.Reader.64-bit": (
        "Leitor oficial da Adobe para PDF. Abre, imprime, assina e comenta documentos; "
        "amplamente usado em empresas. A versão Reader é gratuita."
    ),
    "TheDocumentFoundation.LibreOffice": (
        "Suíte office gratuita com Writer, Calc, Impress e Draw. Compatível com arquivos "
        "Microsoft Office e alternativa completa ao pacote Office pago."
    ),
    "Microsoft.PowerToys": (
        "Utilitários oficiais da Microsoft: FancyZones, renomeação em lote, pré-visualização "
        "de arquivos, atalhos extras e outras ferramentas para usuários avançados."
    ),
    "Google.Chrome": (
        "Navegador da Google baseado em Chromium. Sincroniza favoritos e senhas, suporta "
        "extensões e é um dos navegadores mais usados no mundo."
    ),
    "Anysphere.Cursor": (
        "Editor de código com IA integrada, baseado no VS Code. Autocomplete inteligente, "
        "chat com o projeto e refatoração assistida."
    ),
    "Ollama.Ollama": (
        "Executa modelos de linguagem localmente no PC. Baixa e roda LLMs sem depender "
        "apenas de serviços na nuvem."
    ),
    "TechPowerUp.GPU-Z": (
        "Mostra informações da placa de vídeo: modelo, BIOS, driver, clocks e sensores "
        "em tempo real."
    ),
    "CodecGuide.K-LiteCodecPack.Standard": (
        "Pacote de codecs e filtros para reproduzir a maioria dos formatos de vídeo e áudio "
        "no Windows, inclusive com players como MPC-HC."
    ),
    "7zip.7zip": (
        "Compactador open-source. Abre e cria ZIP, 7z, RAR e muitos outros formatos com "
        "alta compressão."
    ),
    "Valve.Steam": (
        "Loja e launcher de jogos para PC: compras, downloads, atualizações, nuvem de saves "
        "e comunidade."
    ),
    "Microsoft.BingNews_8wekyb3d8bbwe": (
        "Feed de notícias Bing/MSN integrado ao Windows. Exibe manchetes e widgets de notícias."
    ),
    "Microsoft.GamingApp_8wekyb3d8bbwe": (
        "App Xbox no Windows: biblioteca de jogos, PC Game Pass, capturas e recursos sociais."
    ),
    "Microsoft.WindowsStore_8wekyb3d8bbwe": (
        "Loja oficial de aplicativos do Windows. Necessária para instalar e atualizar muitos apps UWP."
    ),
}


def _plain(descricao: str) -> str:
    return descricao.strip()


def main() -> None:
    out: dict[str, str] = dict(EXTRA)

    winget = json.loads((DATA / "winget_catalog.json").read_text(encoding="utf-8"))
    for item in winget["itens"]:
        pid = item["id"]
        if pid not in out:
            out[pid] = _plain(item.get("descricao", ""))

    debloat = json.loads((DATA / "debloat_catalog.json").read_text(encoding="utf-8"))
    for item in debloat["itens"]:
        pid = item["id"]
        if pid not in out:
            out[pid] = _plain(item.get("descricao", ""))

    TOOLTIPS_FILE = DATA / "catalog_tooltips.json"
    TOOLTIPS_FILE.write_text(
        json.dumps(out, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"catalog_tooltips.json: {len(out)} entradas")


if __name__ == "__main__":
    main()
