<div align="center">
  <img src="./web/assets/logo.png" alt="Prompt Auxiliar" width="320" />

  <p>
    <img alt="Python" src="https://img.shields.io/badge/Python-3.10+-3776AB?logo=python&logoColor=white" />
    <img alt="pywebview" src="https://img.shields.io/badge/pywebview-5+-1a1a2e?logo=python&logoColor=white" />
    <img alt="WebView2" src="https://img.shields.io/badge/WebView2-Edge-0078D4?logo=microsoftedge&logoColor=white" />
    <img alt="Winget" src="https://img.shields.io/badge/Winget-pacotes-2EA043?logo=windows&logoColor=white" />
    <img alt="PowerShell" src="https://img.shields.io/badge/PowerShell-5.1+-5391FE?logo=powershell&logoColor=white" />
    <img alt="Versão" src="https://img.shields.io/badge/Versão-2.7.5-0078D4" />
  </p>

  <p>
    Utilitário Windows com interface <strong>WebView2</strong>: scripts <strong>.ps1</strong>,
    painel <strong>Winget</strong>, painel <strong>Debloat</strong> e ajustes <strong>Tweaks Windows</strong>.
    <br />
    Python + pywebview + Winget — Windows 10 e 11.
  </p>
</div>

## Visão geral

O **Prompt Auxiliar** centraliza tarefas comuns de manutenção e personalização do Windows:

- **Scripts PowerShell** com visual padronizado: banner, confirmação S/N, passos com status ✓/✗ e log ao final
- **Painel Winget** — catálogo curado com busca, categorias e instalação em lote
- **Painel Debloat** — remoção de bloatware conhecido (Microsoft, Xbox, Bing legado Win10, OEM)
- **Tweaks Windows** — ajustes de registro e sistema com detecção automática do estado atual
- **Ações sensíveis** — confirmação extra para registro, KMS, WinUtil e similares
- **Pasta de dados** em `C:\PromptAuxiliar` (softwares, registros, seleções dos painéis)

---

## Funcionalidades e como usar

### 1) Instalação rápida (one-liner)

Abra o **PowerShell** e execute:

```powershell
irm "https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/install.ps1" | iex
```

Também funciona com `win.ps1` direto; o instalador configura **RemoteSigned** no seu usuário e cria `Iniciar-PromptAuxiliar.cmd` para os próximos usos.

**O que o instalador faz automaticamente**

| Etapa | O que acontece |
|-------|----------------|
| 1. Download | Baixa o repositório para `%LOCALAPPDATA%\PromptAuxiliar` |
| 2. Python | Procura **Python 3.10+**; se não existir, instala via winget ou python.org |
| 3. Dependências | Executa `pip install -r requirements.txt` |
| 4. Pasta de dados | Prepara `C:\PromptAuxiliar` (softwares, registros, seleções) |
| 5. Política | Define **RemoteSigned** (usuário); gera `Iniciar-PromptAuxiliar.cmd` |
| 6. Atalhos | Cria `Prompt Auxiliar vX.Y.Z.lnk` na Área de Trabalho e Menu Iniciar |
| 7. Abrir app | Inicia a interface WebView2 |

---

### 2) Atualizações

O app **não atualiza automaticamente** ao abrir. Para verificar e aplicar uma atualização:

1. Clique em **Verificar atualização** na barra lateral
2. Se houver nova versão, o botão muda para **Atualização disponível** (azul pulsante)
3. Clique novamente para confirmar — o app fecha e o PowerShell aplica a atualização

| Situação | Comportamento |
|----------|----------------|
| Atalho / `win.ps1` | Verifica; atualiza somente com `-Update` ou via botão |
| `python main.py` (dev) | Botão verifica; nunca substitui arquivos com o app aberto |
| Clone com `.git` | Atualização automática **desligada** (você controla pelo Git) |

**Variáveis opcionais** (antes do `irm`):

```powershell
$env:PROMPTAUX_HOME   = "D:\Ferramentas\PromptAuxiliar"  # pasta de instalação
$env:PROMPTAUX_UPDATE = "1"                              # força download do ZIP
irm "https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/win.ps1" | iex
```

**Importante:** suba a versão em `app/config.py` (`APP_VERSION`) a cada release — é isso que o comparador usa.

---

### 3) Scripts PowerShell

Cada card na aba **Scripts** executa um `.ps1` em `scripts/`. Todos usam a biblioteca `_ui.ps1` para saída padronizada:

| Categoria | Exemplos |
|-----------|----------|
| **Instalação** | Atualizar via Winget, instalar da pasta `softwares`, Visual C++ Runtimes |
| **Limpeza** | Temporários, disco, MRT, limpeza profunda (SFC/DISM), malware |
| **Otimização** | Aplicar `.reg`, WinUtil (Chris Titus — PowerShell admin) |
| **Sistema** | Rede, atalhos GodMode/BIOS, inicialização, ativação (aviso) |

**Fluxo de cada script**

