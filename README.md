# Prompt Auxiliar

Utilitário Windows (WebView2): **scripts .bat** + painéis **Winget** e **Debloat**.

**Versão:** 2.8.0

## Instalação (IRM)

```powershell
irm "https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/install.ps1" | iex
```

Atualizar instalação existente:

```powershell
$env:PROMPTAUX_UPDATE = '1'
irm "https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/install.ps1" | iex
```

Alternativa direta (`win.ps1`):

```powershell
irm "https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/win.ps1" | iex
```

O instalador baixa o repositório em `%LOCALAPPDATA%\PromptAuxiliar`, instala dependências Python, gera o ícone `.ico`, cria atalhos na Área de Trabalho e no Menu Iniciar e abre o app.

## Desenvolvimento

```powershell
pip install -r requirements.txt
python main.py
```

Atalho local (regenera ícone + desktop):

```powershell
powershell -ExecutionPolicy Bypass -File powershell\Criar-Atalho.ps1
```

## Logo e ícone

| Arquivo | Uso |
|---------|-----|
| `web/assets/logo.png` | Logo raster (fonte) |
| `web/assets/logo.svg` | Logo vetorial (UI fallback) |
| `imagens/logo.ico` | Ícone do atalho Windows |
| `scripts/build_icon.py` | Regenera `.ico` a partir do PNG |

## Scripts (`scripts/`)

Cada card do menu executa um `.bat` na pasta `scripts/` do projeto (limpeza, rede, registro, etc.).

## Painéis

- Seleção em `C:\PromptAuxiliar\panels.json`
- Winget instala / Debloat remove via terminal

## Pasta de dados

```
C:\PromptAuxiliar\
├── panels.json
├── softwares\      # instaladores locais
└── registros\      # arquivos .reg
```

## Repositório

- GitHub: [luanwolf/PromptAuxiliar](https://github.com/luanwolf/PromptAuxiliar)
- Releases: [releases/latest](https://github.com/luanwolf/PromptAuxiliar/releases/latest)

## Créditos

[Heyash](https://heyash.vercel.app/)
