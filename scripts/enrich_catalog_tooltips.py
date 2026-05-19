"""Gera descricao_detalhada nos catálogos Winget e Debloat. Uso: python scripts/enrich_catalog_tooltips.py"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "app" / "data"

# Textos específicos (prioridade sobre o gerador automático)
CUSTOM: dict[str, str] = {
    "Foxit.FoxitReader": (
        "É uma popular família de softwares e ferramentas para criar, visualizar, editar e "
        "gerenciar arquivos PDF. O Foxit PDF Reader é a versão gratuita: leve, rápida e "
        "adequada para leitura diária de documentos sem abrir o pacote completo pago."
    ),
    "Adobe.Acrobat.Reader.64-bit": (
        "Leitor oficial da Adobe para PDF. Abre, imprime, assina e comenta documentos; "
        "amplamente usado em empresas. Versão Reader é gratuita; recursos avançados de "
        "edição exigem o Acrobat Pro."
    ),
    "TheDocumentFoundation.LibreOffice": (
        "Suíte office gratuita e open-source com Writer, Calc, Impress e Draw. "
        "Compatível com formatos Microsoft Office (.docx, .xlsx) e alternativa completa "
        "ao pacote Office pago para uso doméstico e profissional."
    ),
    "Microsoft.PowerToys": (
        "Conjunto oficial de utilitários da Microsoft para power users: FancyZones, "
        "renomeação em lote, pré-visualização de arquivos, atalhos de teclado extras e "
        "mais. Open-source e atualizado com frequência."
    ),
    "Anysphere.Cursor": (
        "Editor de código com IA integrada, baseado no VS Code. Oferece autocomplete "
        "inteligente, chat com o código e refatoração assistida — popular para "
        "desenvolvimento com modelos de linguagem."
    ),
    "Ollama.Ollama": (
        "Executa modelos de linguagem (LLMs) localmente no seu PC, sem depender só da "
        "nuvem. Baixa modelos via terminal e integra com outras ferramentas de IA offline."
    ),
    "TechPowerUp.GPU-Z": (
        "Utilitário gratuito para inspecionar placa de vídeo: modelo, BIOS, driver, clocks "
        "e sensores em tempo real. Referência entre entusiastas e técnicos de hardware."
    ),
    "CodecGuide.K-LiteCodecPack.Standard": (
        "Pacote de codecs e filtros DirectShow para o Windows. A edição Standard cobre "
        "os formatos mais comuns de vídeo e áudio; útil com players como MPC-HC e Windows Media Player."
    ),
    "Microsoft.BingNews_8wekyb3d8bbwe": (
        "App de notícias curadas (Bing/MSN) pré-instalado no Windows. Consome dados e "
        "exibe conteúdo na barra de widgets; removível se você não usa notícias integradas ao sistema."
    ),
    "Microsoft.GamingApp_8wekyb3d8bbwe": (
        "App Xbox moderno no Windows: biblioteca de jogos, Game Pass, gravação e social. "
        "Remover desativa parte da integração Xbox no PC — avalie se você joga na plataforma."
    ),
    "Google.Chrome": (
        "Navegador da Google baseado em Chromium. Sincroniza favoritos e senhas com conta Google, "
        "suporta extensões da Chrome Web Store e é um dos navegadores mais usados no mundo."
    ),
    "7zip.7zip": (
        "Compactador open-source muito usado no Windows. Abre ZIP, 7z, RAR e dezenas de formatos; "
        "alta taxa de compressão e integração ao menu de contexto do Explorer."
    ),
    "Valve.Steam": (
        "Maior loja de jogos para PC: compra, download, atualizações automáticas, nuvem de saves "
        "e comunidade. Quase indispensável para quem joga no computador."
    ),
    "Microsoft.OneDrive": (
        "Sincroniza pastas e arquivos com a nuvem Microsoft. Integrado ao Windows e ao Office; "
        "remover no debloat não apaga arquivos na nuvem, mas desativa sync automático local."
    ),
    "Microsoft.WindowsStore_8wekyb3d8bbwe": (
        "Loja oficial de apps UWP do Windows. Não é recomendado remover: muitas atualizações e "
        "apps do sistema dependem da Microsoft Store para instalação e manutenção."
    ),
}

WINGET_CAT_HINT: dict[str, str] = {
    "Navegadores": "Navegador para acessar sites, favoritos, extensões e downloads na web.",
    "Produtividade": "Ferramenta de produtividade para trabalho, estudo ou organização no Windows.",
    "Desenvolvimento": "Software para programação, versionamento, testes ou infraestrutura de desenvolvimento.",
    "Inteligência artificial": "Ferramenta de IA: assistentes, modelos locais ou integração com LLMs.",
    "Mídia e criatividade": "Software para áudio, vídeo, imagem ou entretenimento multimídia.",
    "Utilitários": "Utilitário do sistema: manutenção, segurança, rede ou produtividade no PC.",
    "Personalização": "Personaliza aparência, tema ou comportamento do Windows.",
    "Sistema e hardware": "Monitora ou ajusta hardware, drivers, desempenho ou estabilidade do sistema.",
    "Runtimes e componentes": "Runtime ou biblioteca exigida por outros programas e jogos no Windows.",
    "Comunicação": "Comunicação por chat, voz ou videoconferência.",
    "Jogos": "Launcher, loja ou ferramenta relacionada a jogos no PC.",
}

DEBLOAT_CAT_HINT: dict[str, str] = {
    "Apps Microsoft": "App UWP/Microsoft Store pré-instalado no Windows.",
    "Xbox e gaming": "Componente ou app da ecossistema Xbox no Windows.",
    "Entretenimento e mídia": "App de entretenimento pré-instalado (vídeo, música ou jogos casuais).",
    "Comunicação": "App de comunicação pré-instalado pela Microsoft ou parceiros.",
    "Windows 10 (legado)": "App legado do Windows 10 que pode ainda aparecer no Windows 11.",
    "Pré-instalados (loja)": "App promocional ou de parceiro (OEM/loja) — pode não existir em todo PC.",
    "Revisar antes de remover": "Remoção sensível: pode afetar funcionalidades centrais do Windows.",
}


def _auto_winget(item: dict) -> str:
    pid = item["id"]
    if pid in CUSTOM:
        return CUSTOM[pid]
    nome = item["nome"]
    short = item.get("descricao", "").strip()
    cat = item.get("categoria", "")
    hint = WINGET_CAT_HINT.get(cat, "Programa instalável via Winget.")
    return (
        f"{nome}: {short} {hint} "
        f"ID Winget: {pid}. Instalação silenciosa com aceite de termos pelo Prompt Auxiliar."
    )


def _auto_debloat(item: dict) -> str:
    pid = item["id"]
    if pid in CUSTOM:
        return CUSTOM[pid]
    nome = item["nome"]
    short = item.get("descricao", "").strip()
    cat = item.get("categoria", "")
    hint = DEBLOAT_CAT_HINT.get(cat, "Pacote removível via winget uninstall.")
    extra = (
        " Atenção: remova apenas se não usar este recurso; alguns itens voltam após atualizações do Windows."
        if cat == "Revisar antes de remover"
        else " Remover reduz apps em segundo plano e espaço ocupado, mas não afeta arquivos pessoais."
    )
    return f"{nome}: {short} {hint}{extra} ID: {pid}."


def _enrich_file(path: Path, kind: str) -> None:
    data = json.loads(path.read_text(encoding="utf-8"))
    gen = _auto_winget if kind == "winget" else _auto_debloat
    for item in data["itens"]:
        item["descricao_detalhada"] = gen(item)
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"{path.name}: {len(data['itens'])} itens")


if __name__ == "__main__":
    _enrich_file(DATA / "winget_catalog.json", "winget")
    _enrich_file(DATA / "debloat_catalog.json", "debloat")
