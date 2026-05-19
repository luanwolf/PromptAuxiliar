#Requires -Version 5.1
# Biblioteca visual compartilhada — nao executar diretamente.
# Encoding: UTF-8 with BOM

function Show-PABanner {
    param(
        [string]$Titulo,
        [string]$Descricao = ""
    )
    Clear-Host
    $Host.UI.RawUI.WindowTitle = "Prompt Auxiliar - $Titulo"
    Write-Host ""
    Write-Host "  ================================================" -ForegroundColor DarkCyan
    Write-Host "    PROMPT AUXILIAR  |  $Titulo" -ForegroundColor Cyan
    Write-Host "  ================================================" -ForegroundColor DarkCyan
    if ($Descricao) {
        Write-Host ""
        Write-Host "  $Descricao" -ForegroundColor DarkGray
    }
    Write-Host ""
}

function Confirm-PAAction {
    param([switch]$Perigo)
    if ($Perigo) {
        Write-Host "  ATENCAO: operacao sensivel — use por sua conta e risco." -ForegroundColor Yellow
        Write-Host ""
    }
    Write-Host "  Pressione S para continuar ou N para cancelar:" -ForegroundColor Gray
    $resp = Read-Host "  Opcao"
    return ($resp -ieq "S")
}

function Invoke-PAStep {
    param(
        [string]$Label,
        [System.Collections.ArrayList]$Results,
        [scriptblock]$Script
    )
    Write-Host "  -> $Label..." -ForegroundColor Gray
    $ok  = $true
    $msg = ""
    try {
        & $Script
    } catch {
        $ok  = $false
        $msg = $_.Exception.Message
        Write-Host "     ERRO: $msg" -ForegroundColor Red
    }
    if ($ok) { Write-Host "     OK" -ForegroundColor DarkGreen }
    [void]$Results.Add(@{ Label = $Label; Ok = $ok; Msg = $msg })
}

function Write-PASummary {
    param(
        [System.Collections.ArrayList]$Results,
        [datetime]$StartTime,
        [switch]$NeedRestart,
        [string]$Titulo = "script"
    )
    $elapsed  = [math]::Round(((Get-Date) - $StartTime).TotalSeconds, 1)
    $okCount  = ($Results | Where-Object { $_.Ok  }).Count
    $errCount = ($Results | Where-Object { -not $_.Ok }).Count

    Write-Host ""
    Write-Host "  ================================================" -ForegroundColor DarkCyan
    Write-Host "   RESUMO" -ForegroundColor Cyan
    Write-Host "  ================================================" -ForegroundColor DarkCyan
    foreach ($r in $Results) {
        if ($r.Ok) {
            Write-Host "   [OK]   $($r.Label)" -ForegroundColor Green
        } else {
            Write-Host "   [ERRO] $($r.Label)" -ForegroundColor Red
            if ($r.Msg) { Write-Host "         $($r.Msg)" -ForegroundColor DarkRed }
        }
    }
    Write-Host "  ------------------------------------------------" -ForegroundColor DarkCyan
    if ($errCount -gt 0) {
        Write-Host "   Resultado: $okCount OK  |  $errCount erro(s)  |  Tempo: ${elapsed}s" -ForegroundColor Yellow
    } else {
        Write-Host "   Resultado: $okCount passo(s) concluido(s) com sucesso  |  Tempo: ${elapsed}s" -ForegroundColor Green
    }
    Write-Host "  ================================================" -ForegroundColor DarkCyan

    if ($NeedRestart) {
        Write-Host ""
        Write-Host "  ATENCAO: reinicie o computador para que as alteracoes tenham efeito." -ForegroundColor Yellow
    }

    # Salvar log em C:\PromptAuxiliar\logs
    $logDir = 'C:\PromptAuxiliar\logs'
    if (-not (Test-Path $logDir)) { New-Item $logDir -ItemType Directory -Force | Out-Null }
    $logFile = Join-Path $logDir "$($Titulo -replace '[\\/:*?""<>|]','_')-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    $logLines = @(
        "Prompt Auxiliar - Log de Script"
        "Script : $Titulo"
        "Data   : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
        "Duracao: ${elapsed}s"
        "Usuario: $env:USERNAME"
        ""
        "---- Passos ----"
    )
    foreach ($r in $Results) {
        $st = if ($r.Ok) { "[OK]  " } else { "[ERRO]" }
        $logLines += "$st  $($r.Label)"
        if (-not $r.Ok -and $r.Msg) { $logLines += "       Detalhe: $($r.Msg)" }
    }
    $logLines += ""
    $logLines += "Total: $okCount OK  |  $errCount erro(s)"
    $logLines | Out-File -FilePath $logFile -Encoding UTF8 -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "  Log salvo em: $logFile" -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "  Pressione Enter para fechar"
}
