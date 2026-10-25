# ============================================================
# Etapa 2 - Extrai o APK do Strava do emulador
# Rodar com o emulador aberto e o Strava instalado nele:
#   cd D:\dev\strava-estudo
#   powershell -ExecutionPolicy Bypass -File .\2-extrair-apk.ps1
# ============================================================

$pacote = "com.strava"
$destino = Join-Path $PSScriptRoot "apk"

$adb = Get-Command adb -ErrorAction SilentlyContinue
if (-not $adb) {
    $adbPath = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
    if (Test-Path $adbPath) { Set-Alias adb $adbPath } else {
        Write-Host "adb nao encontrado. Conclua o assistente do Android Studio primeiro." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Dispositivos conectados:" -ForegroundColor Cyan
adb devices

$caminhos = adb shell pm path $pacote | ForEach-Object { $_ -replace "^package:", "" } | Where-Object { $_ }
if (-not $caminhos) {
    Write-Host "Strava nao encontrado no emulador. Instale pela Play Store do emulador." -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $destino | Out-Null
foreach ($c in $caminhos) {
    Write-Host "Copiando $c" -ForegroundColor Cyan
    adb pull $c $destino | Out-Null
}

# Registra a versao analisada
$info = adb shell dumpsys package $pacote | Select-String "versionName|versionCode" | Select-Object -First 2
$info | Out-File (Join-Path $destino "versao.txt")

Write-Host "`nPronto. Arquivos em: $destino" -ForegroundColor Green
Get-ChildItem $destino | Format-Table Name, @{n="MB";e={[math]::Round($_.Length/1MB,1)}}
$info
Write-Host "`nUso: somente estudo local. Nao redistribuir os arquivos." -ForegroundColor Yellow
