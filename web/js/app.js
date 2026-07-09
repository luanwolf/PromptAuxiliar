/**
 * Prompt Auxiliar — scripts .bat + painéis Winget/Debloat
 */
(function () {
  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

  const PAINEL_KINDS = ["winget", "debloat"];

  const state = {
    catalog: null,
    strings: {},
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

  function str(path, fallback = "") {
    const parts = String(path).split(".");
    let o = state.strings;
    for (const p of parts) {
      if (!o || typeof o !== "object" || Array.isArray(o)) return fallback;
      o = o[p];
    }
    if (o == null || o === "") return fallback;
    if (typeof o !== "string" && typeof o !== "number") return fallback;
    return String(o);
  }

  function strFmt(path, vars, fallback = "") {
    let t = str(path, fallback);
    if (vars) {
      Object.entries(vars).forEach(([k, v]) => {
        t = t.replace(new RegExp(`\\{${k}\\}`, "g"), String(v));
      });
    }
    return t;
  }

  function panelNavLabel(kind) {
    return str(`nav.paineis.${kind}`, kind === "winget" ? "Painel Winget" : "Painel Debloat");
  }

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

  function _setBtnLabel(btn, text) {
    const span = btn.querySelector(".btn-label");
    if (span) span.textContent = text;
    else btn.textContent = text;
  }

  function setUpdateAvailability(info) {
    const btn = document.querySelector('[data-action="check-update"]');
    if (!btn || !info) return;
    const pending = !!info.update_available;
    state.pendingUpdate = pending ? info : null;
    btn.classList.toggle("btn-update-pending", pending);
    _setBtnLabel(btn, pending ? str("footer.atualizacao_disponivel", "Atualização disponível") : str("footer.verificar_atualizacao", "Verificar atualização"));
    if (ui.version) {
      const local = info.local || info.installed_version || info.version;
      ui.version.textContent = pending && info.remote
        ? `v${local} → v${info.remote}`
        : local ? `v${local}` : "v—";
    }
  }

  async function confirmAndLaunchUpdate(info) {
    const r = info || state.pendingUpdate;
    if (!r?.update_available) return false;
    const corpo = strFmt(
      "modais.update.corpo",
      { local: r.local, remote: r.remote },
      `Versão instalada: v${r.local}\nNova versão: v${r.remote}\n\nO app será fechado e o PowerShell executará o instalador oficial.`
    );
    const atualizar = await showAppModal({
      title: str("modais.update.titulo", "Atualização disponível"),
      body: corpo,
      variant: "update",
      confirmLabel: str("modais.atualizar_agora", "Atualizar agora"),
      cancelLabel: str("modais.depois", "Depois"),
    });
    if (!atualizar) return false;
    const ur = await api().launch_app_update();
    toast(ur.message, ur.ok ? "success" : "error");
    return ur.ok;
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
      cancelBtn.textContent = cancelLabel || (isUpdate ? str("modais.depois", "Depois") : str("modais.cancelar", "Cancelar"));
      cancelBtn.hidden = isAlert;
      cancelBtn.classList.toggle("hidden", isAlert);
      confirmBtn.textContent =
        confirmLabel ||
        (isAlert ? str("modais.ok", "OK") : isUpdate ? str("modais.atualizar", "Atualizar") : str("modais.confirmar", "Confirmar"));
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

  function confirmDialog(opts) {
    return showAppModal({ ...opts, variant: "confirm" });
  }

  async function showYtdlpSitesModal() {
    const dlg = document.getElementById("ytdlp-sites-modal");
    const listEl = document.getElementById("ytdlp-sites-list");
    const countEl = document.getElementById("ytdlp-sites-count");
    const filterIn = document.getElementById("ytdlp-sites-filter");
    const loadingEl = document.getElementById("ytdlp-sites-loading");
    const closeBtn = document.getElementById("ytdlp-sites-close");
    if (!dlg || !listEl || !filterIn) return;

    let sites = [];
    let totalAll = 0;
    const render = (items) => {
      listEl.innerHTML = items.map((s) => `<li>${escapeHtml(s)}</li>`).join("");
      if (!countEl) return;
      if (!sites.length) {
        countEl.textContent = "";
        return;
      }
      const q = filterIn.value.trim();
      if (q) {
        countEl.textContent = strFmt(
          "modais.ytdlp_sites.count_filtrado",
          { shown: items.length, total: sites.length },
          `${items.length} de ${sites.length} sites`
        );
      } else {
        countEl.textContent = strFmt(
          "modais.ytdlp_sites.count",
          { shown: sites.length, total: totalAll },
          `${sites.length} de ${totalAll} sites principais`
        );
      }
    };

    filterIn.value = "";
    listEl.innerHTML = "";
    if (countEl) countEl.textContent = "";
    loadingEl?.classList.remove("hidden");
    listEl.classList.add("hidden");
    filterIn.classList.add("hidden");

    const close = () => {
      if (dlg.open) dlg.close();
    };

    closeBtn?.addEventListener("click", close, { once: true });
    dlg.addEventListener(
      "cancel",
      (e) => {
        e.preventDefault();
        close();
      },
      { once: true }
    );
    dlg.showModal();

    try {
      const r = await api().list_ytdlp_sites();
      loadingEl?.classList.add("hidden");
      if (!r?.ok) {
        toast(r?.message || "Não foi possível listar os sites.", "error");
        close();
        return;
      }
      sites = r.sites || [];
      totalAll = r.total ?? sites.length;
      listEl.classList.remove("hidden");
      filterIn.classList.remove("hidden");
      render(sites);
      filterIn.oninput = () => {
        const q = filterIn.value.trim().toLowerCase();
        render(q ? sites.filter((s) => s.toLowerCase().includes(q)) : sites);
      };
      setTimeout(() => filterIn.focus(), 80);
    } catch (e) {
      loadingEl?.classList.add("hidden");
      toast(String(e), "error");
      close();
    }
  }

  /**
   * Modal para Utilitários (yt-dlp / spotdl): URL, pasta e opcionalmente vídeo/áudio.
   * @returns {Promise<{url:string,dest:string,mode?:string}|null>}
   */
  function showUtilModal(acao) {
    const dlg = document.getElementById("util-modal");
    const form = dlg?.querySelector("form");
    const titleEl = document.getElementById("util-modal-title");
    const urlIn = document.getElementById("util-url");
    const destIn = document.getElementById("util-dest");
    const browseBtn = document.getElementById("util-browse");
    const sitesBtn = document.getElementById("util-sites-btn");
    const modeWrap = document.getElementById("util-mode-wrap");
    const cancelBtn = document.getElementById("util-cancel");
    if (!dlg || !form || !urlIn || !destIn) return Promise.resolve(null);

    const showMode = acao.id === "baixar-ytdlp";
    const playlistWrap = document.getElementById("util-playlist-wrap");
    const playlistCb = document.getElementById("util-playlist");
    if (titleEl) titleEl.textContent = acao.nome;
    if (modeWrap) modeWrap.classList.toggle("hidden", !showMode);
    if (playlistWrap) playlistWrap.classList.toggle("hidden", !showMode);
    if (sitesBtn) sitesBtn.classList.toggle("hidden", !showMode);
    if (playlistCb && showMode) playlistCb.checked = true;

    urlIn.value = "";
    destIn.value = "";
    const videoRadio = form.querySelector('input[name="util-mode"][value="video"]');
    if (videoRadio) videoRadio.checked = true;

    return new Promise((resolve) => {
      let done = false;
      const finish = (value) => {
        if (done) return;
        done = true;
        if (dlg.open) dlg.close();
        resolve(value);
      };

      const onBrowse = async () => {
        try {
          const r = await api().pick_folder();
          if (r.ok && r.path) destIn.value = r.path;
          else if (!r.ok && r.message) toast(r.message, "error");
        } catch (e) {
          toast(String(e), "error");
        }
      };

      const onCancel = () => finish(null);
      const onSubmit = (e) => {
        e.preventDefault();
        const url = urlIn.value.trim();
        const dest = destIn.value.trim();
        if (!url || !dest) {
          toast(str("modais.util_download.erro_url_destino", "Informe o link e a pasta de destino."), "error");
          return;
        }
        const params = { url, dest };
        if (showMode) {
          const modeEl = form.querySelector('input[name="util-mode"]:checked');
          params.mode = modeEl?.value === "audio" ? "audio" : "video";
          params.playlist = playlistCb?.checked ? "1" : "0";
        }
        finish(params);
      };

      const onSites = () => {
        showYtdlpSitesModal();
      };

      browseBtn?.addEventListener("click", onBrowse, { once: true });
      sitesBtn?.addEventListener("click", onSites, { once: true });
      cancelBtn?.addEventListener("click", onCancel, { once: true });
      form.addEventListener("submit", onSubmit, { once: true });
      dlg.addEventListener(
        "cancel",
        (e) => {
          e.preventDefault();
          finish(null);
        },
        { once: true }
      );
      dlg.showModal();
      setTimeout(() => urlIn.focus(), 80);
    });
  }

  const IMAGEMAGICK_FORMATS = [
    { id: "jpg", label: "JPEG", aliases: ["jpg", "jpeg"] },
    { id: "png", label: "PNG", aliases: ["png"] },
    { id: "webp", label: "WebP", aliases: ["webp"] },
    { id: "gif", label: "GIF", aliases: ["gif"] },
    { id: "bmp", label: "BMP", aliases: ["bmp"] },
    { id: "tiff", label: "TIFF", aliases: ["tiff", "tif"] },
    { id: "pdf", label: "PDF", aliases: ["pdf"] },
    { id: "ico", label: "ICO", aliases: ["ico"] },
    { id: "avif", label: "AVIF", aliases: ["avif"] },
  ];

  function sourceExt(path) {
    const m = String(path || "").trim().toLowerCase().match(/\.([a-z0-9]+)$/);
    return m ? m[1] : "";
  }

  const WIN_INVALID_NAME = /[\\/:*?"<>|]/;

  function sourceBasename(path) {
    const name = String(path || "").trim().replace(/\\/g, "/").split("/").pop() || "";
    const dot = name.lastIndexOf(".");
    return dot > 0 ? name.slice(0, dot) : name;
  }

  function formatOutputExt(format) {
    const f = String(format || "").toLowerCase();
    if (f === "jpeg") return "jpg";
    if (f === "tif") return "tiff";
    return f;
  }

  function sanitizeOutname(raw) {
    let name = String(raw || "").trim();
    if (!name) return "";
    const dot = name.lastIndexOf(".");
    if (dot > 0) name = name.slice(0, dot);
    name = name.trim();
    if (!name || WIN_INVALID_NAME.test(name)) return null;
    if (name.endsWith(".") || name.endsWith(" ")) return null;
    return name;
  }

  function refreshImagemFormatOptions(formatSel, srcPath, hintEl, outnameIn) {
    if (!formatSel) return;
    const ext = sourceExt(srcPath);
    let firstEnabled = null;
    Array.from(formatSel.options).forEach((opt) => {
      if (!opt.value) return;
      const fmt = IMAGEMAGICK_FORMATS.find((f) => f.id === opt.value);
      const same = fmt && ext && fmt.aliases.includes(ext);
      opt.hidden = same;
      opt.disabled = same;
      if (!same && firstEnabled === null) firstEnabled = opt.value;
    });
    const current = formatSel.options[formatSel.selectedIndex];
    if (!current?.value || current.disabled) {
      formatSel.value = firstEnabled || "";
    }
    refreshImagemOutPreview(outnameIn, formatSel, hintEl, srcPath, ext);
  }

  function refreshImagemOutPreview(outnameIn, formatSel, hintEl, srcPath, srcExt) {
    if (!hintEl) return;
    const parts = [];
    if (srcExt) {
      parts.push(
        strFmt("modais.util_imagem.hint_origem", { ext: srcExt }, `Origem detectada: .${srcExt}. Formatos iguais ao original foram ocultados.`)
      );
    }
    const format = formatSel?.value?.trim();
    const base = sanitizeOutname(outnameIn?.value) || sourceBasename(srcPath);
    if (format && base) {
      parts.push(
        strFmt("modais.util_imagem.hint_arquivo", { nome: base, ext: formatOutputExt(format) }, `Arquivo final: ${base}.${formatOutputExt(format)}`)
      );
    }
    if (parts.length) {
      hintEl.textContent = parts.join(" ");
      hintEl.classList.remove("hidden");
    } else {
      hintEl.textContent = "";
      hintEl.classList.add("hidden");
    }
  }

  /**
   * Modal ImageMagick: arquivo, pasta de destino, formato e nome opcional.
   * @returns {Promise<{src:string,dest:string,format:string,outname?:string}|null>}
   */
  function showUtilImagemModal(acao) {
    const dlg = document.getElementById("util-imagem-modal");
    const form = dlg?.querySelector("form");
    const titleEl = document.getElementById("util-imagem-modal-title");
    const srcIn = document.getElementById("util-imagem-src");
    const destIn = document.getElementById("util-imagem-dest");
    const formatSel = document.getElementById("util-imagem-format");
    const outnameIn = document.getElementById("util-imagem-outname");
    const hintEl = document.getElementById("util-imagem-hint");
    const browseSrcBtn = document.getElementById("util-imagem-browse-src");
    const browseDestBtn = document.getElementById("util-imagem-browse-dest");
    const cancelBtn = document.getElementById("util-imagem-cancel");
    if (!dlg || !form || !srcIn || !destIn || !formatSel) return Promise.resolve(null);

    if (titleEl) titleEl.textContent = acao.nome;
    srcIn.value = "";
    destIn.value = "";
    if (outnameIn) outnameIn.value = "";
    formatSel.selectedIndex = 0;
    if (hintEl) {
      hintEl.textContent = "";
      hintEl.classList.add("hidden");
    }

    const onFormatChange = () => {
      refreshImagemOutPreview(outnameIn, formatSel, hintEl, srcIn.value, sourceExt(srcIn.value));
    };
    const onOutnameInput = () => {
      refreshImagemOutPreview(outnameIn, formatSel, hintEl, srcIn.value, sourceExt(srcIn.value));
    };

    return new Promise((resolve) => {
      let done = false;
      const finish = (value) => {
        if (done) return;
        done = true;
        formatSel.removeEventListener("change", onFormatChange);
        outnameIn?.removeEventListener("input", onOutnameInput);
        if (dlg.open) dlg.close();
        resolve(value);
      };

      const onBrowseSrc = async () => {
        try {
          const r = await api().pick_file();
          if (r.ok && r.path) {
            srcIn.value = r.path;
            if (outnameIn) outnameIn.value = sourceBasename(r.path);
            refreshImagemFormatOptions(formatSel, r.path, hintEl, outnameIn);
          } else if (!r.ok && r.message) toast(r.message, "error");
        } catch (e) {
          toast(String(e), "error");
        }
      };

      const onBrowseDest = async () => {
        try {
          const r = await api().pick_folder();
          if (r.ok && r.path) destIn.value = r.path;
          else if (!r.ok && r.message) toast(r.message, "error");
        } catch (e) {
          toast(String(e), "error");
        }
      };

      const onCancel = () => finish(null);
      const onSubmit = (e) => {
        e.preventDefault();
        const src = srcIn.value.trim();
        const dest = destIn.value.trim();
        const format = formatSel.value.trim();
        const rawOutname = outnameIn?.value.trim() || "";
        if (!src || !dest || !format) {
          toast(str("modais.util_imagem.erro_campos", "Informe o arquivo, a pasta de destino e o formato."), "error");
          return;
        }
        let outname = "";
        if (rawOutname) {
          const clean = sanitizeOutname(rawOutname);
          if (!clean) {
            toast(str("modais.util_imagem.erro_nome", 'Nome inválido. Evite \\ / : * ? " < > | e não use extensão.'), "error");
            return;
          }
          outname = clean;
        }
        const params = { src, dest, format };
        if (outname) params.outname = outname;
        finish(params);
      };

      formatSel.addEventListener("change", onFormatChange);
      outnameIn?.addEventListener("input", onOutnameInput);
      browseSrcBtn?.addEventListener("click", onBrowseSrc, { once: true });
      browseDestBtn?.addEventListener("click", onBrowseDest, { once: true });
      cancelBtn?.addEventListener("click", onCancel, { once: true });
      form.addEventListener("submit", onSubmit, { once: true });
      dlg.addEventListener(
        "cancel",
        (e) => {
          e.preventDefault();
          finish(null);
        },
        { once: true }
      );
      dlg.showModal();
      setTimeout(() => browseSrcBtn?.focus(), 80);
    });
  }

  function escapeHtml(s) {
    const d = document.createElement("div");
    d.textContent = s;
    return d.innerHTML;
  }

  function renderNav() {
    if (!ui.nav) return;
    ui.nav.innerHTML = "";
    const curView = document.body.dataset.view;
    const acoes = state.catalog?.acoes;
    if (!Array.isArray(acoes)) return;

    PAINEL_KINDS.forEach((kind) => {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "nav-item nav-painel";
      btn.dataset.panelKind = kind;
      if (curView === kind) btn.classList.add("active");
      btn.textContent = panelNavLabel(kind);
      btn.addEventListener("click", () => {
        if (window.Panels.isOpen() && document.body.dataset.view === kind) {
          window.Panels.close();
        } else {
          if (window.Utils?.isOpen()) window.Utils.close();
          if (window.Tweaks?.isOpen()) window.Tweaks.close();
          window.Panels.open(kind);
        }
      });
      ui.nav.appendChild(btn);
    });

    const divUtils = document.createElement("div");
    divUtils.className = "nav-divider";
    ui.nav.appendChild(divUtils);

    const utilsBtn = document.createElement("button");
    utilsBtn.type = "button";
    utilsBtn.className = `nav-item nav-utils${curView === "utils" ? " active" : ""}`;
    utilsBtn.textContent = str("nav.utilitarios", "Utilitários");
    utilsBtn.addEventListener("click", () => {
      if (window.Utils?.isOpen()) {
        window.Utils.close();
        openScriptsView();
      } else {
        if (window.Panels?.isOpen()) window.Panels.close();
        if (window.Tweaks?.isOpen()) window.Tweaks.close();
        window.Utils?.open();
        renderNav();
      }
    });
    ui.nav.appendChild(utilsBtn);

    const divTweaks = document.createElement("div");
    divTweaks.className = "nav-divider";
    ui.nav.appendChild(divTweaks);

    const tweaksBtn = document.createElement("button");
    tweaksBtn.type = "button";
    tweaksBtn.className = `nav-item nav-tweaks${curView === "tweaks" ? " active" : ""}`;
    tweaksBtn.textContent = str("nav.tweaks", "Tweaks Windows");
    tweaksBtn.addEventListener("click", () => {
      if (window.Tweaks?.isOpen()) {
        window.Tweaks.close();
        openScriptsView();
      } else {
        if (window.Panels?.isOpen()) window.Panels.close();
        if (window.Utils?.isOpen()) window.Utils.close();
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
    const scriptCount = acoes.filter((a) => a.categoria !== "Utilitários").length;
    scriptsBtn.className = `nav-item nav-scripts${
      curView === "scripts" &&
      !window.Panels?.isOpen() &&
      !window.Tweaks?.isOpen() &&
      !window.Utils?.isOpen()
        ? " active"
        : ""
    }`;
    scriptsBtn.innerHTML = `${str("nav.scripts", "Scripts")} <span class="badge">${scriptCount}</span>`;
    scriptsBtn.addEventListener("click", () => openScriptsView());
    ui.nav.appendChild(scriptsBtn);
  }

  function openScriptsView() {
    if (window.Panels?.isOpen()) window.Panels.close();
    if (window.Tweaks?.isOpen()) window.Tweaks.close();
    if (window.Utils?.isOpen()) window.Utils.close();
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
    let list = state.catalog.acoes.filter((a) => a.categoria !== "Utilitários");
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
    ui.title.textContent = str("scripts.titulo", "Scripts");
    ui.subtitle.textContent = strFmt("scripts.subtitulo", { count: list.length }, `${list.length} script(s) disponíveis`);
    if (ui.scriptsToolbar) ui.scriptsToolbar.classList.remove("hidden");
    if (!list.length) {
      ui.scriptsGrid.innerHTML = `
        <div class="empty-state">
          <svg class="empty-state-icon" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true">
            <circle cx="21" cy="21" r="13"/>
            <line x1="30.5" y1="30.5" x2="42" y2="42" stroke-linecap="round"/>
          </svg>
          <h3>${escapeHtml(str("scripts.vazio_titulo", "Nenhum resultado"))}</h3>
          <p>${escapeHtml(str("scripts.vazio_descricao", "Tente outra palavra-chave ou limpe a busca."))}</p>
        </div>`;
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
            ? `<span class="tag risco-${acao.risco}">${acao.risco === "perigo" ? str("scripts.risco_alto", "Alto risco") : str("scripts.risco_atencao", "Atenção")}</span>`
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
            <span class="script-run-hint">${escapeHtml(str("scripts.executar", "Executar"))}</span>
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
          ? `<span class="tag risco-${acao.risco}">${acao.risco === "perigo" ? str("scripts.risco_alto", "Alto risco") : str("scripts.risco_atencao", "Atenção")}</span>`
          : "";
      card.innerHTML = `<div class="card-head"><div class="card-head-top"><h3>${escapeHtml(acao.nome)}</h3><span class="card-run-top">${escapeHtml(str("scripts.executar", "Executar"))}</span></div><p>${escapeHtml(acao.descricao)}</p></div><div class="card-foot"><span class="card-foot-left"><span class="script-row-cat">${escapeHtml(acao.categoria)}</span></span><span class="card-foot-right">${tag}</span></div>`;
      card.addEventListener("click", () => runAction(acao));
      ui.scriptsGrid.appendChild(card);
    });
  }

  async function runAction(acao) {
    if (state.busy) {
      toast(str("scripts.aguarde_acao", "Aguarde — outra ação em execução."), "error");
      return;
    }

    if (acao.interativo === "util") {
      const params = await showUtilModal(acao);
      if (!params) return;
      state.busy = true;
      try {
        const res = await api().run_action_params(acao.id, params);
        toast(res.message, res.ok ? "success" : "error");
      } catch (e) {
        toast(String(e), "error");
      } finally {
        state.busy = false;
      }
      return;
    }

    if (acao.interativo === "util-imagem") {
      const params = await showUtilImagemModal(acao);
      if (!params) return;
      state.busy = true;
      try {
        const res = await api().run_action_params(acao.id, params);
        toast(res.message, res.ok ? "success" : "error");
      } catch (e) {
        toast(String(e), "error");
      } finally {
        state.busy = false;
      }
      return;
    }

    if (acao.risco === "perigo" || acao.risco === "aviso") {
      const ok = await confirmDialog({
        title: acao.risco === "perigo" ? str("scripts.acao_sensivel", "Ação sensível") : str("scripts.confirmar", "Confirmar"),
        body: strFmt("scripts.confirmar_continuar", { descricao: acao.descricao }, `${acao.descricao}\n\nContinuar?`),
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

  function applyChromeStrings() {
    document.title = str("app.titulo_html", "Prompt Auxiliar");
    const bootTitle = document.querySelector(".boot-title");
    if (bootTitle) bootTitle.textContent = str("app.nome", "Prompt Auxiliar");
    const brandName = document.querySelector(".brand-name");
    if (brandName) brandName.textContent = str("app.nome", "Prompt Auxiliar");
    const pageSub = document.querySelector(".page-subtitle");
    if (pageSub) pageSub.textContent = str("app.tagline", "Scripts .bat do Prompt Auxiliar");
    if (ui.search) ui.search.placeholder = str("busca.placeholder", "Buscar…");

    const updBtn = document.querySelector('[data-action="check-update"]');
    if (updBtn) {
      updBtn.dataset.tooltip = str("footer.tooltip_atualizacao", updBtn.dataset.tooltip || "");
      if (!state.pendingUpdate) _setBtnLabel(updBtn, str("footer.verificar_atualizacao", "Verificar atualização"));
    }
    const folderBtn = document.querySelector('[data-action="folder"]');
    if (folderBtn) {
      folderBtn.dataset.tooltip = str("footer.tooltip_pasta", folderBtn.dataset.tooltip || "");
      const lbl = folderBtn.querySelector(".btn-label");
      if (lbl) lbl.textContent = str("footer.pasta_dados", "Pasta de Dados / Logs");
      else folderBtn.lastChild.textContent = str("footer.pasta_dados", "Pasta de Dados / Logs");
    }
    const uninstBtn = document.querySelector('[data-action="uninstall"]');
    if (uninstBtn) {
      uninstBtn.dataset.tooltip = str("footer.tooltip_excluir", uninstBtn.dataset.tooltip || "");
      const lbl = uninstBtn.querySelector(".btn-label");
      if (lbl) lbl.textContent = str("footer.excluir_app", "Excluir Prompt Auxiliar");
    }
    const creditos = document.querySelector('[data-action="creditos"]');
    if (creditos) creditos.textContent = str("footer.creditos", "GitHub · Heyash");

    const welcomeDlg = ui.welcome;
    if (welcomeDlg) {
      const h3 = welcomeDlg.querySelector("h3");
      if (h3) h3.textContent = str("modais.welcome.titulo", "Bem-vindo");
      const startBtn = welcomeDlg.querySelector('button[type="submit"]');
      if (startBtn) startBtn.textContent = str("modais.welcome.comecar", "Começar");
    }

    const utilDlg = document.getElementById("util-modal");
    if (utilDlg) {
      const setLabel = (forId, path, fb) => {
        const el = utilDlg.querySelector(`label[for="${forId}"]`);
        if (el) el.textContent = str(path, fb);
      };
      setLabel("util-url", "modais.util_download.url", "Link (URL)");
      setLabel("util-dest", "modais.util_download.destino", "Pasta de destino");
      const urlIn = document.getElementById("util-url");
      if (urlIn) urlIn.placeholder = str("modais.util_download.url_placeholder", "https://...");
      const destIn = document.getElementById("util-dest");
      if (destIn) destIn.placeholder = str("modais.util_download.destino_placeholder", "Clique em Procurar…");
      const browse = document.getElementById("util-browse");
      if (browse) browse.textContent = str("modais.util_download.procurar", "Procurar");
      const modeLabel = utilDlg.querySelector("#util-mode-wrap .util-label");
      if (modeLabel) modeLabel.textContent = str("modais.util_download.formato", "Formato");
      const radios = utilDlg.querySelectorAll('input[name="util-mode"]');
      if (radios[0]?.parentElement) radios[0].parentElement.lastChild.textContent = ` ${str("modais.util_download.video", "Vídeo (MP4)")}`;
      if (radios[1]?.parentElement) radios[1].parentElement.lastChild.textContent = ` ${str("modais.util_download.audio", "Somente áudio (MP3)")}`;
      const playlistLbl = document.querySelector("#util-playlist-wrap .util-check");
      if (playlistLbl?.lastChild) playlistLbl.lastChild.textContent = ` ${str("modais.util_download.playlist", "Baixar playlist inteira (quando o link for uma playlist do YouTube)")}`;
      const utilCancel = document.getElementById("util-cancel");
      if (utilCancel) utilCancel.textContent = str("modais.cancelar", "Cancelar");
      const utilSubmit = document.getElementById("util-submit");
      if (utilSubmit) utilSubmit.textContent = str("modais.util_download.baixar", "Baixar");
      const sitesBtn = document.getElementById("util-sites-btn");
      if (sitesBtn) sitesBtn.textContent = str("modais.util_download.sites_suportados", "Sites suportados");
    }

    const ytdlpSitesDlg = document.getElementById("ytdlp-sites-modal");
    if (ytdlpSitesDlg) {
      const h3 = ytdlpSitesDlg.querySelector("h3");
      if (h3) h3.textContent = str("modais.ytdlp_sites.titulo", "Sites suportados");
      const note = ytdlpSitesDlg.querySelector(".ytdlp-sites-note");
      if (note) {
        note.textContent = str(
          "modais.ytdlp_sites.nota",
          "Principais plataformas suportadas pelo yt-dlp — qualquer URL reconhecida funciona no download"
        );
      }
      const filterIn = document.getElementById("ytdlp-sites-filter");
      if (filterIn) filterIn.placeholder = str("modais.ytdlp_sites.filtrar", "Filtrar sites…");
      const closeBtn = document.getElementById("ytdlp-sites-close");
      if (closeBtn) closeBtn.textContent = str("modais.ytdlp_sites.fechar", "Fechar");
      const loading = document.getElementById("ytdlp-sites-loading");
      if (loading) loading.textContent = str("modais.ytdlp_sites.carregando", "Carregando…");
    }

    const imgDlg = document.getElementById("util-imagem-modal");
    if (imgDlg) {
      const setLabel = (forId, path, fb) => {
        const el = imgDlg.querySelector(`label[for="${forId}"]`);
        if (el) el.textContent = str(path, fb);
      };
      const imgTitle = document.getElementById("util-imagem-modal-title");
      if (imgTitle) imgTitle.textContent = str("modais.util_imagem.titulo", "Converter imagem");
      setLabel("util-imagem-src", "modais.util_imagem.origem", "Arquivo de origem");
      setLabel("util-imagem-dest", "modais.util_imagem.destino", "Pasta de destino");
      setLabel("util-imagem-format", "modais.util_imagem.converter_para", "Converter para");
      const fmtSel = document.getElementById("util-imagem-format");
      if (fmtSel?.options[0]) fmtSel.options[0].textContent = str("modais.util_imagem.formato_placeholder", "Escolha o formato de saída…");
      Array.from(fmtSel?.options || []).forEach((opt) => {
        if (!opt.value) return;
        const txt = str(`modais.util_imagem.formatos.${opt.value}`, opt.textContent);
        if (txt) opt.textContent = txt;
      });
      const outLbl = imgDlg.querySelector('label[for="util-imagem-outname"]');
      if (outLbl) {
        outLbl.innerHTML = `${str("modais.util_imagem.nome_saida", "Nome do arquivo de saída")} <span class="util-label-optional">${str("modais.util_imagem.nome_opcional", "(opcional)")}</span>`;
      }
      const outIn = document.getElementById("util-imagem-outname");
      if (outIn) outIn.placeholder = str("modais.util_imagem.nome_placeholder", "Ex.: MinhaFoto — sem extensão");
      ["util-imagem-browse-src", "util-imagem-browse-dest"].forEach((id) => {
        const b = document.getElementById(id);
        if (b) b.textContent = str("modais.util_download.procurar", "Procurar");
      });
      const imgCancel = document.getElementById("util-imagem-cancel");
      if (imgCancel) imgCancel.textContent = str("modais.cancelar", "Cancelar");
      const imgSubmit = document.getElementById("util-imagem-submit");
      if (imgSubmit) imgSubmit.textContent = str("modais.util_imagem.converter", "Converter");
    }

    document.querySelectorAll("[data-scripts-layout]").forEach((btn) => {
      const layout = btn.getAttribute("data-scripts-layout");
      btn.textContent = str(`scripts.layout_${layout}`, layout === "list" ? "Lista" : "Grade");
      btn.title = btn.textContent;
    });
    document.querySelectorAll("[data-utils-layout]").forEach((btn) => {
      const layout = btn.getAttribute("data-utils-layout");
      btn.textContent = str(`scripts.layout_${layout}`, layout === "list" ? "Lista" : "Grade");
      btn.title = btn.textContent;
    });

    const panelToolbar = document.querySelector("#view-panel .panel-toolbar-actions");
    if (panelToolbar) {
      const map = [
        ["panel-select-all", "paineis.comum.marcar_categoria", "Marcar categoria"],
        ["panel-select-none", "paineis.comum.desmarcar_categoria", "Desmarcar categoria"],
        ["panel-select-installed", "paineis.debloat.selecionar_instalados", "Selecionar instalados"],
        ["panel-save", "paineis.comum.salvar_selecao", "Salvar seleção"],
      ];
      map.forEach(([id, path, fb]) => {
        const el = document.getElementById(id);
        if (el) el.textContent = str(path, fb);
      });
    }

    const tweaksToolbar = document.querySelector("#view-tweaks .panel-toolbar-actions");
    if (tweaksToolbar) {
      const map = [
        ["tweaks-select-all", "tweaks.marcar_todos", "Marcar todos"],
        ["tweaks-select-none", "tweaks.desmarcar_todos", "Desmarcar todos"],
        ["tweaks-detect-btn", "tweaks.detectar", "Detectar estado"],
        ["tweaks-apply-btn", "tweaks.aplicar", "Aplicar selecionados"],
      ];
      map.forEach(([id, path, fb]) => {
        const el = document.getElementById(id);
        if (el) el.textContent = str(path, fb);
      });
    }
  }

  async function init() {
    setBootProgress(20, str("boot.conectando", "Conectando…"));
    const a = api();
    if (!a) {
      setBootProgress(100, str("boot.bridge_indisponivel", "Bridge Python indisponível."));
      return;
    }
    setBootProgress(45, str("boot.preparando_pasta", "Preparando pasta de dados…"));
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
    setBootProgress(70, str("boot.carregando_acoes", "Carregando ações…"));
    state.catalog = await a.get_catalog();
    state.strings = state.catalog.ui_strings || {};
    applyChromeStrings();
    if (window.PromptAuxTheme) {
      const theme = document.documentElement.getAttribute("data-theme") || initRes.theme || "dark";
      window.PromptAuxTheme.apply(theme);
    }
    ui.version.textContent = `v${state.catalog.meta.version}`;
    setBootProgress(100, str("boot.pronto", "Pronto."));
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
    if (window.Utils?.initLayout) {
      let utilsLayout;
      try {
        utilsLayout = localStorage.getItem("promptaux-utils-layout");
      } catch (_) {
        /* ignore */
      }
      if (initRes.utils_layout === "grid" || initRes.utils_layout === "list") {
        utilsLayout = initRes.utils_layout;
      }
      window.Utils.initLayout(utilsLayout);
    }
    showApp();
    document.body.dataset.view = "scripts";
    renderNav();
    openScriptsView();
    if (initRes.primeira_vez) {
      $("#welcome-path").textContent = initRes.pasta;
      const welcomeBody = ui.welcome?.querySelector(".modal-body");
      if (welcomeBody) {
        welcomeBody.textContent = strFmt(
          "modais.welcome.corpo",
          { pasta: initRes.pasta },
          `Pasta ${initRes.pasta} pronta. Use os scripts ou os painéis Winget/Debloat.`
        );
      }
      ui.welcome.showModal();
    }
    // Verifica update em background — só atualiza o botão, sem modal nem instalação automática
    a.check_for_updates()
      .then((r) => {
        if (r?.ok) setUpdateAvailability(r);
      })
      .catch(() => {});
  }

  function runActionById(actionId) {
    const acao = state.catalog?.acoes?.find((a) => a.id === actionId);
    if (acao) return runAction(acao);
    toast(strFmt("scripts.acao_nao_encontrada", { id: actionId }, `Ação não encontrada: ${actionId}`), "error");
  }

  window.appStr = str;
  window.appStrFmt = strFmt;
  window.appToast = toast;
  window.appConfirm = confirmDialog;
  window.appRunActionById = runActionById;
  window.appRenderNav = renderNav;
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
    if (window.Utils?.isOpen()) window.Utils.close();
    ui.search.placeholder = str("scripts.busca_placeholder", "Buscar scripts…");
    ui.search.value = "";
    state.busca = "";
    window._panelBusca = "";
    openScriptsView();
  };

  function bindEvents() {
    if (window.Panels) window.Panels.bind();
    if (window.Tweaks) window.Tweaks.bind();
    if (window.Utils) window.Utils.bind();
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
          // Já há update pendente (ex.: cancelou o modal antes) → abrir confirmação de novo
          if (state.pendingUpdate) {
            await confirmAndLaunchUpdate(state.pendingUpdate);
            return;
          }
          el.disabled = true;
          _setBtnLabel(el, str("footer.verificando", "Verificando…"));
          try {
            const r = await api().check_for_updates();
            if (!r.ok) {
              toast(r.message || str("modais.update.erro", "Erro ao verificar atualização."), "error");
              return;
            }
            setUpdateAvailability(r);
            if (r.update_available) {
              await confirmAndLaunchUpdate(r);
            } else {
              const corpo = r.remote
                ? strFmt(
                    "modais.update.verificar_atualizado",
                    { local: r.local, remote: r.remote },
                    `Versão instalada: v${r.local}\nGitHub (main): v${r.remote}\n\nJá na versão mais recente.`
                  )
                : str("modais.update.verificar_simples", "Já na versão mais recente.");
              await showAppModal({
                title: str("modais.update.verificar_titulo", "Verificar atualização"),
                body: corpo,
                variant: "alert",
              });
            }
          } catch (e) {
            toast(String(e), "error");
          } finally {
            el.disabled = false;
            if (!state.pendingUpdate) _setBtnLabel(el, str("footer.verificar_atualizacao", "Verificar atualização"));
          }
        } else if (kind === "uninstall") {
          const preview = await api().get_uninstall_preview();
          if (!preview.ok) {
            toast(preview.message || str("modais.uninstall.erro_preview", "Não foi possível preparar a exclusão."), "error");
            return;
          }
          const lista = preview.paths.map((p) => `• ${p}`).join("\n");
          const ok = await confirmDialog({
            title: str("modais.uninstall.titulo", "Excluir Prompt Auxiliar"),
            body: strFmt(
              "modais.uninstall.corpo",
              { lista },
              `Tem certeza? Esta ação é permanente e não pode ser desfeita.\n\nPastas que serão removidas:\n${lista}\n\nAtalhos na Área de Trabalho e Menu Iniciar também serão apagados.\n\nO aplicativo será fechado em seguida.`
            ),
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
      setBootProgress(100, str("boot.falha_iniciar", "Falha ao iniciar."));
      toast(String(err), "error");
    });
  });
  if (window.pywebview) window.dispatchEvent(new Event("pywebviewready"));
})();
