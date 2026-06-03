/**
 * Prompt Auxiliar — painel Utilitários (yt-dlp / spotdl)
 */
(function () {
  const state = { layout: "grid" };

  const ITEMS = [
    {
      id: "baixar-ytdlp",
      title: "yt-dlp",
      subtitle: "YouTube e outros sites",
      desc: "Baixa vídeo (MP4), áudio (MP3) ou playlist inteira do YouTube.",
      iconClass: "",
      icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" aria-hidden="true">
        <path d="M8 5v14l11-7L8 5z" stroke-linejoin="round"/>
      </svg>`,
    },
    {
      id: "baixar-spotdl",
      title: "spotdl",
      subtitle: "Spotify",
      desc: "Baixa música ou playlist do Spotify em MP3.",
      iconClass: "utils-card-icon-music",
      icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" aria-hidden="true">
        <path d="M9 18V5l12-2v13"/>
        <circle cx="6" cy="18" r="3"/>
        <circle cx="18" cy="16" r="3"/>
      </svg>`,
    },
  ];

  function esc(s) {
    const d = document.createElement("div");
    d.textContent = s;
    return d.innerHTML;
  }

  function setLayout(layout) {
    state.layout = layout === "list" ? "list" : "grid";
    try {
      localStorage.setItem("promptaux-utils-layout", state.layout);
    } catch (_) {
      /* ignore */
    }
    const apiRef = window.pywebview && window.pywebview.api;
    if (apiRef?.save_utils_layout) apiRef.save_utils_layout(state.layout);

    document.querySelectorAll("[data-utils-layout]").forEach((btn) => {
      btn.classList.toggle("active", btn.getAttribute("data-utils-layout") === state.layout);
    });

    const container = document.getElementById("utils-container");
    if (container) {
      container.classList.toggle("scripts-list", state.layout === "list");
      container.classList.toggle("grid", state.layout === "grid");
    }
    render();
  }

  function render() {
    const container = document.getElementById("utils-container");
    if (!container) return;
    container.innerHTML = "";

    ITEMS.forEach((item, i) => {
      if (state.layout === "list") {
        const row = document.createElement("button");
        row.type = "button";
        row.className = "panel-row utils-row";
        row.dataset.utilAction = item.id;
        row.title = item.desc;
        row.innerHTML = `
          <span class="utils-card-icon ${item.iconClass}" aria-hidden="true">${item.icon}</span>
          <span class="panel-row-body">
            <strong>${esc(item.title)}</strong>
            <span class="panel-row-desc">${esc(item.desc)}</span>
          </span>
          <span class="panel-row-meta">
            <span class="panel-row-cat">${esc(item.subtitle)}</span>
            <span class="script-run-hint">Baixar</span>
          </span>`;
        row.addEventListener("click", () => onAction(item.id));
        container.appendChild(row);
        return;
      }

      const card = document.createElement("button");
      card.type = "button";
      card.className = "card utils-card";
      card.dataset.utilAction = item.id;
      card.title = item.desc;
      card.style.animationDelay = `${Math.min(i * 0.03, 0.2)}s`;
      card.innerHTML = `
        <div class="card-head">
          <div class="card-head-top utils-card-head-top">
            <span class="utils-card-icon ${item.iconClass}" aria-hidden="true">${item.icon}</span>
            <h3>${esc(item.title)}</h3>
            <span class="card-run-top">Baixar</span>
          </div>
          <p>${esc(item.desc)}</p>
        </div>
        <div class="card-foot">
          <span class="card-foot-left">
            <span class="utils-card-sub">${esc(item.subtitle)}</span>
          </span>
        </div>`;
      card.addEventListener("click", () => onAction(item.id));
      container.appendChild(card);
    });
  }

  function onAction(id) {
    if (id && window.appRunActionById) window.appRunActionById(id);
  }

  function open() {
    const vHome = document.getElementById("view-home");
    const vPanel = document.getElementById("view-panel");
    const vTweaks = document.getElementById("view-tweaks");
    const vUtils = document.getElementById("view-utils");
    const toolbar = document.getElementById("utils-toolbar");
    if (vHome) { vHome.classList.add("hidden"); vHome.hidden = true; }
    if (vPanel) { vPanel.classList.add("hidden"); vPanel.hidden = true; }
    if (vTweaks) { vTweaks.classList.add("hidden"); vTweaks.hidden = true; }
    if (vUtils) { vUtils.classList.remove("hidden"); vUtils.hidden = false; }
    if (toolbar) toolbar.classList.remove("hidden");

    document.body.dataset.view = "utils";
    if (window.appSetTitle) {
      window.appSetTitle("Utilitários", "2 ferramentas de download");
    }
    if (window.appRenderNav) window.appRenderNav();
    render();
  }

  function close() {
    const v = document.getElementById("view-utils");
    const toolbar = document.getElementById("utils-toolbar");
    if (v) { v.classList.add("hidden"); v.hidden = true; }
    if (toolbar) toolbar.classList.add("hidden");
  }

  function isOpen() {
    const v = document.getElementById("view-utils");
    return !!(v && !v.hidden);
  }

  function bind() {
    document.querySelectorAll("[data-utils-layout]").forEach((btn) => {
      btn.addEventListener("click", () => {
        setLayout(btn.getAttribute("data-utils-layout"));
      });
    });
  }

  function initLayout(preferred) {
    let layout = preferred;
    if (!layout) {
      try {
        layout = localStorage.getItem("promptaux-utils-layout");
      } catch (_) {
        /* ignore */
      }
    }
    setLayout(layout === "list" ? "list" : "grid");
  }

  window.Utils = { open, close, isOpen, bind, initLayout, ITEMS };
})();
