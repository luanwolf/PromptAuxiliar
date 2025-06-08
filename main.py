import customtkinter as ctk
import sys
import os
import subprocess
import webbrowser
import threading
import time
from PIL import Image

# --- Configurações e Constantes ---
ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")

PASTA_BASE = r"C:\PromptAuxiliar"
PASTAS_NECESSARIAS = ["softwares", "registros", "scripts"]
ARQUIVOS_TXT = {
    "registros/README.txt": "Coloque seus arquivos .reg aqui.\nEles serão executados pelo app.",
    "softwares/README.txt": "Coloque seus seus arquivos .exe, .msi e .lnk (atalhos) aqui.\nEles serão executados pelo app.",
    "winget.txt": "#Informe aqui quais são os códigos que o app deve instalar.\n#Para ignorar uma linha, coloque '#' no início dela.",
    "bloatware.txt": "#Informe aqui quais são os códigos que o app deve remover.\n#Para ignorar uma linha, coloque '#' no início dela.",
}

# --- Cores e Estilos ---
COR_PRIMARIA = "#2C75B7"
COR_DESTAQUE = "#3C8CD0"
COR_FUNDO_ESCURO = "#292929"
COR_FUNDO_CLARO = "#F0F0F0"
COR_BOTAO_ESCURO = "#4A4A4A"
COR_BOTAO_CLARO = COR_PRIMARIA
COR_PERIGO = "#8B0000"
COR_PERIGO_HOVER = "#A00000"

COR_TEXTO_TEMA_ESCURO = "#E0E0E0"
COR_TEXTO_TEMA_CLARO = "#333333"
COR_TEXTO_BOTAO_FUNDO_ESCURO = "#FFFFFF"
COR_TEXTO_BOTAO_FUNDO_CLARO = "#FFFFFF"

COR_LINK_HOVER = "#0078D4"

# --- Fontes ---
FAMILIA_FONTE = "Segoe UI"
TAMANHO_FONTE_TITULO = 24
TAMANHO_FONTE_SUBTITULO = 16
TAMANHO_FONTE_BOTAO = 14
TAMANHO_FONTE_NORMAL = 12
TAMANHO_FONTE_SPLASH = 18

# --- Espaçamento ---
ESPACAMENTO_XL = 40
ESPACAMENTO_L = 25
ESPACAMENTO_M = 15
ESPACAMENTO_S = 10
ESPACAMENTO_XS = 5


def obter_caminho_recurso(caminho_relativo):
    try:
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.path.abspath(".")
    return os.path.join(base_path, caminho_relativo)


class ToolTip(object):
    def __init__(self, widget, texto="informação do widget", instancia_app=None):
        self.widget = widget
        self.texto = texto
        self.instancia_app = instancia_app
        self.janela_tooltip = None
        self.id = None
        self.x_entrada = 0
        self.y_entrada = 0
        self.widget.bind("<Enter>", self.entrar)
        self.widget.bind("<Leave>", self.sair)
        self.widget.bind("<ButtonPress>", self.sair)

    def entrar(self, evento=None):
        self.x_entrada = evento.x_root
        self.y_entrada = evento.y_root
        self.agendar()

    def sair(self, evento=None):
        self.desagendar()
        self.esconder_tooltip()

    def agendar(self):
        self.desagendar()
        self.id = self.widget.after(500, self.mostrar_tooltip)

    def desagendar(self):
        if self.id:
            self.widget.after_cancel(self.id)
            self.id = None

    def mostrar_tooltip(self):
        if self.janela_tooltip:
            return

        x = self.x_entrada + 10
        y = self.y_entrada + 10

        if self.instancia_app and self.instancia_app.tema_atual == "dark":
            cor_fundo_principal = COR_FUNDO_ESCURO
            cor_fundo_tooltip = COR_FUNDO_ESCURO
            cor_texto = COR_TEXTO_TEMA_ESCURO
            cor_borda = COR_DESTAQUE
        else:
            cor_fundo_principal = self.instancia_app.cget("fg_color")
            if isinstance(cor_fundo_principal, tuple):
                cor_fundo_principal = cor_fundo_principal[0]
            cor_fundo_tooltip = COR_FUNDO_CLARO
            cor_texto = COR_TEXTO_TEMA_CLARO
            cor_borda = COR_PRIMARIA

        self.janela_tooltip = ctk.CTkToplevel(self.widget)
        self.janela_tooltip.wm_overrideredirect(True)
        self.janela_tooltip.wm_geometry(f"+{x}+{y}")
        self.janela_tooltip.wm_attributes("-topmost", True)
        self.janela_tooltip.configure(fg_color=cor_fundo_principal)

        frame_visivel_tooltip = ctk.CTkFrame(
            self.janela_tooltip,
            fg_color=cor_fundo_tooltip,
            corner_radius=0,
            border_width=3,
            border_color="#429ce9",
        )
        frame_visivel_tooltip.pack(padx=0, pady=0)

        label = ctk.CTkLabel(
            frame_visivel_tooltip,
            text=self.texto,
            fg_color="transparent",
            text_color=cor_texto,
            font=ctk.CTkFont(family=FAMILIA_FONTE, size=TAMANHO_FONTE_NORMAL),
            wraplength=200,
        )
        label.pack(padx=ESPACAMENTO_S, pady=ESPACAMENTO_S)

    def esconder_tooltip(self):
        if self.janela_tooltip:
            self.janela_tooltip.destroy()
            self.janela_tooltip = None


