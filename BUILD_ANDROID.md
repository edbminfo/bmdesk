# BMDesk - Build Android

## Status Atual (17/07/2026)

- **APK:** SUCESSO - arm64-v8a (60.1MB) + armeabi-v7a (48.9MB)
- **Rust lib:** Compilada para arm64 e armv7
- **Update check:** Funcionando em custom clients (fix aplicado)
- **Gradle/AGP:** 8.14 / 8.9.1

## Ambiente

### Windows (host)
- Flutter 3.44.1 em `D:\Python\flutter`
- JDK 17 em `D:\jdk-17.0.14+7`
- Android SDK em `%LOCALAPPDATA%\Android\Sdk`
- Android NDK r29 em `%LOCALAPPDATA%\Android\Sdk\ndk\29.0.13846066`

### WSL (Ubuntu 26.04)
- Rust 1.75 em `/root/.cargo`
- Android NDK r28c em `/opt/android-ndk/android-ndk-r28c`
- vcpkg em `/opt/vcpkg`
- JDK 17 em `/usr/lib/jvm/java-17-openjdk-amd64`
- NASM 2.16.03 em `/usr/local/bin/nasm`

### Pré-requisitos WSL
```bash
apt-get install -y autoconf autoconf-archive automake libtool
```

## Build Completo

### 1. Compilar .so para ambas arquiteturas (WSL)

```bash
# Como root no WSL:
HOME=/root
PATH=/root/.cargo/bin:/usr/bin:/bin
export HOME PATH ANDROID_NDK_HOME=/opt/android-ndk/android-ndk-r28c
export VCPKG_ROOT=/opt/vcpkg PKG_CONFIG_ALLOW_CROSS=1
export CLANG_PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/clang
export BINDGEN_EXTRA_CLANG_ARGS="--sysroot=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot --target=armv7-linux-androideabi21"

# Symlink vcpkg triplet (se necessario)
ln -sf arm-neon-android /opt/vcpkg/installed/arm-android

# Arm64
cd /mnt/d/bmdesk
cargo ndk --platform 21 --target aarch64-linux-android build --locked --release --features flutter,hwcodec

# Armv7 (sem hwcodec - FFmpeg v8 incompativel)
cargo ndk --platform 21 --target armv7-linux-androideabi build --locked --release --features flutter
```

### 2. Copiar para jniLibs (Windows PowerShell)

```powershell
# arm64
Copy-Item D:\bmdesk\target\aarch64-linux-android\release\liblibrustdesk.so D:\bmdesk\flutter\android\app\src\main\jniLibs\arm64-v8a\librustdesk.so

# armv7
Copy-Item D:\bmdesk\target\armv7-linux-androideabi\release\liblibrustdesk.so D:\bmdesk\flutter\android\app\src\main\jniLibs\armeabi-v7a\librustdesk.so

# libc++_shared.so do NDK
$NDK = "$env:LOCALAPPDATA\Android\Sdk\ndk\29.0.13846066"
Copy-Item "$NDK\toolchains\llvm\prebuilt\windows-x86_64\sysroot\usr\lib\aarch64-linux-android\libc++_shared.so" D:\bmdesk\flutter\android\app\src\main\jniLibs\arm64-v8a\
Copy-Item "$NDK\toolchains\llvm\prebuilt\windows-x86_64\sysroot\usr\lib\arm-linux-androideabi\libc++_shared.so" D:\bmdesk\flutter\android\app\src\main\jniLibs\armeabi-v7a\
```

### 3. Gerar APK

```powershell
$env:JAVA_HOME = "D:\jdk-17.0.14+7"
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
cd D:\bmdesk\flutter
flutter build apk --release --target-platform android-arm64,android-arm --split-per-abi
```

**Output:**
- `build\app\outputs\flutter-apk\app-arm64-v8a-release.apk`
- `build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk`

## Vcpkg Dependencies

Instaladas via `--classic` (manifest mode quebrado pelo cmake 4.3.3):

```bash
# Como root no WSL:
export ANDROID_NDK_HOME=/opt/android-ndk/android-ndk-r28c VCPKG_ROOT=/opt/vcpkg

/opt/vcpkg/vcpkg install --classic opus:arm-neon-android libvpx:arm-neon-android libyuv:arm-neon-android libsodium:arm-neon-android
/opt/vcpkg/vcpkg install --classic aom:arm-neon-android cpu-features:arm-neon-android oboe:arm-neon-android
/opt/vcpkg/vcpkg install --classic ffmpeg:arm-neon-android
```

## Modificacoes Android Build

| Arquivo | Alteracao |
|---------|-----------|
| `pubspec.yaml` | `external_path: ^2.2.0`, `file_picker: ^8.0.0`, `sqflite: ^2.3.0`, `uni_links: ^0.5.1` |
| `settings.gradle` | AGP 8.9.1, Kotlin 2.2.20 |
| `gradle-wrapper.properties` | Gradle 8.14 |
| `app/build.gradle` | `compileSdk 36`, `ndkVersion 28.2.13676358`, core desugaring, namespace `com.carriez.flutter_hbb` |
| `gradle.properties` | `kotlin.incremental=false`, `org.gradle.jvmargs=-Xmx4096M` |
| `app/AndroidManifest.xml` | Removido `package=` |

## Plugins Corrigidos no Pub Cache

- `flutter_plugin_android_lifecycle-2.0.35` (override)
- `uni_links-0.5.1` (namespace + compileSdk + removido `registerWith()`)
- `flutter_keyboard_visibility-5.4.1` (removido `package=` do manifest)
- `qr_code_scanner-1.0.1` (removido `package=` do manifest)
- `device_info_plus-9.1.2` (removido `package=` do manifest)
- `package_info_plus-4.2.0` (removido `package=` do manifest)

> **Atencao:** `flutter pub upgrade` pode reaplicar versoes antigas. Reaplicar correcoes se necessario.
