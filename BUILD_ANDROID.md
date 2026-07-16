# BMDesk - Build Android

## Status Atual

- **Rust lib compilada:** SUCESSO (`librustdesk.so` 34MB para arm64-v8a)
- **vcpkg deps:** Todas compiladas (ffmpeg, openssl, libsodium, opus, libvpx, libyuv, aom, oboe, cpu-features, libjpeg-turbo)
- **Gradle/AGP:** Atualizados para Gradle 8.7 + AGP 8.6.0 (requisito do Flutter 3.44.1)
- **JDK:** JDK 17 instalado em `D:\jdk-17.0.14+7`
- **APK:** BLOQUEADO - plugins Flutter desatualizados incompatíveis com AGP 8.x

## Ambiente

### Windows (host)
- Flutter 3.44.1 em `D:\Python\flutter`
- JDK 17 em `D:\jdk-17.0.14+7`
- Android SDK em `%LOCALAPPDATA%\Android\Sdk`
- Android NDK r29 em `%LOCALAPPDATA%\Android\Sdk\ndk\29.0.13846066`

### WSL (Ubuntu 26.04)
- Rust 1.75 em `/root/.cargo`
- Android NDK r28c em `/opt/android-ndk/android-ndk-r28c`
- vcpkg em `/opt/vcpkg` (pacotes em `/opt/vcpkg/installed/arm64-android`)
- JDK 17 em `/usr/lib/jvm/java-17-openjdk-amd64`
- NASM 2.16.03 em `/usr/local/bin/nasm` (NASM 3.x não suporta multipass exigido pelo aom)

### Scripts de build
- `D:\bmdesk\build_android_wsl.sh` - compila a lib Rust via WSL
- `D:\bmdesk\build_flutter_wsl.sh` - compila o APK via WSL (não usado, Flutter usado do Windows)

## Passos Concluídos

### 1. vcpkg dependencies (no WSL)
```bash
# No WSL como root:
export ANDROID_NDK_HOME=/opt/android-ndk/android-ndk-r28c
export VCPKG_ROOT=/opt/vcpkg

# Copiar res/vcpkg e vcpkg.json para filesystem Linux (evitar CRLF)
mkdir -p /opt/bmdesk/res
cp -r /mnt/d/bmdesk/res/vcpkg /opt/bmdesk/res/
cp -r /mnt/d/bmdesk/res/vcpkg-triplets /opt/bmdesk/res/
cp /mnt/d/bmdesk/vcpkg.json /opt/bmdesk/
find /opt/bmdesk/res -type f -exec dos2unix -q {} \;

# Instalar deps
cd /opt/bmdesk
/opt/vcpkg/vcpkg install --triplet arm64-android --x-install-root=/opt/vcpkg/installed
```

### 2. Compilar lib Rust
```bash
# No WSL como root:
export ANDROID_NDK_HOME=/opt/android-ndk/android-ndk-r28c
export VCPKG_ROOT=/opt/vcpkg
export OPENSSL_NO_VENDOR=1
export AARCH64_LINUX_ANDROID_OPENSSL_DIR=/opt/vcpkg/installed/arm64-android
export CLANG_PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/clang
export BINDGEN_EXTRA_CLANG_ARGS="--sysroot=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot --target=aarch64-linux-android21"
export PKG_CONFIG_ALLOW_CROSS=1
export PATH=/root/.cargo/bin:$PATH

cd /mnt/d/bmdesk
cargo ndk --platform 21 --target aarch64-linux-android build --locked --release --features flutter,hwcodec
```

Output: `target/aarch64-linux-android/release/liblibrustdesk.so` (34MB)

### 3. Copiar .so para jniLibs
```powershell
mkdir -p D:\bmdesk\flutter\android\app\src\main\jniLibs\arm64-v8a
Copy-Item D:\bmdesk\target\aarch64-linux-android\release\liblibrustdesk.so D:\bmdesk\flutter\android\app\src\main\jniLibs\arm64-v8a\librustdesk.so
```

### 4. Atualizar Gradle/AGP/Kotlin (necessário para Flutter 3.44.1)
Arquivos modificados:
- `flutter/android/gradle/wrapper/gradle-wrapper.properties` → Gradle 8.7
- `flutter/android/settings.gradle` → AGP 8.6.0
- `flutter/android/app/build.gradle` → adicionado `namespace`, `compileSdk`, `compileOptions`, `kotlinOptions`
- `flutter/android/build.gradle` → `compileOptions` e `kotlinOptions` globais para subprojects
- `72 plugins` no pub cache → adicionado `namespace` e `compileSdk`

### 5. Flutter config
```powershell
flutter config --jdk-dir "D:\jdk-17.0.14+7"
```

## Próximo Passo: Gerar APK

### Problema atual
Plugins Flutter usam APIs removidas do Android v1 embedding (`PluginRegistry.Registrar`):
- `external_path` 1.0.3
- `flutter_plugin_android_lifecycle` 2.0.17

### Solução necessária
1. Atualizar `pubspec.yaml` - versões mínimas dos plugins problemáticos:
   ```yaml
   external_path: ^1.0.4  # ou superior
   flutter_plugin_android_lifecycle: ^2.0.18  # ou superior
   ```
2. Rodar `flutter pub upgrade` no diretório `flutter/`
3. Rodar build:
   ```powershell
   $env:JAVA_HOME = "D:\jdk-17.0.14+7"
   $env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
   cd D:\bmdesk\flutter
   flutter build apk --release --target-platform android-arm64 --split-per-abi
   ```

### Output esperado
- Arm64: `flutter/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

### Para build universal (todas arquiteturas)
Antes do Flutter build, compilar Rust para as outras arquiteturas:
```bash
# No WSL:
cargo ndk --platform 21 --target armv7-linux-androideabi build --locked --release --features flutter,hwcodec
cargo ndk --platform 21 --target x86_64-linux-android build --locked --release --features flutter,hwcodec
# Copiar cada .so para jniLibs/<abi>/
```
Depois:
```powershell
flutter build apk --release --target-platform android-arm64,android-arm,android-x64
```

## Notas

- NASM 3.01 (Ubuntu 26.04 default) não funciona com aom. Instalar NASM 2.16.03.
- CRLF nos arquivos do Windows quebra scripts no WSL. Usar `dos2unix` ou copiar para filesystem Linux.
- JDK 21 do Android Studio não funciona com Gradle < 8.x. Usar JDK 17.
- Flutter 3.24.5 (CI) não funciona porque `extended_text` requer Dart SDK >= 3.7.0. Manter Flutter 3.44.1.
- Para builds futuros, rodar `cargo ndk` do WSL e `flutter build apk` do Windows.
