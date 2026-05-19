/**
 * Prompt Auxiliar — Tweaks Windows
 * Detecta e aplica ajustes de configuração do sistema via registro/PowerShell.
 */
(function () {
  const state = {
    tweaks: [],
    categorias: {},
    activeCat: null,
    busca: "",
    busy: false,
    loaded: false,
    detecting: false,
  };

  function api() {
    return window.pywebview && window.pywebview.api;
  }

  function esc(s) {
    const d = document.createElement("div");
    d.textContent = s;
    return d.innerHTML;
  }

  // ── Views ───────────────────────────────────────────────────────────────
  function open() {
    const vHome = document.getElementById("view-home");
    const vPanel = document.getElementById("view-panel");
    const vTweaks = document.getElementById("view-tweaks");
    if (vHome) { vHome.classList.add("hidden"); vHome.hidden = true; }
    if (vPanel) { vPanel.classList.add("hidden"); vPanel.hidden = true; }
    if (vTweaks) { vTweaks.classList.remove("hidden"); vTweaks.hidden = false; }

    document.body.dataset.view = "tweaks";
    if (window.appSetTitle) {
      window.appSetTitle("Tweaks Windows", "Ajustes de configuração do sistema");
    }

    if (!state.loaded) {
      _loadAndDetect();
    } else {
      render();
    }
  }

  function close() {
    const v = document.getElementById("view-tweaks");
    if (v) { v.classList.add("hidden"); v.hidden = true; }
  }

  function isOpen() {
    const v = document.getElementById("view-tweaks");
    return !!(v && !v.hidden);
  }

  // ── Data loading ────────────────────────────────────────────────────────
  async function _loadAndDetect() {
    state.detecting = true;
    _renderDetecting();
    _updateToolbar();

    try {
      // Step 1: load catalog immediately (no detection)
      const cat = await api().get_tweaks();
      if (cat && cat.ok) {
        state.tweaks = cat.tweaks.map(tw => ({ ...tw, _selected: false }));
        state.categorias = cat.categorias || {};
        state.loaded = true;
        render();
      }
      // Step 2: detect state (runs PowerShell, takes ~3–8 s)
      const det = await api().detect_tweaks();
      if (det && det.states) {
        state.tweaks.forEach(tw => {
          const v = det.states[tw.id];
          if (v !== undefined) tw.aplicado = v;
        });
      }
    } catch (e) {
      if (window.appToast) window.appToast(String(e), "error");
    } finally {
      state.detecting = false;
      render();
    }
  }

  async function redetect() {
    if (state.detecting) return;
    state.tweaks.forEach(tw => { tw.aplicado = null; });
    state.detecting = true;
    render();
    try {
      const det = await api().detect_tweaks();
      if (det && det.states) {
        state.tweaks.forEach(tw => {
          const v = det.states[tw.id];
          if (v !== undefined) tw.aplicado = v;
        });
      }
    } catch (e) {
      if (window.appToast) window.appToast(String(e), "error");
    } finally {
      state.detecting = false;
      render();
    }
  }

  // ── Filtering ────────────────────────────────────────────────────────────
  function filtered() {
    let list = state.tweaks.slice();
    if (state.activeCat) {
      list = list.filter(t => t.categoria === state.activeCat);
    }
    if (state.busca) {
      const q = state.busca.toLowerCase();
      list = list.filter(
        t => t.label.toLowerCase().includes(q) || t.descricao.toLowerCase().includes(q)
      );
    }
    return list;
  }

  // ── Rendering ────────────────────────────────────────────────────────────
  function render() {
    _renderCats();
    _renderList();
    _renderCount();
    _updateToolbar();
  }

  function _renderDetecting() {
    const el = document.getElementById("tweaks-list");
    if (!el) return;
    el.innerHTML =
      '<div class="tweaks-loading"><span class="tweaks-spinner"></span><span>Detectando configurações...</span></div>';
  }

  function _renderCats() {
    const el = document.getElementById("tweaks-cats");
    if (!el) return;
    el.innerHTML = "";

    function chip(label, key) {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "panel-cat" + (!key && !state.activeCat ? " active" : key === state.activeCat ? " active" : "");
      btn.textContent = label;
      btn.addEventListener("click", () => {
        state.activeCat = state.activeCat === key ? null : key;
        render();
      });
      el.appendChild(btn);
    }

    chip("Todos", null);
    Object.entries(state.categorias).forEach(([k, label]) => chip(label, k));
  }

  function _badgeHtml(tw) {
    if (tw.aplicado === null || tw.aplicado === undefined) {
      return state.detecting
        ? '<span class="tweak-badge tweak-badge-detecting">...</span>'
        : '<span class="tweak-badge tweak-badge-unknown">?</span>';
    }
    return tw.aplicado
      ? '<span class="tweak-badge tweak-badge-active">Ativo</span>'
      : '<span class="tweak-badge tweak-badge-inactive">Inativo</span>';
  }

  function _metaHtml(tw) {
    let s = "";
    if (tw.requer_admin) {
      s += '<span class="tweak-icon-admin" title="Requer privilégio de Administrador">🔒</span>';
    }
    if (tw.requer_reiniciar) {
      s += '<span class="tweak-icon-restart" title="Requer reinicialização do Windows">↺</span>';
    }
    return s;
  }

  function _renderList() {
    const el = document.getElementById("tweaks-list");
    if (!el) return;

    if (!state.loaded && state.detecting) {
      _renderDetecting();
      return;
    }

    const list = filtered();
    if (!list.length) {
      el.innerHTML = `
        <div class="empty-state">
          <svg class="empty-state-icon" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true">
            <circle cx="21" cy="21" r="13"/>
            <line x1="30.5" y1="30.5" x2="42" y2="42" stroke-linecap="round"/>
          </svg>
          <h3>Nenhum ajuste encontrado</h3>
          <p>Tente outra busca ou selecione outra categoria.</p>
        </div>`;
      return;
    }

    el.innerHTML = "";
    list.forEach(tw => {
      const row = document.createElement("div");
      row.className = "panel-row tweaks-row";
      row.dataset.id = tw.id;

      const cb = document.createElement("input");
      cb.type = "checkbox";
      cb.checked = !!tw._selected;
      cb.addEventListener("change", () => {
        tw._selected = cb.checked;
        _renderCount();
        _updateToolbar();
      });

      const body = document.createElement("span");
      body.className = "panel-row-body";
      body.innerHTML =
        `<strong>${esc(tw.label)}</strong>` +
        `<span class="panel-row-desc">${esc(tw.descricao)}</span>`;

      const meta = document.createElement("span");
      meta.className = "tweaks-row-meta";
      meta.innerHTML = _metaHtml(tw) + _badgeHtml(tw);

      row.appendChild(cb);
      row.appendChild(body);
      row.appendChild(meta);

      row.addEventListener("click", e => {
        if (e.target === cb) return;
        cb.checked = !cb.checked;
        tw._selected = cb.checked;
        _renderCount();
        _updateToolbar();
      });

      el.appendChild(row);
    });
  }

  function _renderCount() {
    const el = document.getElementById("tweaks-selected-count");
    if (!el) return;
    const n = state.tweaks.filter(t => t._selected).length;
    el.textContent = n === 0 ? "0 selecionados" : `${n} selecionado(s)`;
  }

  function _updateToolbar() {
    const detectBtn = document.getElementById("tweaks-detect-btn");
    const applyBtn = document.getElementById("tweaks-apply-btn");
    if (detectBtn) {
      detectBtn.disabled = state.detecting || state.busy;
      detectBtn.textContent = state.detecting ? "Detectando…" : "Detectar estado";
    }
    if (applyBtn) {
      const sel = state.tweaks.filter(t => t._selected).length;
      applyBtn.disabled = sel === 0 || state.busy || state.detecting;
    }
  }

  // ── Bind events ──────────────────────────────────────────────────────────
  function bind() {
    const detectBtn = document.getElementById("tweaks-detect-btn");
    const applyBtn = document.getElementById("tweaks-apply-btn");
    const selAll = document.getElementById("tweaks-select-all");
    const selNone = document.getElementById("tweaks-select-none");

    if (detectBtn) {
      detectBtn.addEventListener("click", () => redetect());
    }

    if (applyBtn) {
      applyBtn.addEventListener("click", async () => {
        const ids = state.tweaks.filter(t => t._selected).map(t => t.id);
        if (!ids.length) return;

        const needsAdmin = state.tweaks.some(t => t._selected && t.requer_admin);
        const needsRestart = state.tweaks.some(t => t._selected && t.requer_reiniciar);

        let body = `${ids.length} ajuste(s) serão aplicados via PowerShell.`;
        if (needsAdmin) body += "\n\n🔒 Alguns requerem privilégio de Administrador (UAC será solicitado).";
        if (needsRestart) body += "\n\n↺ Alguns requerem reinicialização para ter efeito.";

        const ok = await (window.appConfirm
          ? window.appConfirm({ title: "Aplicar ajustes", body })
          : Promise.resolve(true));
        if (!ok) return;

        state.busy = true;
        _updateToolbar();
        try {
          const res = await api().apply_tweaks(ids);
          if (window.appToast) window.appToast(res.message, res.ok ? "success" : "error");
        } catch (e) {
          if (window.appToast) window.appToast(String(e), "error");
        } finally {
          state.busy = false;
          _updateToolbar();
        }
      });
    }

    if (selAll) {
      selAll.addEventListener("click", () => {
        filtered().forEach(t => { t._selected = true; });
        _renderList();
        _renderCount();
        _updateToolbar();
      });
    }

    if (selNone) {
      selNone.addEventListener("click", () => {
        state.tweaks.forEach(t => { t._selected = false; });
        _renderList();
        _renderCount();
        _updateToolbar();
      });
    }
  }

  function setBusca(q) {
    state.busca = q;
    render();
  }

  window.Tweaks = { open, close, isOpen, setBusca, bind };
})();
