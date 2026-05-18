"""Prompt Auxiliar — painéis Winget e Debloat (WebView2)."""

from __future__ import annotations

from app.webview_app import iniciar_webview


def main() -> None:
    try:
        iniciar_webview()
    except SystemExit:
        raise
    except Exception as e:
        print(f"Erro: {e}")
        input("Pressione Enter para sair...")
        raise SystemExit(1) from e


if __name__ == "__main__":
    main()
