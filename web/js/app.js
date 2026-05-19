/**
 * Prompt Auxiliar — scripts .bat + painéis Winget/Debloat
 */
(function () {
  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

  const state = { catalog: null, categoriaAtiva: null, busca: "", busy: false };

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

  function confirmDialog({ title, body, danger = false }) {
    return new Promise((resolve) => {
      $("#modal-title").textContent = title;
      $("#modal-body").textContent = body;
      const confirmBtn = $("#modal-confirm");
      const cancelBtn = $("#modal-cancel");
      confirmBtn.style.background = danger
        ? "linear-gradient(135deg,#c42b1c,#e81123)"
        : "";
      let settled = false;
      const finish = (v) => {
        if (settled) return;
        settled = true;
        resolve(v);
      };
      cancelBtn.onclick = () => {
        ui.modal.close();
        finish(false);
      };
      confirmBtn.onclick = (e) => {
        e.preventDefault();
        finish(true);
        ui.modal.close();
      };
      ui.modal.addEventListener(
        "cancel",
        (e) => {
          e.preventDefault();
          finish(false);
        },
        { once: true }
      );
      ui.modal.showModal();
    });
  }

  function escapeHtml(s) {
    const d = document.createElement("div");
    d.textContent = s;
    return d.innerHTML;
  }

  function renderNav() {
    ui.nav.innerHTML = "";
    PAINELS.forEach((p) => {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "nav-item nav-painel";
      btn.dataset.panelKind = p.kind;
      btn.textContent = p.label;
      btn.addEventListener("click", () => {
        if (window.Panels.isOpen() && document.body.dataset.view === p.kind) {
          window.Panels.close();
        } else {
          window.Panels.open(p.kind);
        }
      });
      ui.nav.appendChild(btn);
    });
    const div = document.createElement("div");
    div.className = "nav-divider";
    ui.nav.appendChild(div);
    const allBtn = document.createElement("button");
    allBtn.type = "button";
    allBtn.className = `nav-item${state.categoriaAtiva === null ? " active" : ""}`;
    allBtn.innerHTML = `Todas <span class="badge">${state.catalog.acoes.length}</span>`;
    allBtn.addEventListener("click", () => selectCategory(null));
    ui.nav.appendChild(allBtn);
    state.catalog.categorias.forEach((cat) => {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = `nav-item${state.categoriaAtiva === cat.nome ? " active" : ""}`;
      btn.innerHTML = `${cat.nome} <span class="badge">${cat.total}</span>`;
      btn.addEventListener("click", () => selectCategory(cat.nome));
      ui.nav.appendChild(btn);
    });
  }


  function acoesFiltradas() {
    let list = state.catalog.acoes;
    if (state.categoriaAtiva) list = list.filter((a) => a.categoria === state.categoriaAtiva);
    const q = state.busca.trim().toLowerCase();
    if (q) {
      list = list.filter(
        (a) =>
          a.nome.toLowerCase().includes(q) ||
          a.id.includes(q) ||
          a.descricao.toLowerCase().includes(q)
      );
    }
    return list;
  }

  function renderGrid() {
    const list = acoesFiltradas();
    if (state.categoriaAtiva) {
      const cat = state.catalog.categorias.find((c) => c.nome === state.categoriaAtiva);
      ui.title.textContent = state.categoriaAtiva;
      ui.subtitle.textContent = cat ? cat.descricao : "";
    } else {
      ui.title.textContent = "Todas as ferramentas";
      ui.subtitle.textContent = "Scripts .bat e painéis Winget/Debloat";
    }
    if (!list.length) {
      ui.grid.innerHTML = '<div class="empty-state"><p>Nenhuma ação encontrada.</p></div>';
      return;
    }
    ui.grid.innerHTML = "";
    list.forEach((acao, i) => {
      const card = document.createElement("button");
      card.type = "button";
      card.className = `card risco-${acao.risco}`;
      card.title = acao.descricao || acao.nome;
      card.style.animationDelay = `${Math.min(i * 0.03, 0.35)}s`;
      const tag =
        acao.risco !== "normal"
          ? `<span class="tag risco-${acao.risco}">${acao.risco === "perigo" ? "Alto risco" : "Atenção"}</span>`
          : "<span></span>";
      card.innerHTML = `<div class="card-head"><h3>${escapeHtml(acao.nome)}</h3><p>${escapeHtml(acao.descricao)}</p></div><div class="card-foot">${tag}<span class="card-run">Executar →</span></div>`;
      card.addEventListener("click", () => runAction(acao));
      ui.grid.appendChild(card);
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

  function selectCategory(nome) {
    if (window.Panels?.isOpen()) window.Panels.close();
    state.categoriaAtiva = nome;
    renderNav();
    renderGrid();
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
    setBootProgress(70, "Carregando ações…");
    state.catalog = await a.get_catalog();
    ui.version.textContent = `v${state.catalog.meta.version}`;
    setBootProgress(100, "Pronto.");
    await new Promise((r) => setTimeout(r, 300));
    showApp();
    renderNav();
    renderGrid();
    if (initRes.update_available && initRes.update_message) {
      toast(initRes.update_message, "info");
    }
    if (initRes.primeira_vez) {
      $("#welcome-path").textContent = initRes.pasta;
      ui.welcome.showModal();
    }
  }

  window.appToast = toast;
  window.appConfirm = confirmDialog;
  window.appClearCategory = () => {
    state.categoriaAtiva = null;
  };
  window.appSetTitle = (t, s) => {
    ui.title.textContent = t;
    ui.subtitle.textContent = s;
  };
  window.appRefreshHome = () => {
    ui.viewHome.classList.remove("hidden");
    ui.viewHome.hidden = false;
    const p = document.getElementById("view-panel");
    if (p) {
      p.classList.add("hidden");
      p.hidden = true;
    }
    ui.title.textContent = state.categoriaAtiva || "Todas as ferramentas";
    ui.subtitle.textContent = state.categoriaAtiva
      ? ""
      : "Scripts .bat e painéis Winget/Debloat";
    ui.search.placeholder = "Buscar por nome ou descrição…";
    ui.search.value = "";
    state.busca = "";
    window._panelBusca = "";
    renderNav();
    renderGrid();
  };

  function bindEvents() {
    if (window.Panels) window.Panels.bind();
    ui.search.addEventListener("input", () => {
      if (window.Panels?.isOpen()) {
        window.Panels.setBusca(ui.search.value);
        return;
      }
      state.busca = ui.search.value;
      renderGrid();
    });
    $$("[data-action]").forEach((el) => {
      el.addEventListener("click", async (e) => {
        e.preventDefault();
        const kind = el.getAttribute("data-action");
        if (kind === "folder") {
          const r = await api().open_data_folder();
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
