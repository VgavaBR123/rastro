# ============================================================
# Loop do estudo: roda o Claude Code uma etapa por vez
#   cd D:\dev\strava-estudo
#   powershell -ExecutionPolicy Bypass -File .\loop.ps1
#   powershell -ExecutionPolicy Bypass -File .\loop.ps1 -MaxIteracoes 3
#
# Para no primeiro destes casos:
#   - arquivo CONCLUIDO criado (roteiro terminou)
#   - arquivo AGUARDANDO.md criado (precisa de voce)
#   - arquivo PARAR criado por voce (parada manual)
#   - limite de iteracoes atingido
#   - a mesma etapa falhou 2 vezes seguidas
# ============================================================
param(
    [int]$MaxIteracoes = 10,
    [int]$MaxTurnosPorEtapa = 60
)

Set-Location $PSScriptRoot
$logDir = Join-Path $PSScriptRoot "analise\loop-logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "Claude Code nao encontrado no PATH." -ForegroundColor Red; exit 1
}
if (-not (Test-Path "relatorios\00-ambiente.md")) {
    Write-Host "Rode primeiro o PROMPT-INICIAL.md no Claude Code (etapa 00)." -ForegroundColor Yellow; exit 1
}
if (-not (Test-Path "apk\base.apk")) {
    Write-Host "apk\base.apk nao encontrado. Rode o 2-extrair-apk.ps1." -ForegroundColor Red; exit 1
}

# Ambiente do REA. O setx feito no setup so vale para processos novos; setamos aqui
# para garantir que o subprocesso do claude veja os valores (ver relatorios\00-ambiente.md).
$env:REA_JADX_MCP_JAR = "C:\Users\gavad\.local\share\rea\android\jadx-headless-mcp-0.7.1-all.jar"
$env:JAVA_HOME = "C:\Users\gavad\.jdks\jbr-17.0.14"
$env:REA_JADX_OPERATION_TIMEOUT_MS = "600000"   # base.apk tem ~100 MB / 55k classes
$env:REA_JADX_HEAP_MIB = "4096"

# O servidor MCP do REA sobe via "npx -y rea-agents@6.7.0 mcp". A resolucao do npx pode
# passar do timeout padrao de startup (30 s) e a sessao fica sem nenhuma ferramenta
# mcp__rea__* - foi o que travou a etapa 04 na primeira rodada completa.
$env:MCP_TIMEOUT = "120000"

if (-not (Test-Path $env:REA_JADX_MCP_JAR)) {
    Write-Host "JAR do JADX do REA nao encontrado em $($env:REA_JADX_MCP_JAR)" -ForegroundColor Red; exit 1
}

# Ferramentas liberadas sem pedir confirmacao.
# Para MCP, o Claude Code nao aceita curinga (mcp__rea__*): cada ferramenta vai pelo nome
# exato. Um "mcp__rea" solto liberaria o servidor inteiro (frida, adb install, etc.) -
# fora do escopo do CLAUDE.md, que e analise ESTATICA.
$ferramentas = @(
    # built-in
    "Read", "Write", "Edit", "Glob", "Grep", "TodoWrite",
    "Bash(git -C tools/rea:*)",

    # REA - analise estatica de APK (JADX)
    "mcp__rea__inspect_android_package",
    "mcp__rea__search_android_classes",
    "mcp__rea__inspect_android_class",
    "mcp__rea__inspect_android_method",
    "mcp__rea__trace_android_references",
    "mcp__rea__project_android_application_graph",
    "mcp__rea__trace_application_feature",
    "mcp__rea__inspect_analysis_view",

    # REA - registro de lacunas (para a secao "Duvidas em aberto")
    "mcp__rea__record_unknown",
    "mcp__rea__list_unknowns",
    "mcp__rea__update_unknown"
) -join ","

$prompt = Get-Content (Join-Path $PSScriptRoot "LOOP.md") -Raw
$falhasSeguidas = 0

function EtapaAtual {
    $linha = Select-String -Path "PROGRESSO.md" -Pattern "^- \[ \] (\d+)" | Select-Object -First 1
    if ($linha) { return $linha.Matches[0].Groups[1].Value } else { return "" }
}

function ArquivoDeParada {
    foreach ($f in "CONCLUIDO", "AGUARDANDO.md", "PARAR") {
        if (Test-Path $f) { return $f }
    }
    return $null
}

for ($i = 1; $i -le $MaxIteracoes; $i++) {
    $parada = ArquivoDeParada
    if ($parada) {
        Write-Host "`nParando: $parada encontrado." -ForegroundColor Yellow
        if ($parada -eq "AGUARDANDO.md") { Get-Content $parada }
        exit 0
    }

    $etapa = EtapaAtual
    if (-not $etapa) {
        Write-Host "`nNenhuma etapa [ ] no PROGRESSO.md. Roteiro terminou." -ForegroundColor Green
        "Roteiro concluido." | Out-File -FilePath "CONCLUIDO" -Encoding utf8
        exit 0
    }

    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $log = Join-Path $logDir "iter-$stamp-etapa$etapa.log"
    Write-Host "`n=== Iteracao $i | etapa $etapa | $stamp ===" -ForegroundColor Cyan
    Write-Host "log: $log" -ForegroundColor DarkGray

    # --verbose: sem isso o `claude -p` grava so a mensagem final no log, e um pedido de
    # permissao negado (ferramenta fora da allowlist) fica invisivel na auditoria.
    claude -p $prompt `
        --verbose `
        --permission-mode acceptEdits `
        --max-turns $MaxTurnosPorEtapa `
        --allowedTools $ferramentas 2>&1 |
        Tee-Object -FilePath $log

    # Tee-Object do PS 5.1 nao aceita -Encoding e grava UTF-16LE. Converte para UTF-8.
    if (Test-Path $log) { (Get-Content $log) | Set-Content -Path $log -Encoding utf8 }

    $parada = ArquivoDeParada
    if ($parada) {
        Write-Host "`nParando: $parada criado nesta iteracao." -ForegroundColor Yellow
        if ($parada -eq "AGUARDANDO.md") { Get-Content $parada }
        exit 0
    }

    $depois = EtapaAtual
    if ($depois -eq $etapa) {
        $falhasSeguidas++
        Write-Host "Etapa $etapa nao avancou ($falhasSeguidas/2)." -ForegroundColor Yellow
        if ($falhasSeguidas -ge 2) {
            "Etapa $etapa nao avancou em 2 iteracoes seguidas. Ver logs em analise\loop-logs." |
                Out-File -FilePath "AGUARDANDO.md" -Encoding utf8
            Write-Host "Parando para nao gastar iteracoes a toa." -ForegroundColor Red
            exit 1
        }
    } else {
        $falhasSeguidas = 0
        Write-Host "Etapa $etapa concluida. Proxima: $depois" -ForegroundColor Green
    }
}

Write-Host "`nLimite de $MaxIteracoes iteracoes atingido." -ForegroundColor Yellow
