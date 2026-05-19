/**
 * Prompt Auxiliar — scripts .bat + painéis Winget/Debloat
 */
(function () {
  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

  const state = {
    catalog: null,
    busca: "",
    busy: false,
    scriptsLayout: "grid",
    view: "scripts",
    pendingUpdate: null,   // guarda info de update disponível
  };

  const boot = { el: $("#boot"), status: $("#boot-status"), bar: $("#boot-bar-fill") };
  const ui = {
    app: $("#app"),
    nav: $("#nav-categories"),
    grid: $("#actions-grid"),
    search: $("#search"),
    title: $("#page-title"),
    subtitle: $("#page-subtitle"),
    version: $("#brand-version"),
    modal: $("#modal"),
    welcome: $("#welcome"),
    toastRoot: $("#toast-root"),
    viewHome: $("#view-home"),
    scriptsToolbar: $("#scripts-toolbar"),
    scriptsGrid: $("#actions-grid"),
  };

  const PAINELS = [
    { kind: "winget", label: "Painel Winget" },
    { kind: "debloat", label: "Painel Debloat" },
  ];

  function api() {
    return window.pywebview && window.pywebview.api;
  }

  function setBootProgress(pct, text) {
    if (boot.bar) boot.bar.style.width = `${pct}%`;
    if (boot.status && text) boot.status.textContent = text;
  }

  function showApp() {
    boot.el.classList.add("hidden");
    ui.app.classList.remove("hidden");
    ui.app.hidden = false;
  }

  function setUpdateAvailability(info) {
    const btn = document.querySelector('[data-action="check-update"]');
    if (!btn || !info) return;
    const pending = !!info.update_available;
    state.pendingUpdate = pending ? info : null;
    btn.classList.toggle("btn-update-pending", pending);
    btn.textContent = pending ? "Atualização disponível" : "Verificar atualização";
    if (ui.version) {
      const local = info.local || info.installed_version || info.version;
      ui.version.textContent = pending && info.remote
        ? `v${local} → v${info.remote}`
        : local ? `v${local}` : "v—";
    }
  }

  function toast(message, type = "info") {
    const el = document.createElement("div");
    el.className = `toast ${type}`;
    el.textContent = message;
    ui.toastRoot.appendChild(el);
    setTimeout(() => {
      el.style.opacity = "0";
      setTimeout(() => el.remove(), 280);
    }, 4200);
  }

  function replaceModalButton(id) {
    const btn = document.getElementById(id);
    const clone = btn.cloneNode(true);
    btn.replaceWith(clone);
    return clone;
  }

  /**
   * @param {{ title: string, body: string, variant?: 'confirm'|'alert', danger?: boolean }} opts
   * @returns {Promise<boolean>} true = confirmar/OK, false = cancelar/Escape
   */
  function showAppModal({
    title,
    body,
    variant = "confirm",
    danger = false,
    confirmLabel,
    cancelLabel,
  }) {
    return new Promise((resolve) => {
      const modal = ui.modal;
      const confirmBtn = replaceModalButton("modal-confirm");
      const cancelBtn = replaceModalButton("modal-cancel");
      $("#modal-title").textContent = title;
      $("#modal-body").textContent = body;

      const isAlert = variant === "alert";
      const isUpdate = variant === "update";
      cancelBtn.textContent = cancelLabel || (isUpdate ? "Depois" : "Cancelar");
      cancelBtn.hidden = isAlert;
      cancelBtn.classList.toggle("hidden", isAlert);
      confirmBtn.textContent =
        confirmLabel || (isAlert ? "OK" : isUpdate ? "Atualizar" : "Confirmar");
      confirmBtn.style.background =
        !isAlert && !isUpdate && danger
          ? "linear-gradient(135deg,#c42b1c,#e81123)"
          : "";

      let done = false;
      const finish = (value) => {
        if (done) return;
        done = true;
        if (modal.open) modal.close();
        resolve(value);
      };

      cancelBtn.addEventListener("click", () => finish(false));
      confirmBtn.addEventListener("click", () => finish(true));
      modal.addEventListener(
        "cancel",
        (e) => {
          e.preventDefault();
          finish(false);
        },
        { once: true }
      );
      modal.showModal();
    });
  }

  function infoDialog(opts) {
    return showAppModal({ ...opts, variant: "alert" });
  }

  function confirmDialog(opts) {
    return showAppModal({ ...opts, variant: "confirm" });
  }

  function escapeHtml(s) {
    const d = document.createElement("div");
    d.textContent = s;
    return d.innerHTML;
  }

  function renderNav() {
    ui.nav.innerHTML = "";
    const curView = document.body.dataset.view;

    PAINELS.forEach((p) => {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "nav-item nav-painel";
      btn.dataset.panelKind = p.kind;
      if (curView === p.kind) btn.classList.add("active");
      btn.textContent = p.label;
      btn.addEventListener("click", () => {
        if (window.Panels.isOpen() && document.body.dataset.view === p.kind) {
          window.Panels.close();
        } else {
          if (window.Tweaks?.isOpen()) window.Tweaks.close();
          window.Panels.open(p.kind);
        }
      });
      ui.nav.appendChild(btn);
    });

    const divTweaks = document.createElement("div");
    divTweaks.className = "nav-divider";
    ui.nav.appendChild(divTweaks);

    const tweaksBtn = document.createElement("button");
    tweaksBtn.type = "button";
    tweaksBtn.className = `nav-item nav-tweaks${curView === "tweaks" ? " active" : ""}`;
    tweaksBtn.textContent = "Tweaks Windows";
    tweaksBtn.addEventListener("click", () => {
      if (window.Tweaks?.isOpen()) {
        window.Tweaks.close();
        openScriptsView();
      } else {
        if (window.Panels?.isOpen()) window.Panels.close();
        window.Tweaks?.open();
        renderNav();
      }
    });
    ui.nav.appendChild(tweaksBtn);

    const div = document.createElement("div");
    div.className = "nav-divider";
    ui.nav.appendChild(div);

    const scriptsBtn = document.createElement("button");
    scriptsBtn.type = "button";
    scriptsBtn.className = `nav-item nav-scripts${curView === "scripts" && !window.Panels?.isOpen() && !window.Tweaks?.isOpen() ? " active" : ""}`;
    scriptsBtn.innerHTML = `Scripts <span class="badge">${state.catalog.acoes.length}</span>`;
    scriptsBtn.addEventListener("click", () => openScriptsView());
    ui.nav.appendChild(scriptsBtn);
  }

  function openScriptsView() {
    if (window.Panels?.isOpen()) window.Panels.close();
    if (window.Tweaks?.isOpen()) window.Tweaks.close();
    state.view = "scripts";
    document.body.dataset.view = "scripts";
    ui.viewHome.classList.remove("hidden");
    ui.viewHome.hidden = false;
    if (ui.scriptsToolbar) ui.scriptsToolbar.classList.remove("hidden");
    renderNav();
    renderScripts();
  }

  function setScriptsLayout(layout) {
    state.scriptsLayout = layout === "list" ? "list" : "grid";
    try {
      localStorage.setItem("promptaux-scripts-layout", state.scriptsLayout);
    } catch (_) {
      /* ignore */
    }
    document.querySelectorAll("[data-scripts-layout]").forEach((btn) => {
      btn.classList.toggle("active", btn.getAttribute("data-scripts-layout") === state.scriptsLayout);
    });
    if (ui.scriptsGrid) {
      ui.scriptsGrid.classList.toggle("scripts-list", state.scriptsLayout === "list");
      ui.scriptsGrid.classList.toggle("grid", state.scriptsLayout === "grid");
    }
    const apiRef = api();
    if (apiRef?.save_scripts_layout) apiRef.save_scripts_layout(state.scriptsLayout);
    renderScripts();
  }


  function compararNome(a, b) {
    return a.nome.localeCompare(b.nome, "pt-BR", { sensitivity: "base" });
  }

  function acoesFiltradas() {
    let list = state.catalog.acoes.slice();
    const q = state.busca.trim().toLowerCase();
    if (q) {
      list = list.filter(
        (a) =>
          a.nome.toLowerCase().includes(q) ||
          a.id.includes(q) ||
          a.descricao.toLowerCase().includes(q) ||
          a.categoria.toLowerCase().includes(q)
      );
    }
    list.sort(compararNome);
    return list;
  }

  function renderScripts() {
    const list = acoesFiltradas();
    ui.title.textContent = "Scripts";
    ui.subtitle.textContent = `${list.length} script(s) .bat disponíveis`;
    if (ui.scriptsToolbar) ui.scriptsToolbar.classList.remove("hidden");
    if (!list.length) {
      ui.scriptsGrid.innerHTML = '<div class="empty-state"><p>Nenhum script encontrado.</p></div>';
      return;
    }
    ui.scriptsGrid.innerHTML = "";
    if (state.scriptsLayout === "list") {
      list.forEach((acao) => {
        const row = document.createElement("button");
        row.type = "button";
        row.className = `panel-row script-action-row risco-${acao.risco}`;
        row.title = acao.descricao || acao.nome;
        const tag =
          acao.risco !== "normal"
            ? `<span class="tag risco-${acao.risco}">${acao.risco === "perigo" ? "Alto risco" : "Atenção"}</span>`
            : "";
        row.innerHTML = `
          <span class="panel-row-body">
            <strong>${escapeHtml(acao.nome)}</strong>
            <span class="panel-row-id">${escapeHtml(acao.id)}</span>
            <span class="panel-row-desc">${escapeHtml(acao.descricao)}</span>
          </span>
          <span class="panel-row-meta">
            ${tag}
            <span class="panel-row-cat">${escapeHtml(acao.categoria)}</span>
            <span class="script-run-hint">Executar</span>
          </span>`;
        row.addEventListener("click", () => runAction(acao));
        ui.scriptsGrid.appendChild(row);
      });
      return;
    }
    list.forEach((acao, i) => {
      const card = document.createElement("button");
      card.type = "button";
      card.className = `card risco-${acao.risco}`;
      card.title = acao.descricao || acao.nome;
      card.style.animationDelay = `${Math.min(i * 0.03, 0.35)}s`;
      const tag =
        acao.risco !== "normal"
          ? `<span class="tag risco-${acao.risco}">${acao.risco === "perigo" ? "Alto risco" : "Atenção"}</span>`
          : "";
      card.innerHTML = `<div class="card-head"><div class="card-head-top"><h3>${escapeHtml(acao.nome)}</h3><span class="card-run-top">Executar</span></div><p>${escapeHtml(acao.descricao)}</p></div><div class="card-foot"><span class="card-foot-left"><span class="script-row-cat">${escapeHtml(acao.categoria)}</span></span><span class="card-foot-right">${tag}</span></div>`;
      card.addEventListener("click", () => runAction(acao));
      ui.scriptsGrid.appendChild(card);
    });
  }

  async function runAction(acao) {
    if (state.busy) {
      toast("Aguarde — outra ação em execução.", "error");
      return;
    }
    if (acao.risco === "perigo" || acao.risco === "aviso") {
      const ok = await confirmDialog({
        title: acao.risco === "perigo" ? "Ação sensível" : "Confirmar",
        body: `${acao.descricao}\n\nContinuar?`,
        danger: acao.risco === "perigo",
      });
      if (!ok) return;
    }
    state.busy = true;
    try {
      const res = await api().run_action(acao.id);
      toast(res.message, res.ok ? "success" : "error");
    } catch (e) {
      toast(String(e), "error");
    } finally {
      state.busy = false;
    }
  }

  async function init() {
    setBootProgress(20, "Conectando…");
    const a = api();
    if (!a) {
      setBootProgress(100, "Bridge Python indisponível.");
      return;
    }
    setBootProgress(45, "Preparando pasta de dados…");
    const initRes = await a.initialize();
    if (!initRes.ok) {
      setBootProgress(100, initRes.message);
      toast(initRes.message, "error");
      return;
    }
    if (window.PromptAuxTheme) {
      if (initRes.theme) {
        window.PromptAuxTheme.apply(initRes.theme);
      } else {
        await window.PromptAuxTheme.syncFromServer();
      }
      window.PromptAuxTheme.bindToggle();
    }
    setBootProgress(70, "Carregando ações…");
    state.catalog = await a.get_catalog();
    ui.version.textContent = `v${state.catalog.meta.version}`;
    setBootProgress(100, "Pronto.");
    await new Promise((r) => setTimeout(r, 300));
    try {
      const savedLayout = localStorage.getItem("promptaux-scripts-layout");
      if (savedLayout === "grid" || savedLayout === "list") state.scriptsLayout = savedLayout;
    } catch (_) {
      /* ignore */
    }
    if (initRes.scripts_layout === "grid" || initRes.scripts_layout === "list") {
      state.scriptsLayout = initRes.scripts_layout;
    }
    setScriptsLayout(state.scriptsLayout);
    showApp();
    document.body.dataset.view = "scripts";
    renderNav();
    openScriptsView();
    if (initRes.primeira_vez) {
      $("#welcome-path").textContent = initRes.pasta;
      ui.welcome.showModal();
    }
  }

  window.appToast = toast;
  window.appConfirm = confirmDialog;
  window.appSetTitle = (t, s) => {
    ui.title.textContent = t;
    ui.subtitle.textContent = s;
    if (ui.scriptsToolbar) ui.scriptsToolbar.classList.add("hidden");
  };
  window.appRefreshHome = () => {
    ui.viewHome.classList.remove("hidden");
    ui.viewHome.hidden = false;
    const p = document.getElementById("view-panel");
    if (p) { p.classList.add("hidden"); p.hidden = true; }
    const t = document.getElementById("view-tweaks");
    if (t) { t.classList.add("hidden"); t.hidden = true; }
    ui.search.placeholder = "Buscar scripts…";
    ui.search.value = "";
    state.busca = "";
    window._panelBusca = "";
    openScriptsView();
  };

  function bindEvents() {
    if (window.Panels) window.Panels.bind();
    if (window.Tweaks) window.Tweaks.bind();
    ui.search.addEventListener("input", () => {
      if (window.Panels?.isOpen()) {
        window.Panels.setBusca(ui.search.value);
        return;
      }
      if (window.Tweaks?.isOpen()) {
        window.Tweaks.setBusca(ui.search.value);
        return;
      }
      state.busca = ui.search.value;
      renderScripts();
    });
    document.querySelectorAll("[data-scripts-layout]").forEach((btn) => {
      btn.addEventListener("click", () => {
        setScriptsLayout(btn.getAttribute("data-scripts-layout"));
      });
    });
    $$("[data-action]").forEach((el) => {
      el.addEventListener("click", async (e) => {
        e.preventDefault();
        const kind = el.getAttribute("data-action");
        if (kind === "folder") {
          const r = await api().open_data_folder();
          toast(r.message, r.ok ? "success" : "error");
        } else if (kind === "check-update") {
          // Se já detectou update disponível → confirmar e atualizar
          if (state.pendingUpdate) {
            const r = state.pendingUpdate;
            const corpo =
              `Versão instalada: v${r.local}\nNova versão: v${r.remote}\n\n` +
              `O app será fechado e o PowerShell executará o instalador oficial.`;
            const atualizar = await showAppModal({
              title: "Atualização disponível",
              body: corpo,
              variant: "update",
              confirmLabel: "Atualizar agora",
              cancelLabel: "Depois",
            });
            if (atualizar) {
              const ur = await api().launch_app_update();
              toast(ur.message, ur.ok ? "success" : "error");
            }
            return;
          }
          // Primeira vez: verifica update
          el.disabled = true;
          el.textContent = "Verificando…";
          try {
            const r = await api().check_for_updates();
            if (!r.ok) {
              toast(r.message || "Erro ao verificar atualização.", "error");
              return;
            }
            setUpdateAvailability(r);
            if (r.update_available) {
              toast(`Nova versão disponível: v${r.remote}`, "info");
            } else {
              const corpo = r.remote
                ? `Versão instalada: v${r.local}\nGitHub (main): v${r.remote}\n\nJá na versão mais recente.`
                : "Já na versão mais recente.";
              await showAppModal({ title: "Verificar atualização", body: corpo, variant: "alert" });
            }
          } catch (e) {
            toast(String(e), "error");
          } finally {
            el.disabled = false;
            if (!state.pendingUpdate) el.textContent = "Verificar atualização";
          }
        } else if (kind === "uninstall") {
          const preview = await api().get_uninstall_preview();
          if (!preview.ok) {
            toast(preview.message || "Não foi possível preparar a exclusão.", "error");
            return;
          }
          const lista = preview.paths.map((p) => `• ${p}`).join("\n");
          const ok = await confirmDialog({
            title: "Excluir Prompt Auxiliar",
            body: `Tem certeza? Esta ação é permanente e não pode ser desfeita.\n\nPastas que serão removidas:\n${lista}\n\nAtalhos na Área de Trabalho e Menu Iniciar também serão apagados.\n\nO aplicativo será fechado em seguida.`,
            danger: true,
          });
          if (!ok) return;
          const r = await api().uninstall_prompt_auxiliar();
          toast(r.message, r.ok ? "success" : "error");
        } else if (kind === "creditos") {
          const r = await api().open_link(kind);
          toast(r.message, r.ok ? "success" : "error");
        }
      });
    });
  }

  window.addEventListener("pywebviewready", () => {
    bindEvents();
    init().catch((err) => {
      setBootProgress(100, "Falha ao iniciar.");
      toast(String(err), "error");
    });
  });
  if (window.pywebview) window.dispatchEvent(new Event("pywebviewready"));
})();
