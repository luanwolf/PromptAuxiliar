/**
 * Prompt Auxiliar — painel Utilitários (yt-dlp / spotdl)
 */
(function () {
  const ITEMS = [
    {
      id: "baixar-ytdlp",
      title: "yt-dlp",
      subtitle: "YouTube e outros sites",
      desc: "Baixa vídeo (MP4), áudio (MP3) ou playlist inteira do YouTube.",
    },
    {
      id: "baixar-spotdl",
      title: "spotdl",
      subtitle: "Spotify",
      desc: "Baixa música ou playlist do Spotify em MP3.",
    },
  ];

  function open() {
    const vHome = document.getElementById("view-home");
    const vPanel = document.getElementById("view-panel");
    const vTweaks = document.getElementById("view-tweaks");
    const vUtils = document.getElementById("view-utils");
    if (vHome) { vHome.classList.add("hidden"); vHome.hidden = true; }
    if (vPanel) { vPanel.classList.add("hidden"); vPanel.hidden = true; }
    if (vTweaks) { vTweaks.classList.add("hidden"); vTweaks.hidden = true; }
    if (vUtils) { vUtils.classList.remove("hidden"); vUtils.hidden = false; }

    document.body.dataset.view = "utils";
    if (window.appSetTitle) {
      window.appSetTitle("Utilitários", "Downloads de vídeo, música e Spotify");
    }
    if (window.appRenderNav) window.appRenderNav();
  }

  function close() {
    const v = document.getElementById("view-utils");
    if (v) { v.classList.add("hidden"); v.hidden = true; }
  }

  function isOpen() {
    const v = document.getElementById("view-utils");
    return !!(v && !v.hidden);
  }

  function bind() {
    document.querySelectorAll("[data-util-action]").forEach((btn) => {
      btn.addEventListener("click", () => {
        const id = btn.getAttribute("data-util-action");
        if (id && window.appRunActionById) window.appRunActionById(id);
      });
    });
  }

  window.Utils = { open, close, isOpen, bind, ITEMS };
})();
