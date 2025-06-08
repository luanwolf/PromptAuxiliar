# 🛠️ Prompt Auxiliar v1.3.7

Uma interface gráfica poderosa e intuitiva para automatizar tarefas pós-formatação e manutenção no Windows. Criado com Python e `customtkinter`, o Prompt Auxiliar centraliza rotinas como instalação, remoção, ajustes, limpeza e otimizações com apenas alguns cliques.

![Prompt Auxiliar Banner](https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/imagens/logo.png)

---

## 🚀 Principais Recursos

- Atualização e instalação de programas via Winget.
- Execução de instaladores `.exe`, `.msi` e `.lnk` da pasta `softwares`.
- Limpeza de arquivos temporários e dados inúteis.
- Remoção de bloatwares personalizados via `bloatware.txt`.
- Aplicação automatizada de arquivos `.reg` de ajustes de sistema.
- Ativação simplificada do Windows via `slmgr`.
- Criação de atalhos úteis (GodMode, Reiniciar na BIOS, etc.).
- Reparos rápidos de conexão de rede.
- Execução do MRT (Malicious Software Removal Tool).
- Alternância entre o menu de contexto clássico e moderno (Win11).
- Acesso rápido à aba de inicialização do Gerenciador de Tarefas.
- Execução do script de customização Chris Titus Tech.

---

## 🖥️ Interface Gráfica

- Tema escuro ou claro alternável com um clique.
- Tooltips informativos sobre cada botão.
- Status de execução em tempo real.
- Pop-ups personalizados para erros e confirmações críticas.
- Ícones intuitivos para acesso rápido a configurações e reinicialização/desligamento.

---

## 📁 Estrutura de Pastas Criada Automaticamente

Ao iniciar o app, será criada a seguinte estrutura:

```plaintext
📂 C:\PromptAuxiliar\
├── 📂 softwares       → (Coloque seus .exe, .msi e .lnk nesta pasta)
├── 📂 registros       → (Coloque seus .reg nesta pasta)
├── 📂 scripts\        → (Contém os scripts internos do aplicativo)
├── 📄 winget.txt      → (Liste os códigos para instalação via Winget)
└── 📄 bloatware.txt   → (Lista com os códigos para "desbostificação" do Windows)
```

---

## ⚙️ Como Usar

1. **Execute o PromptAuxiliar.exe**  
   Ele criará as pastas e arquivos necessários automaticamente.

2. **Personalize (opcional)**  
   - Coloque seus `.exe`, `.msi` ou `.lnk` em `C:\PromptAuxiliar\softwares`.
   - Adicione ajustes `.reg` na pasta `registros`.
   - Edite `winget.txt` para programas a instalar.
      * 💡 Você pode obter os IDs de instalação através [deste site](https://winget.run/)
   - Edite `bloatware.txt` para programas a remover.

3. **Clique nas opções da interface**  
   Cada botão executa um script correspondente que automatiza a tarefa.

---

## 🧪 Requisitos

- Python 3.10+
- Bibliotecas: `customtkinter`, `PIL (Pillow)`

> Use o PyInstaller para gerar o `.exe`, ou execute diretamente via `python main.py`

---

## 💡 Dicas

- Scripts `.bat` devem estar na pasta `scripts/`, inclusive ao compilar o app.
- Pode ser executado como `.exe` portátil (modo frozen).
- Requer permissões de administrador para algumas funções (ativação, ajustes .reg, etc).

---

## 🧑‍💻 Desenvolvido por

**Heyash**  
🔗 [Meu site](https://heyash.vercel.app/)  

---

## 📜 Licença

Este projeto é licenciado sob a licença MIT.
