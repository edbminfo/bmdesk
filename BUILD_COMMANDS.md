# Comandos de Build - BMDesk

## Pré-requisitos

- **Windows:** Flutter 3.44.1 em `D:\Python\flutter`, JDK 17 em `D:\jdk-17.0.14+7`
- **WSL (Ubuntu):** Rust 1.75, Android NDK r28c em `/opt/android-ndk/android-ndk-r28c`, vcpkg em `/opt/vcpkg`
- **Assinatura Android:** `D:\bmdesk\flutter\android\key.properties` + keystore em `D:\bmdesk\flutter\android\app\debug.keystore`

---

## APK Android (arm64-v8a)

### Compilar `librustdesk.so` (no WSL)

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

### Copiar .so e libc++ (no Windows PowerShell)

```powershell
# Copiar librustdesk.so
Copy-Item D:\bmdesk\target\aarch64-linux-android\release\liblibrustdesk.so D:\bmdesk\flutter\android\app\src\main\jniLibs\arm64-v8a\librustdesk.so

# Copiar libc++_shared.so do NDK
$NDK = "$env:LOCALAPPDATA\Android\Sdk\ndk\29.0.13846066"
Copy-Item "$NDK\toolchains\llvm\prebuilt\windows-x86_64\sysroot\usr\lib\aarch64-linux-android\libc++_shared.so" D:\bmdesk\flutter\android\app\src\main\jniLibs\arm64-v8a\
```

### Gerar APK

```powershell
$env:JAVA_HOME = "D:\jdk-17.0.14+7"
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
cd D:\bmdesk\flutter
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

**Output:** `D:\bmdesk\flutter\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk`

---

## Windows .exe

### Build completo (recomendado)

```powershell
cd D:\bmdesk
python3 .\build.py --portable --flutter --hwcodec --vram
```

**Output:** `D:\bmdesk\rustdesk-1.4.9-install.exe` (auto-instalador)

### Build sem instalador (pasta executável)

```powershell
cd D:\bmdesk
python3 .\build.py --portable --flutter --skip-portable-pack --hwcodec --vram
```

**Output:** `D:\bmdesk\flutter\build\windows\x64\runner\Release\` (contém `rustdesk.exe` + DLLs)

### Build manual (passo a passo)

```powershell
# 1. Virtual display DLL
cd D:\bmdesk\libs\virtual_display\dylib
cargo build --locked --release
cd D:\bmdesk

# 2. Rust library
cargo build --locked --features flutter,hwcodec,vram --lib --release

# 3. Flutter Windows
cd D:\bmdesk\flutter
flutter build windows --release
cd D:\bmdesk

# 4. Copiar virtual display DLL
Copy-Item D:\bmdesk\target\release\deps\dylib_virtual_display.dll D:\bmdesk\flutter\build\windows\x64\runner\Release\

# 5. (Opcional) Gerar instalador autoextraível
cd D:\bmdesk\libs\portable
pip3 install -r requirements.txt
python3 .\generate.py -f ../../flutter/build/windows/x64/runner/Release -o . -e ../../flutter/build/windows/x64/runner/Release/rustdesk.exe
```

---

## Notas sobre modificações feitas nos arquivos de build

As seguintes alterações foram necessárias para compatibilidade com Flutter 3.44.1 + AGP 8.x:

| Arquivo | O que foi alterado |
|---------|--------------------|
| `flutter/pubspec.yaml` | `external_path: ^2.2.0`, `flutter_plugin_android_lifecycle: 2.0.35`, `file_picker: ^8.0.0`, `sqflite: ^2.3.0`, `uni_links: ^0.5.1` (hosted) |
| `flutter/android/settings.gradle` | AGP `8.9.1`, Kotlin `2.2.20` |
| `flutter/android/gradle/wrapper/gradle-wrapper.properties` | Gradle `8.14` |
| `flutter/android/app/build.gradle` | `compileSdk 36`, `ndkVersion 28.2.13676358`, core desugaring, namespace `com.carriez.flutter_hbb` |
| `flutter/android/gradle.properties` | `kotlin.incremental=false`, `org.gradle.jvmargs=-Xmx4096M` |
| `flutter/android/app/src/main/AndroidManifest.xml` | Removido atributo `package=` |
| `flutter/lib/models/native_model.dart` | Null check para `ExternalPath.getExternalStorageDirectories()` |

### Plugins corrigidos manualmente no pub cache:

| Plugin | Correção |
|--------|----------|
| `flutter_plugin_android_lifecycle-2.0.35` | override da versão antiga |
| `uni_links-0.5.1` | namespace + compileSdk + removido `registerWith()` |
| `flutter_keyboard_visibility-5.4.1` | removido `package=` do manifest |
| `qr_code_scanner-1.0.1` | removido `package=` do manifest |
| `device_info_plus-9.1.2` | removido `package=` do manifest |
| `package_info_plus-4.2.0` | removido `package=` do manifest |

> **Atenção:** Se rodar `flutter pub upgrade` no futuro, pode precisar reaplicar essas correções nos plugins do pub cache.