1. Banner colorido com título e descrição
2. Confirmação **S/N** (ações de risco exibem aviso extra)
3. Execução com passos numerados e status **OK** (verde) / **ERRO** (vermelho)
4. Resumo consolidado com contagem de sucessos/falhas e tempo decorrido
5. Log salvo em `%TEMP%\PromptAuxiliar\logs\`

Scripts de **alto risco** (WinUtil, KMS) abrem **PowerShell como administrador** após confirmação no app.

Visualização em **grade** (cards) ou **lista densa** (nome + descrição em linha) — botão de alternância no topo.

---

### 4) Painel Winget

| Ação | Como fazer |
|------|------------|
| Abrir | Barra lateral → **Painel Winget** |
| Buscar | Campo de busca no topo (filtra por nome/descrição/categoria) |
| Selecionar | Clique nos itens ou use *Marcar categoria* |
| Instalar | **Executar selecionados** — abre terminal com `winget install` |
| Salvar seleção | **Salvar seleção** grava em `C:\PromptAuxiliar\panels.json` |

O catálogo inclui navegadores, dev tools, utilitários, jogos, personalização e **Runtimes** (ex.: Visual C++ AIO `abbodi1406.vcredist`).

---

### 5) Painel Debloat

| Ação | Como fazer |
|------|------------|
| Abrir | Barra lateral → **Painel Debloat** |
| Itens padrão | Na primeira execução, apps marcados como `padrao` vêm pré-selecionados |
| Remover | **Executar selecionados** — `winget uninstall` no terminal |
| Categorias | Microsoft, Xbox, mídia, comunicação, **Bing legado (Win10)**, OEM, *Revisar antes* |

> Alguns pacotes não existem em todo PC (OEM, versão do Windows). Erros no terminal para IDs ausentes são normais.

Itens em **Revisar antes de remover** (OneDrive, Edge, Store) vêm **desmarcados** por padrão.

---

### 6) Tweaks Windows

Barra lateral → **Tweaks Windows**

O painel detecta automaticamente o estado atual de cada ajuste no registro e exibe um badge **ATIVO** (verde) ou **INATIVO** para cada item.

| Categoria | Exemplos de ajustes disponíveis |
|-----------|--------------------------------|
| **Interface** | Centralizar/mover ícones da taskbar, combinar botões, menu de contexto clássico |
| **Menu Iniciar** | Ocultar apps/arquivos recentes, remover pesquisa Bing |
| **Explorador** | Vista compacta, pasta pessoal na área de trabalho |
| **Privacidade** | Desativar rastreamento de localização, histórico da área de transferência |
| **Desempenho** | Modo Jogo, GPU Hardware-Accelerated Scheduling, remover atraso de startup |
| **Energia** | Desativar Inicialização Rápida |
| **Acessibilidade** | Desativar Sticky Keys, rolar janelas inativas com o mouse |
| **Segurança** | Desativar tela de bloqueio |

**Fluxo de uso:**

1. Selecione os tweaks desejados (caixas de seleção)
2. Clique **Aplicar selecionados** — executa um script PowerShell com admin
3. Um resumo consolidado mostra o resultado de cada ajuste com log salvo em `%TEMP%\PromptAuxiliar\logs\`

> Alguns tweaks requerem **reinicialização do Windows** (indicado com ↺). Tweaks com 🔒 requerem privilégio de Administrador.

---

### 7) Barra lateral

| Controle | Descrição |
|----------|-----------|
| **Verificar atualização** | Verifica se há nova versão no GitHub; muda para "Atualização disponível" se houver |
| **Pasta de dados** | Abre `C:\PromptAuxiliar` no Explorer |
| **Excluir Prompt Auxiliar** | Remove a instalação local completamente |
| **GitHub · luanwolf** | Repositório e perfil |

---

### 8) Ações com nível de risco

| Nível | Comportamento |
|-------|----------------|
| **Normal** | Executa após um clique |
| **Atenção** | Modal de confirmação no app |
| **Alto risco** | Modal + aviso; KMS/WinUtil em PowerShell **admin** |

---

## Pasta de dados

```text
C:\PromptAuxiliar\
├── panels.json       # seleção Winget / Debloat
├── softwares\        # .exe, .msi para instalar_software.ps1
└── registros\        # arquivos .reg para aplicar_ajustes.ps1
```

---

## Estrutura do projeto

```text
app/
  actions.py            # catálogo de ações (.ps1)
  api.py                # bridge WebView ↔ Python
  config.py             # APP_VERSION e constantes
  panels.py             # lógica Winget / Debloat
  paths.py              # resolução de caminhos + geração do .ico
  runner.py             # execução de scripts (embute _ui.ps1 + UTF-8-BOM)
  tweaks.py             # lógica do painel Tweaks Windows
  webview_app.py        # inicialização WebView2 + AUMID taskbar
  win_icon.py           # ícone da janela via WM_SETICON
  data/
    winget_catalog.json
    debloat_catalog.json
    tweaks_catalog.json
scripts/
  _ui.ps1               # biblioteca visual compartilhada
  *.ps1                 # scripts individuais
web/
  assets/
    logo.ico            # ícone do app (taskbar / alt-tab)
    logo-mark.png
  css/app.css
  js/
    app.js              # scripts + navegação + atualização
    panels.js           # painéis Winget/Debloat
    tweaks.js           # painel Tweaks Windows
  index.html
main.py                 # entrada
win.ps1                 # instalador / atualizador one-liner
```

---

## Personalizar catálogos

Edite `app/data/winget_catalog.json`, `app/data/debloat_catalog.json` ou `app/data/tweaks_catalog.json`.

IDs Winget devem ser válidos para:

```powershell
winget install --id <ID> -h
winget uninstall --id <ID> -h
```

---

## Créditos e licença

Desenvolvido por **[luanwolf](https://github.com/luanwolf)**.

Inspirado em fluxos de utilitários Windows (WinUtil, listas de debloat da comunidade). Use por sua conta e risco em ações de sistema, registro e ativação.
