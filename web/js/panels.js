/**
 * Painéis Winget e Debloat — seleção estilo catálogo.
 */
(function () {
  const $ = (sel, root = document) => root.querySelector(sel);

  const el = {
    viewHome: $("#view-home"),
    viewPanel: $("#view-panel"),
    cats: $("#panel-cats"),
    list: $("#panel-list"),
    count: $("#panel-selected-count"),
    selectAll: $("#panel-select-all"),
    selectNone: $("#panel-select-none"),
    save: $("#panel-save"),
    run: $("#panel-run"),
    search: $("#search"),
  };

  const state = {
    kind: null,
    data: null,
    categoria: null,
    selecionados: new Set(),
  };

  let bound = false;

  function api() {
    return window.pywebview && window.pywebview.api;
  }

  function escapeHtml(s) {
    const d = document.createElement("div");
    d.textContent = s;
    return d.innerHTML;
  }

  function itensFiltrados() {
    if (!state.data) return [];
    let list = state.data.itens;
    if (state.categoria) {
      list = list.filter((i) => i.categoria === state.categoria);
    }
    const q = (window._panelBusca || "").trim().toLowerCase();
    if (q) {
      list = list.filter(
        (i) =>
          i.nome.toLowerCase().includes(q) ||
          i.id.toLowerCase().includes(q) ||
          i.descricao.toLowerCase().includes(q)
      );
    }
    return list;
  }

  function syncSelecionadosFromData() {
    state.selecionados.clear();
    state.data.itens.forEach((i) => {
      if (i.selecionado) state.selecionados.add(i.id);
    });
  }

  function applySelecionadosToData() {
    state.data.itens.forEach((i) => {
      i.selecionado = state.selecionados.has(i.id);
    });
  }

  function updateCount() {
    const n = state.selecionados.size;
    el.count.textContent = `${n} selecionado${n !== 1 ? "s" : ""}`;
  }

  function renderCats() {
    if (!state.data) return;
    el.cats.innerHTML = "";

    const all = document.createElement("button");
    all.type = "button";
    all.className = `panel-cat${!state.categoria ? " active" : ""}`;
    all.textContent = "Todas";
    all.addEventListener("click", () => {
      state.categoria = null;
      renderCats();
      renderList();
    });
    el.cats.appendChild(all);

    state.data.categorias.forEach((cat) => {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = `panel-cat${state.categoria === cat ? " active" : ""}`;
      const total = state.data.itens.filter((i) => i.categoria === cat).length;
      const sel = state.data.itens.filter(
        (i) => i.categoria === cat && state.selecionados.has(i.id)
      ).length;
      btn.textContent = `${cat} (${sel}/${total})`;
      btn.addEventListener("click", () => {
        state.categoria = cat;
        renderCats();
        renderList();
      });
      el.cats.appendChild(btn);
    });
  }

  function renderList() {
    const list = itensFiltrados();
    el.list.innerHTML = "";

    if (!list.length) {
      el.list.innerHTML =
        '<p class="panel-empty">Nenhum item nesta categoria ou busca.</p>';
      return;
    }

    list.forEach((item) => {
      const row = document.createElement("label");
      row.className = "panel-row";
      const checked = state.selecionados.has(item.id);
      row.innerHTML = `
        <input type="checkbox" ${checked ? "checked" : ""} />
        <span class="panel-row-body">
          <strong>${escapeHtml(item.nome)}</strong>
          <span class="panel-row-id">${escapeHtml(item.id)}</span>
          <span class="panel-row-desc">${escapeHtml(item.descricao)}</span>
        </span>
        <span class="panel-row-cat">${escapeHtml(item.categoria)}</span>
      `;
      const input = row.querySelector("input");
      input.addEventListener("change", () => {
        if (input.checked) state.selecionados.add(item.id);
        else state.selecionados.delete(item.id);
        applySelecionadosToData();
        updateCount();
        renderCats();
      });
      el.list.appendChild(row);
    });
  }

  function render() {
    renderCats();
    renderList();
    updateCount();
  }

  function setViewVisible(panelOpen) {
    if (!el.viewHome || !el.viewPanel) return;

    if (panelOpen) {
      el.viewHome.classList.add("hidden");
      el.viewHome.hidden = true;
      el.viewPanel.classList.remove("hidden");
      el.viewPanel.hidden = false;
      document.body.dataset.view = state.kind || "panel";
    } else {
      el.viewPanel.classList.add("hidden");
      el.viewPanel.hidden = true;
      el.viewHome.classList.remove("hidden");
      el.viewHome.hidden = false;
      delete document.body.dataset.view;
    }
  }

  function updateSidebarActive() {
    document.querySelectorAll(".nav-item").forEach((btn) => {
      const isPanel = btn.classList.contains("nav-painel");
      if (isPanel) {
        const kind = btn.dataset.panelKind;
        btn.classList.toggle("active", kind === state.kind);
      } else if (state.kind) {
        btn.classList.remove("active");
      }
    });
  }

  async function open(kind) {
    if (!api()) {
      window.appToast("API indisponível.", "error");
      return;
    }

    const fetchFn =
      kind === "winget" ? api().get_winget_panel : api().get_debloat_panel;
    const data = await fetchFn();
    if (!data.ok) {
      window.appToast(data.message, "error");
      return;
    }

    state.kind = kind;
    state.data = data;
    state.categoria = null;
    window._panelBusca = "";
    if (el.search) {
      el.search.value = "";
      el.search.placeholder = "Buscar no catálogo…";
    }
    syncSelecionadosFromData();

    const runLabel =
      kind === "winget" ? "Instalar selecionados" : "Remover selecionados";
    el.run.textContent = runLabel;
    el.run.className =
      kind === "debloat" ? "btn primary danger-run" : "btn primary";

    window.appSetTitle(data.titulo, data.subtitulo);
    setViewVisible(true);
    updateSidebarActive();
    render();
  }

  function close() {
    state.kind = null;
    state.data = null;
    state.categoria = null;
    window._panelBusca = "";
    setViewVisible(false);
    updateSidebarActive();
    if (typeof window.appClearCategory === "function") {
      window.appClearCategory();
    }
    if (typeof window.appRefreshHome === "function") {
      window.appRefreshHome();
    }
  }

  function idsSelecionados() {
    return [...state.selecionados];
  }

  async function salvar() {
    const ids = idsSelecionados();
    const fn =
      state.kind === "winget"
        ? api().save_winget_selection
        : api().save_debloat_selection;
    const res = await fn(ids);
    window.appToast(res.message, res.ok ? "success" : "error");
  }

  async function executar() {
    const ids = idsSelecionados();
    if (!ids.length) {
      window.appToast("Selecione ao menos um item.", "error");
      return;
    }

    if (state.kind === "debloat") {
      const ok = await window.appConfirm({
        title: "Confirmar Debloat",
        body: `Serão removidos ${ids.length} app(s) via Winget.\nAlguns são componentes do Windows — use com cautela.\n\nContinuar?`,
        danger: true,
      });
      if (!ok) return;
    }

    const fn =
      state.kind === "winget" ? api().run_winget_install : api().run_debloat;
    const res = await fn(ids);
    window.appToast(res.message, res.ok ? "success" : "error");
  }

  function marcarCategoria(valor) {
    const cat = state.categoria;
    const alvo = cat
      ? state.data.itens.filter((i) => i.categoria === cat)
      : state.data.itens;
    alvo.forEach((i) => {
      if (valor) state.selecionados.add(i.id);
      else state.selecionados.delete(i.id);
    });
    applySelecionadosToData();
    render();
  }

  function bind() {
    if (bound) return;
    bound = true;

    el.selectAll.addEventListener("click", () => marcarCategoria(true));
    el.selectNone.addEventListener("click", () => marcarCategoria(false));
    el.save.addEventListener("click", salvar);
    el.run.addEventListener("click", executar);

    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && state.kind) close();
    });
  }

  function setBusca(texto) {
    window._panelBusca = texto;
    if (state.data) renderList();
  }

  function isOpen() {
    return !!state.kind;
  }

  window.Panels = { open, close, isOpen, setBusca, bind };
})();
