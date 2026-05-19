/**
 * Tema claro / escuro — localStorage + ui_settings.json (via API).
 */
(function () {
  const STORAGE_KEY = "promptaux-theme";
  const VALID = new Set(["light", "dark"]);

  function normalize(theme) {
    const t = String(theme || "").trim().toLowerCase();
    return VALID.has(t) ? t : "dark";
  }

  function updateToggleUi(theme) {
    const btn = document.getElementById("theme-toggle");
    if (!btn) return;
    const isLight = theme === "light";
    btn.setAttribute("aria-pressed", isLight ? "true" : "false");
    btn.title = isLight ? "Usar modo escuro" : "Usar modo claro";
    btn.setAttribute("aria-label", btn.title);
    const sun = btn.querySelector(".theme-icon-sun");
    const moon = btn.querySelector(".theme-icon-moon");
    if (sun) sun.classList.toggle("hidden", isLight);
    if (moon) moon.classList.toggle("hidden", !isLight);
  }

  function applyTheme(theme, persistLocal = true) {
    const t = normalize(theme);
    document.documentElement.setAttribute("data-theme", t);
    if (persistLocal) {
      try {
        localStorage.setItem(STORAGE_KEY, t);
      } catch (_) {
        /* WebView sem storage */
      }
    }
    updateToggleUi(t);
    return t;
  }

  function readLocalTheme() {
    try {
      const t = localStorage.getItem(STORAGE_KEY);
      if (t && VALID.has(t)) return t;
    } catch (_) {
      /* ignore */
    }
    return null;
  }

  function toggleTheme() {
    const next = document.documentElement.getAttribute("data-theme") === "light" ? "dark" : "light";
    applyTheme(next);
    const api = window.pywebview && window.pywebview.api;
    if (api && typeof api.save_ui_theme === "function") {
      api.save_ui_theme(next).catch(() => {});
    }
    return next;
  }

  function bindToggle() {
    const btn = document.getElementById("theme-toggle");
    if (!btn || btn.dataset.themeBound === "1") return;
    btn.dataset.themeBound = "1";
    btn.addEventListener("click", () => toggleTheme());
  }

  async function syncFromServer() {
    const api = window.pywebview && window.pywebview.api;
    if (!api) return applyTheme(readLocalTheme() || "dark", false);
    try {
      if (typeof api.get_ui_settings === "function") {
        const res = await api.get_ui_settings();
        if (res && res.ok && res.theme) return applyTheme(res.theme);
      }
    } catch (_) {
      /* ignore */
    }
    return applyTheme(readLocalTheme() || "dark", false);
  }

  window.PromptAuxTheme = {
    apply: applyTheme,
    toggle: toggleTheme,
    bindToggle,
    syncFromServer,
    normalize,
  };

  applyTheme(readLocalTheme() || "dark", false);
})();
