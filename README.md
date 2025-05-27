# 🛠️ Prompt Auxiliar v1.2 by Heyash

Script em batch (.bat) interativo para automação pós-formatação e manutenção de sistemas Windows. Desenvolvido com foco em praticidade, organização e automação de tarefas comuns com apenas alguns cliques.

## 📦 Recursos principais

- Interface de menu interativo com suporte a UTF-8
- Execução forçada como administrador
- Criação automática de estrutura de pastas e arquivos
- Registro de logs com nome personalizado por data e usuário
- Primeira execução com apresentação e ajuda inicial
- Otimizado para rodar via **PowerShell** ou convertido em `.exe` com suporte a elevação

---

## 🧭 Estrutura de diretórios criada automaticamente

```plaintext
📁 PromptAuxiliar\
├── 📂 Log\               → Armazena os arquivos de log gerados automaticamente
├── 📂 Registros\         → Local para arquivos .reg (ajustes de sistema)
├── 📂 Software\          → Local para instaladores .exe, .msi e atalhos
├── 📂 Utilitarios\       → Scripts auxiliares como limpeza de temporários
├── 📄 Winget.txt          → Lista de apps para instalação via Winget
├── 📄 Bloatware.txt       → Lista de apps para desinstalação
```

---

## 📋 Funcionalidades do menu

| Código | Função                                                                  |
|--------|-------------------------------------------------------------------------|
| 01     | 🔄 Atualizar softwares do sistema                                       |
| 02     | 📦 Instalar softwares via **Winget** (baseado no arquivo `winget.txt`)  |
| 03     | 💻 Instalar softwares da pasta `Software`                               |
| 04     | 🧹 Remover bloatwares (`bloatware.txt`)                                 |
| 05     | 🛠️ Aplicar configurações do sistema via arquivos `.reg`                 |
| 06     | 🔐 Ativar o Windows com `slmgr`                                         |
| 07     | 🧭 Criar atalhos úteis na área de trabalho (GodMode e BIOS)             |
| 08     | 🌐 Reparar conexão de rede                                              |
| 09     | 🧼 Limpeza de malwares via **MRT**                                      |
| 10     | 🧹 Limpar arquivos temporários                                          |
| 11     | 🧽 Limpeza profunda do sistema                                          |
| 12     | 🪛 Acessar o **Windows Utility** (Chris Titus                           |
| 13     | 🧰 Alternar menu de contexto do botão direito                           |
| P      | 📂 Abrir pasta raiz do prompt                                           |
| R      | 🔁 Recarregar o menu                                                    |
| X      | ❌ Encerrar o script                                                    |

---

## ⚙️ Requisitos

- Sistema: Windows 10/11
- Execução: como **Administrador**
- Winget habilitado
- PowerShell instalado (nativo no Windows 10/11)

---

## 🚀 Como usar

1. Execute o script como **Administrador**
2. O script criará a estrutura necessária automaticamente
3. Escolha uma opção do menu digitando o número correspondente
4. Personalize os arquivos `Winget.txt` e `Bloatware.txt` conforme desejar

> ⚠️ Linhas com `#` em `Winget.txt` e `Bloatware.txt` são ignoradas

---

## 🧠 Créditos

Desenvolvido por **Heyash** — com foco em produtividade e automação para técnicos e usuários avançados.
