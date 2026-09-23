# build_and_publish.ps1
# Script de automatizacion de compilacion y publicacion para CzBarber

Write-Host "=============================================" -ForegroundColor Yellow
Write-Host "=== CZBARBER - COMPILACION Y PUBLICACION AUTOMATICA ===" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Yellow

# 1. Cargar archivo de configuracion
$configFile = "update_config.json"
if (-not (Test-Path $configFile)) {
    Write-Error "No se encontro el archivo $configFile en el directorio raiz."
    exit 1
}

$config = Get-Content $configFile | ConvertFrom-Json
$backendUrl = $config.backend_url
$downloadUrl = $config.download_url

# 2. Leer version actual en pubspec.yaml
$pubspecFile = "pubspec.yaml"
$pubspec = Get-Content $pubspecFile -Raw
if ($pubspec -match "(?m)^version:\s*([^\r\n]+)") {
    $currentVersion = $Matches[1].Trim()
} else {
    Write-Error "No se pudo leer la version en pubspec.yaml."
    exit 1
}

Write-Host "Version actual detectada: $currentVersion" -ForegroundColor Green

# 3. Preguntar por enlace de descarga en Google Drive
Write-Host ""
Write-Host "Enlace de descarga actual en el backend:" -ForegroundColor Yellow
Write-Host "  $downloadUrl" -ForegroundColor Cyan
Write-Host ""
$userInputUrl = Read-Host "Ingresa el enlace de Google Drive para el nuevo APK (Presiona Enter para mantener el actual)"
if ($userInputUrl.Trim() -ne "") {
    $downloadUrl = $userInputUrl.Trim()
}

# 4. Incrementar version automaticamente
# Si contiene '+' dividimos versionName y versionCode
if ($currentVersion -like "*+*") {
    $parts = $currentVersion.Split("+")
    $namePart = $parts[0]
    $codePart = [int]$parts[1]
} else {
    $namePart = $currentVersion
    $codePart = 1
}

# Incrementar patch version (ultimo digito de versionName)
$nameParts = $namePart.Split(".")
if ($nameParts.Count -eq 3) {
    $patch = [int]$nameParts[2]
    $newPatch = $patch + 1
    $newVersionName = "$($nameParts[0]).$($nameParts[1]).$newPatch"
} else {
    $newVersionName = "$namePart.1"
}

$newVersionCode = $codePart + 1
$newVersion = "$newVersionName+$newVersionCode"

Write-Host ""
Write-Host "Nueva version a generar: $newVersion (Code: $newVersionCode)" -ForegroundColor Yellow

# 5. Actualizar pubspec.yaml
$pubspec = $pubspec -replace "(?m)^version:\s*[^\r\n]+", "version: $newVersion"
Set-Content -Path $pubspecFile -Value $pubspec -NoNewline

Write-Host "[OK] pubspec.yaml actualizado correctamente." -ForegroundColor Green

# 6. Compilar el APK
Write-Host ""
Write-Host "[Build] Obteniendo dependencias..." -ForegroundColor Yellow
flutter pub get

Write-Host "[Build] Compilando APK para Android..." -ForegroundColor Yellow
flutter build apk --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "[Alerta] Fallo compilacion directa. Reintentando con 'flutter clean' para liberar archivos bloqueados..." -ForegroundColor Yellow
    flutter clean
    flutter pub get
    flutter build apk --release
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "[Error] La compilacion del APK ha fallado. Restableciendo version original..." -ForegroundColor Red
    # Volver a poner la version anterior
    $pubspec = Get-Content $pubspecFile -Raw
    $pubspec = $pubspec -replace "version:\s*[^\r\n]+", "version: $currentVersion"
    Set-Content -Path $pubspecFile -Value $pubspec -NoNewline
    exit 1
}

Write-Host "[OK] APK generado exitosamente en build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green

# 7. Registrar version en el Backend con reintentos para despertar el servidor (Render.com)
Write-Host ""
Write-Host "[Backend] Conectando y registrando version en el backend: $backendUrl ..." -ForegroundColor Yellow

$body = @{
    version_name = $newVersionName
    version_code = $newVersionCode
    download_url = $downloadUrl
} | ConvertTo-Json

$maxRetries = 5
$registered = $false

for ($i = 1; $i -le $maxRetries; $i++) {
    try {
        Write-Host "[Intento $i de $maxRetries] Enviando datos al servidor backend (despertando si esta en reposo)..." -ForegroundColor Cyan
        $response = Invoke-RestMethod -Uri "$backendUrl/app-version/update" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        if ($response.success -eq $true) {
            Write-Host "[OK] Version registrada exitosamente en el backend!" -ForegroundColor Green
            Write-Host "Detalles registrados:" -ForegroundColor Green
            Write-Host "  Nombre: $($response.data.version_name)" -ForegroundColor Green
            Write-Host "  Codigo: $($response.data.version_code)" -ForegroundColor Green
            Write-Host "  Enlace: $($response.data.download_url)" -ForegroundColor Green
            $registered = $true
            break
        } else {
            Write-Host "[Alerta] El backend respondio con exito = false: $($response.message)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[Intento $i fallo] El servidor esta iniciando o reconectando: $_" -ForegroundColor Yellow
        if ($i -lt $maxRetries) {
            Write-Host "Esperando 5 segundos antes de reintentar..." -ForegroundColor Gray
            Start-Sleep -Seconds 5
        }
    }
}

if (-not $registered) {
    Write-Host "[Alerta] La version se incremento localmente pero no se pudo sincronizar en el servidor tras $maxRetries intentos." -ForegroundColor Yellow
}

# 8. Actualizar configuracion local
$config.download_url = $downloadUrl
$config | ConvertTo-Json | Set-Content $configFile

Write-Host ""
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host "=== PROCESO COMPLETADO EXITOSAMENTE ===" -ForegroundColor Yellow
Write-Host "1. Sube tu nuevo APK al enlace de Google Drive." -ForegroundColor Yellow
Write-Host "2. Tus usuarios recibiran la notificacion de actualizacion al abrir la app." -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Yellow
