# Prompt Auxiliar 🤖 v1.3.7

![Prompt Auxiliar Banner](https://raw.githubusercontent.com/luanwolf/PromptAuxiliar/main/imagens/logo.png)

Bem-vindo ao Prompt Auxiliar, a sua ferramenta completa para otimizar e gerenciar o Windows de forma simples e eficiente! ✨

O Prompt Auxiliar é um aplicativo desktop desenvolvido em Python com `customtkinter` que centraliza diversas funções úteis para o dia a dia, desde a instalação e remoção de softwares até ajustes no sistema operacional e otimizações de desempenho.

## 🌟 Recursos Principais

O Prompt Auxiliar oferece uma gama de funcionalidades poderosas, todas acessíveis através de uma interface intuitiva:

* **Atualização de Programas/Softwares:** Mantenha seus aplicativos atualizados via Winget. 🔄
* **Instalação via Winget:** Instale rapidamente programas listados no arquivo `winget.txt`. 🚀
* **Instalação da Pasta Software:** Execute instaladores (.exe, .msi, .lnk) diretamente da pasta `softwares`. 📦
* **Remoção de Bloatware:** Livre-se de softwares pré-instalados indesejados (bloatware) definidos em `bloatware.txt`. 🗑️
* **Aplicação de Ajustes .reg:** Automatize ajustes no registro do Windows usando arquivos `.reg` da pasta `registros`. ⚙️
* **Ativação do Windows (slmgr):** Tente ativar o Windows de forma simplificada. ✅
* **Criação de Atalhos no Desktop:** Crie atalhos úteis como GodMode e Reiniciar para BIOS na área de trabalho. 🔗
* **Reparo de Conexão de Rede:** Diagnostique e tente reparar problemas de rede. 🌐
* **Limpeza de Malware via MRT:** Execute a Ferramenta de Remoção de Software Mal-Intencionado da Microsoft. 🛡️
* **Limpeza de Arquivos Temporários (Baboo Script):** Libere espaço em disco removendo arquivos temporários. 🧹
* **Limpeza Profunda do Windows:** Realiza uma limpeza mais abrangente de arquivos do sistema e dados desnecessários. 彻底
* **Alternar Menu de Contexto:** Alterne entre o menu de contexto clássico (Windows 10) e o novo do Windows 11. 🖱️
* **Gerenciar Apps de Inicialização:** Acesse rapidamente o Gerenciador de Tarefas para gerenciar aplicativos que iniciam com o sistema. ⚡
* **Windows Utility - Chris Titus:** Execute o aclamado script de otimização e customização do Windows de Chris Titus Tech. 🛠️

## 📁 Estrutura de Pastas

Ao iniciar o Prompt Auxiliar pela primeira vez, ele criará automaticamente a seguinte estrutura de pastas essenciais em `C:\PromptAuxiliar`:

```plaintext
📂 C:\PromptAuxiliar\
├── 📂 softwares       → (Coloque seus .exe, .msi e .lnk aqui)
├── 📂 registros       → (Coloque seus .reg aqui)
├── 📂 scripts\        → (Contém os scripts internos do aplicativo)
├── 📄 winget.txt      → (Liste os códigos para instalação via Winget)
└── 📄 bloatware.txt   → (Liste os códigos para remoção de bloatware)
```

Essas pastas permitem que você personalize as ações do aplicativo, adicionando seus próprios instaladores, arquivos de registro ou listas de programas para instalação/remoção.

## 🚀 Como Usar

1.  **Baixe a Última Versão:** Faça o download da versão mais recente do Prompt Auxiliar na página de [Releases do GitHub](https://github.com/luanwolf/PromptAuxiliar/releases/tag/Prompt).
2.  **Execute o Aplicativo:** Inicie o `PromptAuxiliar.exe`. Na primeira execução, ele configurará o ambiente, criando as pastas necessárias em `C:\PromptAuxiliar`.
3.  **Personalize (Opcional):**
    * Para instalar softwares específicos, coloque seus arquivos `.exe`, `.msi` ou `.lnk` na pasta `C:\PromptAuxiliar\softwares`.
    * Para aplicar ajustes no registro, adicione seus arquivos `.reg` à pasta `C:\PromptAuxiliar\registros`.
    * Edite `C:\PromptAuxiliar\winget.txt` para listar os IDs dos pacotes Winget que deseja instalar (um por linha).
    * Edite `C:\PromptAuxiliar\bloatware.txt` para listar os programas que deseja remover (um por linha).
4.  **Selecione uma Opção:** Na interface do aplicativo, clique no botão correspondente à ação que deseja executar.
5.  **Acompanhe o Status:** A barra de status na parte inferior do aplicativo informará o progresso e o resultado das operações.

## 🎨 Temas e Configurações

O Prompt Auxiliar permite alternar facilmente entre o tema claro e escuro, garantindo uma experiência visual agradável. Você também pode acessar a pasta base do aplicativo e a página de atualizações diretamente da barra de ferramentas superior.

## ⚠️ Atenção

* **Reiniciar/Desligar:** Os botões de reinicialização e desligamento na parte superior direita exigem confirmação para evitar ações acidentais. Use-os com cautela.
* **Execução de Scripts:** Alguns scripts podem exigir privilégios de administrador para serem executados corretamente. O aplicativo tentará elevá-los automaticamente quando necessário.

## 🤝 Contribuições

Sinta-se à vontade para abrir issues para bugs ou sugestões de novas funcionalidades!

## Licença

Este projeto está licenciado sob a licença MIT.

---

Made with ❤️ by Heyash
[Visite o site do desenvolvedor](https://heyash.vercel.app/)
