# Prompt Auxiliar

Utilitário Windows (WebView2): **scripts .bat** + painéis **Winget** e **Debloat**.

**Versão:** 2.5.0

## Execução rápida

```powershell
irm "https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/win.ps1" | iex
```

## Desenvolvimento

```powershell
pip install -r requirements.txt
python main.py
```

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

## Créditos

[Heyash](https://heyash.vercel.app/)
