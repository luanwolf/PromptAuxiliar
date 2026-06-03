<div align="center">
  <img src="./web/assets/logo.png" alt="Prompt Auxiliar" width="320" />

  <p>
    <img alt="Python" src="https://img.shields.io/badge/Python-3.10+-3776AB?logo=python&logoColor=white" />
    <img alt="pywebview" src="https://img.shields.io/badge/pywebview-5+-1a1a2e?logo=python&logoColor=white" />
    <img alt="WebView2" src="https://img.shields.io/badge/WebView2-Edge-0078D4?logo=microsoftedge&logoColor=white" />
    <img alt="Winget" src="https://img.shields.io/badge/Winget-pacotes-2EA043?logo=windows&logoColor=white" />
    <img alt="PowerShell" src="https://img.shields.io/badge/PowerShell-5.1+-5391FE?logo=powershell&logoColor=white" />
    <img alt="Versão" src="https://img.shields.io/badge/Versão-2.7.14-0078D4" />
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
- **Utilitários** — download de vídeo/música (yt-dlp) e Spotify (spotdl), com escolha de pasta e formato
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
| 4. Pasta de dados | Prepara `C:\PromptAuxiliar` (softwares, registros, logs, seleções) |
| 5. Política | Define **RemoteSigned** (usuário); gera `Iniciar-PromptAuxiliar.cmd` |
| 6. Atalhos | Cria `Prompt Auxiliar vX.Y.Z.lnk` na Área de Trabalho e Menu Iniciar |
| 7. Abrir app | Inicia a interface WebView2 |

---

### 2) Atualizações

O app **não instala atualizações automaticamente** ao abrir, mas **verifica na inicialização** se há versão nova no GitHub e deixa o botão azul (**Atualização disponível**) quando houver.

Para aplicar uma atualização:

1. Ao abrir o app, se houver versão nova, o botão já aparece como **Atualização disponível**
2. Clique no botão — o modal de confirmação abre na hora
3. Confirme para iniciar — o app fecha e o PowerShell aplica a atualização
4. A janela do instalador fecha sozinha após contagem **5…1** (sem precisar pressionar Enter)

Você também pode clicar em **Verificar atualização** a qualquer momento para consultar de novo.

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
5. Log salvo em `C:\PromptAuxiliar\logs\`

Scripts de **alto risco** (WinUtil, KMS) abrem **PowerShell como administrador** após confirmação no app.

Visualização em **grade** (cards) ou **lista densa** (nome + descrição em linha) — botão de alternância no topo.

---

### 4) Utilitários (barra lateral)

Barra lateral → **Utilitários** — painel com **dois botões**:

| Botão | Ferramenta | Uso |
|-------|------------|-----|
| **yt-dlp** | [yt-dlp](https://github.com/yt-dlp/yt-dlp) | Vídeo (MP4), áudio (MP3) ou **playlist do YouTube** |
| **spotdl** | [spotdl](https://github.com/spotDL/spotify-downloader) | Música ou playlist do Spotify em MP3 |

Ao clicar em um botão, o app abre um formulário:

| Campo | Descrição |
|-------|-----------|
| **Link (URL)** | URL do vídeo, playlist YouTube ou link Spotify |
| **Pasta de destino** | **Procurar** abre o seletor de pastas do Windows |
| **Formato** (yt-dlp) | **Vídeo (MP4)** ou **Somente áudio (MP3)** |
| **Playlist** (yt-dlp) | Marque para baixar a playlist inteira do YouTube |

Os scripts **verificam se a ferramenta está instalada**; se não estiver, tentam instalar via **winget** e, em seguida, **pip**. Depois executam o download. Logs em `C:\PromptAuxiliar\logs\`.

---

### 5) Painel Winget

| Ação | Como fazer |
|------|------------|
| Abrir | Barra lateral → **Painel Winget** |
| Buscar | Campo de busca no topo (filtra por nome/descrição/categoria) |
| Selecionar | Clique nos itens ou use *Marcar categoria* |
| Instalar | **Executar selecionados** — abre terminal com `winget install` |
| Salvar seleção | **Salvar seleção** grava em `C:\PromptAuxiliar\panels.json` |

O catálogo inclui navegadores, dev tools, utilitários, jogos, personalização e **Runtimes** (ex.: Visual C++ AIO `abbodi1406.vcredist`).

---

### 6) Painel Debloat

| Ação | Como fazer |
|------|------------|
| Abrir | Barra lateral → **Painel Debloat** |
| Itens padrão | Na primeira execução, apps marcados como `padrao` vêm pré-selecionados |
| Remover | **Executar selecionados** — `winget uninstall` no terminal |
| Categorias | Microsoft, Xbox, mídia, comunicação, **Bing legado (Win10)**, OEM, *Revisar antes* |

> Alguns pacotes não existem em todo PC (OEM, versão do Windows). Erros no terminal para IDs ausentes são normais.

Itens em **Revisar antes de remover** (OneDrive, Edge, Store) vêm **desmarcados** por padrão.

---

### 7) Tweaks Windows

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
2. Clique **Aplicar selecionados** — o UAC é solicitado diretamente pelo app (quando necessário) e um PowerShell é aberto
3. Um resumo consolidado mostra o resultado de cada ajuste com log salvo em `C:\PromptAuxiliar\logs\`

> Alguns tweaks requerem **reinicialização do Windows** (indicado com ↺). Tweaks com 🔒 requerem privilégio de Administrador.

---

### 8) Barra lateral

| Controle | Descrição |
|----------|-----------|
| **Verificar atualização** | Consulta o GitHub; se houver versão nova, abre o modal de atualização na hora |
| **Pasta de Dados / Logs** | Abre `C:\PromptAuxiliar` no Explorer (contém subpasta `logs\` com todos os logs) |
| **Excluir Prompt Auxiliar** | Remove a instalação local completamente |
| **GitHub · luanwolf** | Repositório e perfil |

---

### 9) Ações com nível de risco

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
├── registros\        # arquivos .reg para aplicar_ajustes.ps1
└── logs\             # logs de scripts e tweaks (tweaks-*.log, etc.)
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
  _util_install.ps1     # instalação winget/pip (yt-dlp, spotdl)
  baixar_ytdlp.ps1      # download vídeo/áudio/playlist YouTube
  baixar_spotdl.ps1     # download Spotify
  js/utils.js           # painel Utilitários (2 botões)
  *.ps1                 # demais scripts
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

## Histórico recente

| Versão | Destaques |
|--------|-----------|
| **2.7.14** | **Utilitários** na barra lateral com 2 botões; playlist YouTube; instalação winget+pip |
| **2.7.13** | Utilitários iniciais (yt-dlp / spotdl) com modal de URL e pasta |
| **2.7.12** | Release de teste — verificação automática na abertura (botão azul) |
| **2.7.11** | Verificação automática na abertura — botão **Atualização disponível** sem clicar em verificar |
| **2.7.10** | Release de teste do fluxo de atualização |
| **2.7.9** | Janela do instalador fecha sozinha (contagem 5→1); modal de update ao verificar |
| **2.7.8** | Botão **Pasta de Dados / Logs**; remoção do botão Ver Logs nos Tweaks |
| **2.7.7** | Tweaks com admin via UAC; logs em `C:\PromptAuxiliar\logs` |
| **2.7.6** | Instalação de Python ignora alias da Microsoft Store |
| **2.7.0+** | Painel Tweaks, scripts `.ps1` com visual padronizado, update manual pelo app |

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
