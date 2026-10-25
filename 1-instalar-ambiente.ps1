# ============================================================
# Etapa 1 - Instala o ambiente para o estudo com o REA
# Rodar no PowerShell (normal, nao precisa ser admin):
#   cd D:\dev\strava-estudo
#   powershell -ExecutionPolicy Bypass -File .\1-instalar-ambiente.ps1
# ============================================================

$ErrorActionPreference = "Continue"

function Titulo($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($t)     { Write-Host "  [ok] $t" -ForegroundColor Green }
function Aviso($t)  { Write-Host "  [!]  $t" -ForegroundColor Yellow }

# ---------- 0. Pre-requisitos ----------
Titulo "Verificando winget"
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Aviso "winget nao encontrado. Instale o 'Instalador de Aplicativo' pela Microsoft Store e rode de novo."
    exit 1
}
Ok "winget disponivel"

Titulo "Verificando virtualizacao (necessaria para o emulador)"
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
if ($cpu.VirtualizationFirmwareEnabled) {
    Ok "Virtualizacao ativa na BIOS"
} else {
    # Com Hyper-V ligado esse campo vem False mesmo estando ativo; por isso e so um aviso
    Aviso "Virtualizacao parece desligada (ou o Hyper-V ja esta em uso). Se o emulador nao abrir,"
    Aviso "ative Intel VT-x / AMD-V na BIOS e o recurso 'Plataforma do Hipervisor do Windows'."
}

# ---------- 1. Git ----------
Titulo "Git"
if (Get-Command git -ErrorAction SilentlyContinue) { Ok (git --version) }
else { winget install --id Git.Git -e --accept-package-agreements --accept-source-agreements }

# ---------- 2. Node.js (REA exige 22.19+) ----------
Titulo "Node.js"
$precisaNode = $true
if (Get-Command node -ErrorAction SilentlyContinue) {
    $v = (node -v).TrimStart("v").Split(".")
    $maj = [int]$v[0]; $min = [int]$v[1]
    if ($maj -gt 22 -or ($maj -eq 22 -and $min -ge 19)) { Ok "Node $(node -v) ja atende"; $precisaNode = $false }
    else { Aviso "Node $(node -v) e antigo para o REA, atualizando" }
}
if ($precisaNode) { winget install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements }

# ---------- 3. Android Studio (traz SDK, emulador e adb) ----------
Titulo "Android Studio"
$asInstalado = winget list --id Google.AndroidStudio -e 2>$null | Select-String "AndroidStudio"
if ($asInstalado) { Ok "Android Studio ja instalado" }
else { winget install --id Google.AndroidStudio -e --accept-package-agreements --accept-source-agreements }

# ---------- 4. Coloca o adb no PATH do usuario ----------
Titulo "PATH do platform-tools"
$pt = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$pt*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$pt", "User")
    Ok "Adicionado ao PATH: $pt (vale para terminais novos)"
} else { Ok "platform-tools ja esta no PATH" }

# ---------- Proximos passos manuais ----------
Titulo "Agora faca manualmente"
Write-Host @"
  1. Abra o Android Studio e conclua o assistente inicial (Standard).
     Ele baixa o Android SDK, o emulador e o platform-tools.

  2. Device Manager > Create Virtual Device
     - Modelo com icone da Play Store (ex.: Pixel 7)
     - Imagem do sistema com 'Google Play' no nome, x86_64
     - Finish, depois de play no dispositivo

  3. No emulador: entre na Play Store com uma conta Google de teste
     e instale o Strava.

  4. Feche e abra um PowerShell novo e rode:
       powershell -ExecutionPolicy Bypass -File .\2-extrair-apk.ps1
"@
