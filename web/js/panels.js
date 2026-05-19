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
    selectInstalled: $("#panel-select-installed"),
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
  let floatTipEl = null;

  function ensureFloatTip() {
    if (floatTipEl) return floatTipEl;
    floatTipEl = document.createElement("div");
    floatTipEl.id = "panel-float-tooltip";
    floatTipEl.className = "panel-float-tooltip";
    floatTipEl.hidden = true;
    document.body.appendChild(floatTipEl);
    return floatTipEl;
  }

  function positionFloatTip(row) {
    const tip = floatTipEl;
    if (!tip || tip.hidden) return;
    const rect = row.getBoundingClientRect();
    const margin = 10;
    tip.style.left = "0px";
    tip.style.top = "0px";
    tip.style.maxWidth = `${Math.min(420, window.innerWidth - 24)}px`;
    const tipRect = tip.getBoundingClientRect();
    let left = rect.left;
    let top = rect.bottom + margin;
    if (top + tipRect.height > window.innerHeight - 8) {
      top = rect.top - tipRect.height - margin;
    }
    if (left + tipRect.width > window.innerWidth - 12) {
      left = window.innerWidth - tipRect.width - 12;
    }
    if (left < 12) left = 12;
    if (top < 8) top = rect.bottom + margin;
    tip.style.left = `${left}px`;
    tip.style.top = `${top}px`;
  }

  function showFloatTip(row, text) {
    if (!text) return;
    const tip = ensureFloatTip();
    tip.textContent = text;
    tip.hidden = false;
    positionFloatTip(row);
  }

  function hideFloatTip() {
    if (floatTipEl) floatTipEl.hidden = true;
  }

  function bindRowTooltip(row, text) {
    row.dataset.tip = text;
    row.addEventListener("mouseenter", () => showFloatTip(row, text));
    row.addEventListener("mouseleave", hideFloatTip);
    row.addEventListener("mousemove", () => positionFloatTip(row));
  }

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
          (i.descricao || "").toLowerCase().includes(q)
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
      const tip = item.descricao_detalhada || item.descricao || item.nome;
      const checked = state.selecionados.has(item.id);
      const instaladoTag = item.instalado
        ? '<span class="tag tag-installed">Instalado</span>'
        : "";
      row.innerHTML = `
        <input type="checkbox" ${checked ? "checked" : ""} />
        <span class="panel-row-body">
          <strong>${escapeHtml(item.nome)}</strong>
          <span class="panel-row-id">${escapeHtml(item.id)}</span>
          <span class="panel-row-desc">${escapeHtml(item.descricao || "")}</span>
        </span>
        <span class="panel-row-meta">
          ${instaladoTag}
          <span class="panel-row-cat">${escapeHtml(item.categoria)}</span>
        </span>
      `;
      bindRowTooltip(row, tip);
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
    state.kind = kind;
    window.appSetTitle(
      kind === "winget" ? "Instalar via Winget" : "Debloat Windows 11",
      "Lendo software instalado (winget list)…"
    );
    setViewVisible(true);
    updateSidebarActive();
    const data = await fetchFn();
    if (!data.ok) {
      window.appToast(data.message, "error");
      return;
    }

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

    const sub =
      data.total_instalados != null
        ? `${data.subtitulo} · ${data.total_instalados} instalado(s) no PC`
        : data.subtitulo;
    window.appSetTitle(data.titulo, sub);
    atualizarToolbarPainel();
    render();
  }

  function close() {
    hideFloatTip();
    state.kind = null;
    state.data = null;
    state.categoria = null;
    window._panelBusca = "";
    if (el.selectInstalled) {
      el.selectInstalled.classList.add("hidden");
      el.selectInstalled.hidden = true;
    }
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

  function selecionarInstalados() {
    if (!state.data) return;
    state.selecionados.clear();
    let n = 0;
    state.data.itens.forEach((i) => {
      if (i.instalado) {
        state.selecionados.add(i.id);
        n += 1;
      }
    });
    applySelecionadosToData();
    render();
    window.appToast(
      n
        ? `${n} app(s) instalado(s) selecionado(s) para remoção.`
        : "Nenhum item do catálogo foi detectado como instalado (winget list).",
      n ? "success" : "info"
    );
  }

  function atualizarToolbarPainel() {
    if (!el.selectInstalled) return;
    const debloat = state.kind === "debloat";
    el.selectInstalled.classList.toggle("hidden", !debloat);
    el.selectInstalled.hidden = !debloat;
  }

  function bind() {
    if (bound) return;
    bound = true;

    el.selectAll.addEventListener("click", () => marcarCategoria(true));
    el.selectNone.addEventListener("click", () => marcarCategoria(false));
    el.selectInstalled.addEventListener("click", selecionarInstalados);
    el.save.addEventListener("click", salvar);
    el.run.addEventListener("click", executar);
    const listWrap = el.list?.parentElement;
    if (listWrap) {
      listWrap.addEventListener("scroll", hideFloatTip, { passive: true });
    }

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
