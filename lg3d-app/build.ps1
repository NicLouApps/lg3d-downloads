# build.ps1
# Script de compilação manual para aplicativo Android (API 10) sem Gradle

$ErrorActionPreference = "Stop"

# Configura a JRE do Android Studio (Java 17) no PATH para que d8 e apksigner funcionem corretamente
$env:PATH = "C:\Program Files\Android\Android Studio\jbr\bin;" + $env:PATH

# 1. Configuração dos caminhos das ferramentas
$sdkDir = "C:\Users\niclo\AppData\Local\Android\Sdk"
$buildToolsVersion = "34.0.0"
$buildToolsDir = "$sdkDir\build-tools\$buildToolsVersion"
$platformDir = "$sdkDir\platforms\android-10"
$javaBinDir = "C:\Program Files\Android\Android Studio\jbr\bin"

$aapt = "$buildToolsDir\aapt.exe"
$d8 = "$buildToolsDir\d8.bat"
$zipalign = "$buildToolsDir\zipalign.exe"
$apksigner = "$buildToolsDir\apksigner.bat"
$javac = "$javaBinDir\javac.exe"
$keytool = "$javaBinDir\keytool.exe"

$androidJar = "$platformDir\android.jar"

Write-Host "=== INICIANDO BUILD DO LG 3D HUB ===" -ForegroundColor Green

# 2. Limpar e recriar pastas de saída
Write-Host "Limpando diretórios temporários..."
if (Test-Path "bin") { Remove-Item -Recurse -Force "bin" }
if (Test-Path "src\com\niclouapps\lg3ddownloads\R.java") { Remove-Item "src\com\niclouapps\lg3ddownloads\R.java" }

New-Item -ItemType Directory -Force -Path "bin\classes" | Out-Null
New-Item -ItemType Directory -Force -Path "bin\gen" | Out-Null

# 3. AAPT: Gerar o arquivo R.java e compilar recursos
Write-Host "Compilando recursos com AAPT..."
& $aapt package -f -m -J src -M AndroidManifest.xml -S res -I $androidJar

# 4. JAVAC: Compilar arquivos Java
Write-Host "Compilando arquivos de código Java..."
$javaFiles = Get-ChildItem -Path "src" -Filter "*.java" -Recurse | ForEach-Object { $_.FullName }
& $javac -g:none -encoding utf-8 -target 1.8 -source 1.8 -bootclasspath $androidJar -d bin\classes $javaFiles

# 5. D8: Converter classes Java (.class) para DEX (.dex)
Write-Host "Gerando o arquivo classes.dex com D8..."
$classFiles = Get-ChildItem -Path "bin\classes" -Filter "*.class" -Recurse | ForEach-Object { $_.FullName }
& $d8 --output bin $classFiles --lib $androidJar

# Verifica se o classes.dex foi gerado com sucesso
if (-not (Test-Path "bin\classes.dex")) {
    throw "Erro: O arquivo classes.dex não foi gerado pelo D8. Abortando compilação."
}

# 6. AAPT: Empacotar recursos em APK não assinado
Write-Host "Empacotando recursos no APK temporário..."
& $aapt package -f -M AndroidManifest.xml -S res -I $androidJar -F bin\lg3d-hub-unsigned.apk

# 7. AAPT: Adicionar classes.dex ao APK
Write-Host "Adicionando classes.dex ao APK..."
Push-Location bin
& $aapt add lg3d-hub-unsigned.apk classes.dex
Pop-Location

# 8. KEYTOOL: Criar chave de assinatura de teste (keystore) se não existir
$keystoreFile = "debug.keystore"
if (-not (Test-Path $keystoreFile)) {
    Write-Host "Gerando nova chave de assinatura debug.keystore..."
    & $keytool -genkey -v -keystore $keystoreFile -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
}

# 9. ZIPALIGN: Otimizar o alinhamento de bytes do APK
Write-Host "Alinhando APK com zipalign..."
& $zipalign -f 4 bin\lg3d-hub-unsigned.apk bin\lg3d-hub-aligned.apk

# 10. APKSIGNER: Assinar o APK com a chave de teste
Write-Host "Assinando o APK final..."
& $apksigner sign --ks $keystoreFile --ks-pass pass:android --key-pass pass:android --out bin\lg3d-hub.apk bin\lg3d-hub-aligned.apk

# 11. Copiar o APK final para a pasta de downloads do site principal
Write-Host "Copiando o APK final para a pasta apks/ do site de downloads..."
$siteApkDir = "..\apks"
if (-not (Test-Path $siteApkDir)) {
    New-Item -ItemType Directory -Force -Path $siteApkDir | Out-Null
}
Copy-Item -Path bin\lg3d-hub.apk -Destination "$siteApkDir\lg3d-hub.apk" -Force

Write-Host "=== BUILD CONCLUÍDO COM SUCESSO! ===" -ForegroundColor Green
Write-Host "O aplicativo final foi copiado para: lg-optimus-3d-downloads\apks\lg3d-hub.apk" -ForegroundColor Green