class SplashScreen(ctk.CTkToplevel):
    def __init__(self, master, callback_finalizacao):
        super().__init__(master)
        self.callback_finalizacao = callback_finalizacao
        self.geometry("400x150")
        self.title("Iniciando o Prompt Auxiliar...")
        self.resizable(False, False)
        self.grab_set()

        largura_tela = self.winfo_screenwidth()
        altura_tela = self.winfo_screenheight()
        x = (largura_tela - 400) // 2
        y = (altura_tela - 150) // 2
        self.geometry(f"+{x}+{y}")

        ctk.CTkLabel(
            self,
            text="Preparando o ambiente...",
            font=ctk.CTkFont(
                family=FAMILIA_FONTE, size=TAMANHO_FONTE_SPLASH, weight="bold"
            ),
        ).pack(pady=(ESPACAMENTO_L, ESPACAMENTO_M))

        self.barra_progresso = ctk.CTkProgressBar(
            self,
            mode="indeterminate",
            fg_color=COR_PRIMARIA,
            progress_color=COR_DESTAQUE,
        )
        self.barra_progresso.pack(pady=ESPACAMENTO_M, padx=ESPACAMENTO_L, fill="x")
        self.barra_progresso.start()
        self.update_idletasks()

        self.flag_pastas_criadas = False
        threading.Thread(target=self.preparar_ambiente, daemon=True).start()

    def preparar_ambiente(self):
        time.sleep(0.3)
        if not os.path.exists(PASTA_BASE):
            os.makedirs(PASTA_BASE)
            self.flag_pastas_criadas = True
        time.sleep(0.1)

        for pasta in PASTAS_NECESSARIAS:
            caminho = os.path.join(PASTA_BASE, pasta)
            if not os.path.exists(caminho):
                os.makedirs(caminho)
                self.flag_pastas_criadas = True
            time.sleep(0.1)
        for caminho_relativo, conteudo in ARQUIVOS_TXT.items():
            caminho_completo = os.path.join(PASTA_BASE, caminho_relativo)
            os.makedirs(os.path.dirname(caminho_completo), exist_ok=True)
            if not os.path.exists(caminho_completo):
                with open(caminho_completo, "w", encoding="utf-8") as f:
                    f.write(conteudo)
                self.flag_pastas_criadas = True
            time.sleep(0.1)

        if getattr(sys, "frozen", False):
            self.extrair_todos_scripts()
        time.sleep(0.5)

        self.after(100, self._finalizar_splash)

    def extrair_todos_scripts(self):
        pasta_embutida = os.path.join(sys._MEIPASS, "scripts")
        pasta_destino = os.path.join(PASTA_BASE, "scripts")
        os.makedirs(pasta_destino, exist_ok=True)

        if os.path.exists(pasta_embutida):
            for arquivo in os.listdir(pasta_embutida):
                origem = os.path.join(pasta_embutida, arquivo)
                destino = os.path.join(pasta_destino, arquivo)
                if os.path.isfile(origem) and (
                    not os.path.exists(destino)
                    or os.stat(origem).st_size != os.stat(destino).st_size
                ):
                    try:
                        with open(origem, "rb") as fsrc, open(destino, "wb") as fdst:
                            fdst.write(fsrc.read())
                        self.flag_pastas_criadas = True
                    except Exception as e:
                        print(f"Erro ao extrair {arquivo}: {e}")

    def _finalizar_splash(self):
        self.barra_progresso.stop()
        self.grab_release()
        self.destroy()

        if self.flag_pastas_criadas:
            self.mostrar_popup_pastas_criadas()
        else:
            self.callback_finalizacao()

    def mostrar_popup_pastas_criadas(self):
        popup = ctk.CTkToplevel(self.master)
        popup.geometry("400x180")
        popup.title("IMPORTANTE")
        popup.resizable(False, False)
        popup.grab_set()
        popup.update_idletasks()

        largura_tela = popup.winfo_screenwidth()
        altura_tela = popup.winfo_screenheight()

        largura_popup = 400
        altura_popup = 180

        x = (largura_tela - largura_popup) // 2
        y = (altura_tela - altura_popup) // 2

        popup.geometry(f"{largura_popup}x{altura_popup}+{x}+{y}")

        ctk.CTkLabel(
            popup,
            text=f"As pastas necessárias para o funcionamento do APP foram criadas em 'C:/PromptAuxiliar' para o funcionamento do aplicativo.",
            wraplength=350,
            font=ctk.CTkFont(family=FAMILIA_FONTE, size=TAMANHO_FONTE_NORMAL),
        ).pack(expand=True, padx=ESPACAMENTO_M, pady=ESPACAMENTO_M)

        botao_ok = ctk.CTkButton(
            popup,
            text="OK",
            command=lambda: self._fechar_popup_e_iniciar_app(popup),
            fg_color=COR_PRIMARIA,
            hover_color=COR_DESTAQUE,
            corner_radius=8,
        )
        botao_ok.pack(pady=(0, ESPACAMENTO_M))

        popup.protocol(
            "WM_DELETE_WINDOW", lambda: self._fechar_popup_e_iniciar_app(popup)
        )

    def _fechar_popup_e_iniciar_app(self, popup):
        popup.destroy()
        if self.master:  # Verifica se master existe (deve existir)
            self.master.atualizar_status("Ambiente configurado e pronto.", "green")
        self.callback_finalizacao()


class PromptAuxiliarApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.tema_atual = ctk.get_appearance_mode().lower()
        self.title("Prompt Auxiliar v1.3.7")
        self.resizable(False, False)

        largura, altura = 700, 910
        largura_tela = self.winfo_screenwidth()
        altura_tela = self.winfo_screenheight()
        x = (largura_tela - largura) // 2
        y = (altura_tela - altura) // 4
        self.geometry(f"{largura}x{altura}+{x}+{y}")

        caminho_icone = obter_caminho_recurso(os.path.join("imagens", "logo.ico"))
        if os.path.exists(caminho_icone):
            self.iconbitmap(caminho_icone)

        self.imagem_banner = None
        self.carregar_logo()
        self.criar_botoes_topo()
        self.criar_botoes_opcoes()
        self.criar_barra_status()

        self.script_em_execucao = False

    def carregar_logo(self):
        caminho_logo = obter_caminho_recurso(os.path.join("imagens", "logo.png"))
        if os.path.exists(caminho_logo):
            self.imagem_banner = ctk.CTkImage(
                light_image=Image.open(caminho_logo),
                dark_image=Image.open(caminho_logo),
                size=(400, 260),
            )
            self.titulo_label = ctk.CTkLabel(
                self,
                text="",
                font=ctk.CTkFont(
                    family=FAMILIA_FONTE, size=TAMANHO_FONTE_TITULO, weight="bold"
                ),
                image=self.imagem_banner,
                compound="top",
            )
            self.titulo_label.pack(pady=(50, 0))

    def criar_botoes_topo(self):
        def carregar_img_icone(nome, tamanho=(24, 24)):
            caminho = obter_caminho_recurso(os.path.join("imagens", nome))
            return (
                ctk.CTkImage(Image.open(caminho), size=tamanho)
                if os.path.exists(caminho)
                else None
            )

        self.img_sol = carregar_img_icone("sun.png")
        self.img_lua = carregar_img_icone("moon.png")
        self.img_pasta = carregar_img_icone("folder.png")
        self.img_info = carregar_img_icone("info.png")
        self.img_reiniciar = carregar_img_icone("restart.png")
        self.img_desligar = carregar_img_icone("shutdown.png")

        frame_topo_esquerda = ctk.CTkFrame(self, fg_color="transparent")
        frame_topo_esquerda.place(x=ESPACAMENTO_M, y=ESPACAMENTO_M)

        self.botao_tema = ctk.CTkButton(
            frame_topo_esquerda,
            image=self.img_lua if self.tema_atual == "dark" else self.img_sol,
            text="",
            width=50,
            height=35,
            fg_color=COR_BOTAO_ESCURO if self.tema_atual == "dark" else COR_BOTAO_CLARO,
            text_color=COR_TEXTO_BOTAO_FUNDO_ESCURO,
            hover_color=COR_DESTAQUE,
            corner_radius=8,
            command=self.alternar_tema,
        )
        self.botao_tema.pack(side="left", padx=ESPACAMENTO_XS)
        ToolTip(
            self.botao_tema,
            "Alterna entre o tema claro e escuro do aplicativo.",
            instancia_app=self,
        )

        btn_abrir_pasta = ctk.CTkButton(
            frame_topo_esquerda,
            image=self.img_pasta,
            text="",
            width=50,
            height=35,
            fg_color=COR_BOTAO_ESCURO if self.tema_atual == "dark" else COR_BOTAO_CLARO,
            text_color=COR_TEXTO_BOTAO_FUNDO_ESCURO,
            hover_color=COR_DESTAQUE,
            corner_radius=8,
            command=self.abrir_pasta,
        )
        btn_abrir_pasta.pack(side="left", padx=ESPACAMENTO_XS)
        ToolTip(
            btn_abrir_pasta, "Abre a pasta base do Prompt Auxiliar.", instancia_app=self
        )

        btn_mostrar_atualizacao = ctk.CTkButton(
            frame_topo_esquerda,
            image=self.img_info,
            text="",
            width=50,
            height=35,
            fg_color=COR_BOTAO_ESCURO if self.tema_atual == "dark" else COR_BOTAO_CLARO,
            text_color=COR_TEXTO_BOTAO_FUNDO_ESCURO,
            hover_color=COR_DESTAQUE,
            corner_radius=8,
            command=self.mostrar_atualizacao,
        )
        btn_mostrar_atualizacao.pack(side="left", padx=ESPACAMENTO_XS)
        ToolTip(
            btn_mostrar_atualizacao,
            "Abre a página do GitHub com as informações sobre a versão atual e atualizações.",
            instancia_app=self,
        )

        frame_topo_direita = ctk.CTkFrame(self, fg_color="transparent")
        frame_topo_direita.place(
            relx=1.0, x=-ESPACAMENTO_M, y=ESPACAMENTO_M, anchor="ne"
        )

        btn_reiniciar = ctk.CTkButton(
            frame_topo_direita,
            image=self.img_reiniciar,
            text="",
            width=50,
            height=35,
            fg_color=COR_PERIGO,
            hover_color=COR_PERIGO_HOVER,
            corner_radius=8,
            command=lambda: self.mostrar_popup_confirmacao_acao("reiniciar"),
        )
        btn_reiniciar.pack(side="left", padx=ESPACAMENTO_XS)
        ToolTip(
            btn_reiniciar, "Reinicia o computador.", instancia_app=self
        )

        btn_desligar = ctk.CTkButton(
            frame_topo_direita,
            image=self.img_desligar,
            text="",
            width=50,
            height=35,
            fg_color=COR_PERIGO,
            hover_color=COR_PERIGO_HOVER,
            corner_radius=8,
            command=lambda: self.mostrar_popup_confirmacao_acao("desligar"),
        )
        btn_desligar.pack(side="left", padx=ESPACAMENTO_XS)
        ToolTip(btn_desligar, "Desliga o computador.", instancia_app=self)

        self.subtitulo_label = ctk.CTkLabel(
            self,
            text="Selecione uma das opções abaixo:",
            font=ctk.CTkFont(
                family=FAMILIA_FONTE, size=TAMANHO_FONTE_SUBTITULO, weight="bold"
            ),
        )
        self.subtitulo_label.pack(pady=(ESPACAMENTO_L, ESPACAMENTO_M))

    def criar_botoes_opcoes(self):
        self.frame_botoes = ctk.CTkFrame(self, fg_color="transparent")
        self.frame_botoes.pack(pady=ESPACAMENTO_M, padx=ESPACAMENTO_L)

        self.mapeamento_opcoes = {
            "Atualizar programas/softwares": {
                "script": "atualizar_softwares.bat",
                "desc": "Atualiza os programas instalados no sistema via Winget.",
            },
            "Instalar via Winget": {
                "script": "instalar_winget.bat",
                "desc": "Instala programas listados no arquivo 'winget.txt' usando o Winget.",
            },
            "Instalar da pasta Software": {
                "script": "instalar_software.bat",
                "desc": "Instala programas (.exe, .msi e .lnk) da pasta 'softwares'.",
            },
            "Remover Bloatware": {
                "script": "remover_bloatware.bat",
                "desc": "Remove softwares pré-instalados e indesejados (bloatware) do Windows listados no arquivo 'bloatware.txt'.",
            },
            "Aplicar ajustes .reg": {
                "script": "aplicar_ajustes.bat",
                "desc": "Aplica ajustes no registro do Windows usando arquivos .reg da pasta 'registros'.",
            },
            "Ativar o Windows (slmgr)": {
                "script": "ativar_windows.bat",
                "desc": "Tenta ativar o Windows usando comandos 'slmgr'.",
            },
            "Criar atalhos no desktop (GodMode e BIOS)": {
                "script": "criar_atalhos.bat",
                "desc": "Cria atalhos da pasta GodMode e Reiniciar para BIOS na área de trabalho.",
            },
            "Reparar conexão de rede": {
                "script": "reparar_rede.bat",
                "desc": "Executa comandos para tentar diagnosticar e reparar problemas de conexão de rede.",
            },
            "Limpeza de malware via MRT": {
                "script": "limpeza_malware.bat",
                "desc": "Executa a Ferramenta de Remoção de Software Mal-Intencionado da Microsoft (MRT).",
            },
            "Limpeza de arquivos temporário (Baboo Script)": {
                "script": "limpeza_temporarios.bat",
                "desc": "Limpa arquivos temporários do sistema para liberar espaço em disco.",
            },
            "Limpeza profunda do Windows": {
                "script": "limpeza_profunda.bat",
                "desc": "Realiza uma limpeza mais abrangente de arquivos do sistema e dados desnecessários.",
            },
            "Alternar o menu de contexto": {
                "script": "alternar_contexto.bat",
                "desc": "Alterna entre o menu de contexto clássico (Windows 10) e o novo do Windows 11.",
            },
            "Gerenciar apps de inicialização": {
                "script": "gerenciar_inicializacao.bat",
                "desc": "Abre o Gerenciador de Tarefas na aba de inicialização para gerenciar aplicativos que iniciam com o sistema.",
            },
            "Windows Utility - Chris Titus": {
                "script": "windows_utility.bat",
                "desc": "Executa o script de otimização e customização do Windows de Chris Titus Tech.",
            },
        }

        self.botoes_opcao = []

        for idx, (opcao, dados) in enumerate(self.mapeamento_opcoes.items()):
            linha, coluna = divmod(idx, 2)
            botao = ctk.CTkButton(
                self.frame_botoes,
                text=opcao,
                width=300,
                height=45,
                corner_radius=8,
                font=ctk.CTkFont(
                    family=FAMILIA_FONTE, size=TAMANHO_FONTE_BOTAO, weight="normal"
                ),
                fg_color=COR_PRIMARIA,
                hover_color=COR_DESTAQUE,
                text_color=COR_TEXTO_BOTAO_FUNDO_ESCURO,
                command=lambda s=dados["script"]: self.executar_script_em_thread(s),
            )
            botao.grid(row=linha, column=coluna, padx=ESPACAMENTO_S, pady=ESPACAMENTO_S)
            ToolTip(botao, dados["desc"], instancia_app=self)
            self.botoes_opcao.append(botao)

    def criar_barra_status(self):
        self.frame_barra_status = ctk.CTkFrame(self, fg_color="transparent")
        self.frame_barra_status.pack(
            side="bottom",
            fill="x",
            pady=(ESPACAMENTO_M, ESPACAMENTO_S),
            padx=ESPACAMENTO_L,
        )

        self.label_status = ctk.CTkLabel(
            self.frame_barra_status,
            text="Pronto para uso.",
            font=ctk.CTkFont(family=FAMILIA_FONTE, size=TAMANHO_FONTE_NORMAL),
            text_color=(
                COR_TEXTO_TEMA_ESCURO
                if self.tema_atual == "dark"
                else COR_TEXTO_TEMA_CLARO
            ),
        )
        self.label_status.pack(side="left", padx=ESPACAMENTO_XS)

        self.label_creditos = ctk.CTkLabel(
            self.frame_barra_status,
            text="© Heyash",
            font=ctk.CTkFont(
                family=FAMILIA_FONTE, size=TAMANHO_FONTE_NORMAL, weight="bold"
            ),
            text_color=(
                COR_TEXTO_TEMA_ESCURO
                if self.tema_atual == "dark"
                else COR_TEXTO_TEMA_CLARO
            ),
        )
        self.label_creditos.pack(side="right", padx=ESPACAMENTO_XS)

        self.label_creditos.bind("<Button-1>", lambda e: self.abrir_link_heyash())
        self.label_creditos.bind("<Enter>", self.ao_passar_link)
        self.label_creditos.bind("<Leave>", self.ao_sair_link)
        ToolTip(
            self.label_creditos, "Visite o site do desenvolvedor.", instancia_app=self
        )

    def ao_passar_link(self, evento):
        self.label_creditos.configure(text_color=COR_LINK_HOVER)
        self.label_creditos.configure(cursor="hand2")

    def ao_sair_link(self, evento):
        if self.tema_atual == "dark":
            self.label_creditos.configure(text_color=COR_TEXTO_TEMA_ESCURO)
        else:
            self.label_creditos.configure(text_color=COR_TEXTO_TEMA_CLARO)
        self.label_creditos.configure(cursor="")

    def alternar_tema(self):
        if self.tema_atual == "dark":
            ctk.set_appearance_mode("light")
            self.tema_atual = "light"
            self.botao_tema.configure(image=self.img_sol, fg_color=COR_BOTAO_CLARO)
            self.titulo_label.configure(text_color=COR_TEXTO_TEMA_CLARO)
            self.subtitulo_label.configure(text_color=COR_TEXTO_TEMA_CLARO)
            self.label_status.configure(text_color=COR_TEXTO_TEMA_CLARO)
            self.label_creditos.configure(text_color=COR_TEXTO_TEMA_CLARO)

            for botao in self.botoes_opcao:
                botao.configure(text_color=COR_TEXTO_BOTAO_FUNDO_CLARO)
        else:
            ctk.set_appearance_mode("dark")
            self.tema_atual = "dark"
            self.botao_tema.configure(image=self.img_lua, fg_color=COR_BOTAO_ESCURO)
            self.titulo_label.configure(text_color=COR_TEXTO_TEMA_ESCURO)
            self.subtitulo_label.configure(text_color=COR_TEXTO_TEMA_ESCURO)
            self.label_status.configure(text_color=COR_TEXTO_TEMA_ESCURO)
            self.label_creditos.configure(text_color=COR_TEXTO_TEMA_ESCURO)

            for botao in self.botoes_opcao:
                botao.configure(text_color=COR_TEXTO_BOTAO_FUNDO_ESCURO)

        for widget in self.winfo_children():
            if isinstance(widget, ctk.CTkFrame):
                if len(widget.winfo_children()) > 0 and widget is not self.frame_botoes:
                    for botao_filho in widget.winfo_children():
                        if isinstance(botao_filho, ctk.CTkButton):
                            if botao_filho != self.botao_tema and botao_filho.cget(
                                "fg_color"
                            ) not in (COR_PERIGO, COR_PERIGO_HOVER):
                                botao_filho.configure(
                                    fg_color=(
                                        COR_BOTAO_ESCURO
                                        if self.tema_atual == "dark"
                                        else COR_BOTAO_CLARO
                                    ),
                                    text_color=COR_TEXTO_BOTAO_FUNDO_ESCURO,
                                )
                                botao_filho.configure(hover_color=COR_DESTAQUE)

    def abrir_pasta(self):
        if os.path.exists(PASTA_BASE):
            try:
                os.startfile(PASTA_BASE)
                self.atualizar_status("Pasta aberta com sucesso.")
            except Exception as e:
                self.mostrar_popup_erro(
                    "Erro ao abrir pasta", f"Não foi possível abrir a pasta:\n{e}"
                )
                self.atualizar_status("Erro ao abrir pasta.", "red")
        else:
            self.mostrar_popup_erro("Erro", f"A pasta base '{PASTA_BASE}' não existe.")
            self.atualizar_status("Pasta não encontrada.", "red")

    def mostrar_atualizacao(self):
        try:
            webbrowser.open(
                "https://github.com/luanwolf/PromptAuxiliar/releases/tag/Prompt-Auxiliar-1.3.7"
            )
            self.atualizar_status("Página de atualizações aberta no navegador.")
        except Exception as e:
            self.mostrar_popup_erro(
                "Erro ao abrir link",
                f"Não foi possível abrir a página de atualizações.\nErro: {e}",
            )
            self.atualizar_status("Erro ao abrir página de atualizações.", "red")

    def abrir_link_heyash(self):
        try:
            webbrowser.open("https://heyash.vercel.app/")
            self.atualizar_status("Link de créditos aberto no navegador.")
        except Exception as e:
            self.mostrar_popup_erro(
                "Erro ao abrir link",
                f"Não foi possível abrir o link do desenvolvedor.\nErro: {e}",
            )
            self.atualizar_status("Erro ao abrir link do desenvolvedor.", "red")

    def mostrar_popup_erro(self, titulo, mensagem):
        popup = ctk.CTkToplevel(self)
        popup.geometry("400x180")
        popup.title(titulo)
        popup.resizable(False, False)
        popup.grab_set()
        popup.update_idletasks()

        x = self.winfo_x() + (self.winfo_width() - 400) // 2
        y = self.winfo_y() + (self.winfo_height() - 180) // 2
        popup.geometry(f"+{x}+{y}")

        ctk.CTkLabel(
            popup,
            text=mensagem,
            wraplength=350,
            font=ctk.CTkFont(family=FAMILIA_FONTE, size=TAMANHO_FONTE_NORMAL),
        ).pack(expand=True, padx=ESPACAMENTO_M, pady=ESPACAMENTO_M)
        ctk.CTkButton(
            popup,
            text="OK",
            command=popup.destroy,
            fg_color=COR_PRIMARIA,
            hover_color=COR_DESTAQUE,
            corner_radius=8,
        ).pack(pady=(0, ESPACAMENTO_M))

    def atualizar_status(self, mensagem, cor="green"):
        if cor == "green":
            cor_texto = "green" if self.tema_atual == "dark" else "darkgreen"
        elif cor == "red":
            cor_texto = COR_PERIGO
        else:
            cor_texto = (
                COR_TEXTO_TEMA_ESCURO
                if self.tema_atual == "dark"
                else COR_TEXTO_TEMA_CLARO
            )

        self.label_status.configure(text=mensagem, text_color=cor_texto)
        self.update_idletasks()

    def alternar_estado_botoes(self, habilitar=True):
        for botao in self.botoes_opcao:
            botao.configure(state="normal" if habilitar else "disabled")
        self.botao_tema.configure(state="normal" if habilitar else "disabled")
        for widget in self.winfo_children():
            if isinstance(widget, ctk.CTkFrame):
                if len(widget.winfo_children()) > 0 and widget is not self.frame_botoes:
                    for botao_filho in widget.winfo_children():
                        if isinstance(botao_filho, ctk.CTkButton):
                            if botao_filho != self.botao_tema and botao_filho.cget(
                                "fg_color"
                            ) not in (COR_PERIGO, COR_PERIGO_HOVER):
                                botao_filho.configure(
                                    state="normal" if habilitar else "disabled"
                                )

    def executar_script_em_thread(self, nome_arquivo):
        if self.script_em_execucao:
            self.atualizar_status("Aguarde, outro script está em execução.", "red")
            return

        self.script_em_execucao = True
        self.alternar_estado_botoes(habilitar=False)
        self.atualizar_status(f"Executando '{nome_arquivo}'...", "blue")
        threading.Thread(
            target=self._logica_executar_script, args=(nome_arquivo,), daemon=True
        ).start()

    def _logica_executar_script(self, nome_arquivo):
        try:
            caminho_script_temporario = os.path.join(
                PASTA_BASE, "scripts", nome_arquivo
            )

            if getattr(sys, "frozen", False) and not os.path.exists(
                caminho_script_temporario
            ):
                caminho_embutido = os.path.join(sys._MEIPASS, "scripts", nome_arquivo)
                os.makedirs(os.path.dirname(caminho_script_temporario), exist_ok=True)
                with open(caminho_embutido, "rb") as fsrc, open(
                    caminho_script_temporario, "wb"
                ) as fdst:
                    fdst.write(fsrc.read())

            if os.path.exists(caminho_script_temporario):
                procedimento = subprocess.Popen(
                    ["cmd", "/c", "start", caminho_script_temporario], shell=True
                )
                procedimento.wait()
                self.after(
                    100,
                    lambda: self.atualizar_status(
                        f"'{nome_arquivo}' concluído.", "green"
                    ),
                )
            else:
                self.after(
                    100,
                    lambda: self.mostrar_popup_erro(
                        "Script não encontrado",
                        f"O script '{nome_arquivo}' não foi encontrado.\nVerifique a pasta 'scripts'.",
                    ),
                )
                self.after(
                    100,
                    lambda: self.atualizar_status(
                        f"Erro: Script '{nome_arquivo}' não encontrado.", "red"
                    ),
                )

        except Exception as e:
            self.after(
                100, lambda: self.mostrar_popup_erro("Erro ao executar script", str(e))
            )
            self.after(
                100,
                lambda: self.atualizar_status(
                    f"Erro ao executar '{nome_arquivo}'.", "red"
                ),
            )
        finally:
            self.script_em_execucao = False
            self.after(100, lambda: self.alternar_estado_botoes(habilitar=True))

    def abrir_link_heyash(self):
        webbrowser.open("https://heyash.vercel.app/")
        self.atualizar_status("Link de créditos aberto no navegador.")

    # Novo método para o pop-up de confirmação
    def mostrar_popup_confirmacao_acao(self, acao):
        popup = ctk.CTkToplevel(self)
        popup.geometry("400x180")
        popup.title("IMPORTANTE")
        popup.resizable(False, False)
        popup.grab_set()
        popup.update_idletasks()

        # Centraliza o pop-up como o splash screen
        largura_tela = popup.winfo_screenwidth()
        altura_tela = popup.winfo_screenheight()
        largura_popup = 400
        altura_popup = 180
        x = (largura_tela - largura_popup) // 2
        y = (altura_tela - altura_popup) // 2
        popup.geometry(f"{largura_popup}x{altura_popup}+{x}+{y}")

        if acao == "reiniciar":
            mensagem = "Tem certeza que deseja REINICIAR o computador agora?"
            comando = "shutdown /r /t 0"
        elif acao == "desligar":
            mensagem = "Tem certeza que deseja DESLIGAR o computador agora?"
            comando = "shutdown /s /t 0"
        else:
            return  # Não deveria acontecer

        ctk.CTkLabel(
            popup,
            text=mensagem,
            wraplength=350,
            font=ctk.CTkFont(
                family=FAMILIA_FONTE, size=TAMANHO_FONTE_NORMAL, weight="bold"
            ),
        ).pack(expand=True, padx=ESPACAMENTO_M, pady=ESPACAMENTO_M)

        frame_botoes_popup = ctk.CTkFrame(popup, fg_color="transparent")
        frame_botoes_popup.pack(pady=(0, ESPACAMENTO_M))

        # Botão Confirmar
        botao_confirmar = ctk.CTkButton(
            frame_botoes_popup,
            text="Confirmar",
            command=lambda: self._executar_acao_e_fechar_popup(comando, popup, acao),
            fg_color=COR_PERIGO,
            hover_color=COR_PERIGO_HOVER,
            corner_radius=8,
            height=30,
        )  # Adicione esta linha
        botao_confirmar.pack(side="left", padx=ESPACAMENTO_S)

        # Botão Cancelar
        botao_cancelar = ctk.CTkButton(
            frame_botoes_popup,
            text="Cancelar",
            command=popup.destroy,
            fg_color=COR_PRIMARIA,
            hover_color=COR_DESTAQUE,
            corner_radius=8,
            height=30,
        )  # Adicione esta linha
        botao_cancelar.pack(side="right", padx=ESPACAMENTO_S)

        # Permite fechar o pop-up pelo 'X'
        popup.protocol("WM_DELETE_WINDOW", popup.destroy)

    def _executar_acao_e_fechar_popup(self, comando, popup, acao):
        popup.destroy()
        try:
            subprocess.run(comando, shell=True, check=True)
            self.atualizar_status(f"Comando de {acao} executado com sucesso.", "green")
        except subprocess.CalledProcessError as e:
            self.mostrar_popup_erro(
                "Erro ao executar comando",
                f"Não foi possível {acao} o computador.\nErro: {e}",
            )
            self.atualizar_status(f"Erro ao {acao} o computador.", "red")
        except Exception as e:
            self.mostrar_popup_erro(
                "Erro inesperado",
                f"Ocorreu um erro inesperado ao tentar {acao} o computador.\nErro: {e}",
            )
            self.atualizar_status(f"Erro inesperado ao {acao} o computador.", "red")


def main():
    try:
        app = PromptAuxiliarApp()

        def iniciar_app_principal():
            app.deiconify()
            app.atualizar_status("Pronto para uso.")

        splash = SplashScreen(app, callback_finalizacao=iniciar_app_principal)
        app.withdraw()
        app.mainloop()
    except Exception as e:
        print("Ocorreu um erro durante a execução do programa:")
        print(e)
        input("Pressione Enter para sair...")


if __name__ == "__main__":
    main()
