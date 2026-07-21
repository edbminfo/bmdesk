# BMDesk - Instruções de Build Local

## Rápido (scripts prontos)

Cada plataforma tem seu próprio workspace isolado em `D:\vcpkg-installed\`. Use:

```bat
scripts\build_windows.bat
scripts\build_android.bat arm64     # 64-bit
scripts\build_android.bat arm       # 32-bit
scripts\build_android.bat all       # ambos
scripts\install_apk.bat             # instala APK 64-bit no celular
```

Ou com modo debug: `set MODE=debug && scripts\build_windows.bat`

## Pré-requisitos (todos)

- Rust: `https://rustup.rs`
- Git: `https://git-scm.com`
- Vcpkg: `D:\vcpkg` (clonar de https://github.com/microsoft/vcpkg)
- NDK 28.2.13676358 (apenas Android): instalar via Android Studio ou manualmente

## Isolamento de Workspace

Cada script usa `--x-install-root` para isolar dependências vcpkg:

```
D:\vcpkg-installed\
├── windows\        → build_windows.bat
├── android-arm64\  → build_android.bat arm64
└── android-arm\    → build_android.bat arm
```

Windows e Android não interferem mais um no outro.

## Clonar o repositório

```bash
git clone --recurse-submodules https://github.com/edbminfo/bmdesk.git
cd bmdesk
```

O submodule `libs/hbb_common` é privado. Configure o token:

```bash
git config --global url."https://SEU_TOKEN@github.com".insteadOf "https://github.com"
```

---

## Windows

### 1. Instalar dependências vcpkg

```powershell
$env:VCPKG_ROOT = "D:\vcpkg"
cd D:\bmdesk
& "$env:VCPKG_ROOT\vcpkg.exe" install --triplet x64-windows-static
```

### 2. Compilar Rust nativo

```powershell
cargo build --locked --features flutter,hwcodec --release
```

### 3. Compilar Flutter

```powershell
cd flutter
flutter pub get
flutter build windows --release
```

**Saída:** `flutter\build\windows\x64\runner\Release\`

---

## Android (64-bit + 32-bit)

### 1. Instalar dependências vcpkg

Para arm64 (64-bit):
```powershell
$env:ANDROID_NDK_HOME = "C:\Users\inter\AppData\Local\Android\sdk\ndk\28.2.13676358"
# Precisa corrigir headers do NDK (bug upstream):
# - Adicionar `#define __INTRODUCED_IN(x)` em sys/cdefs.h
# - Remover `__attribute__((__nomerge__))` de abort() em stdlib.h
# - Ver BUILD.md seção "Correções NDK" abaixo

& "$env:VCPKG_ROOT\vcpkg.exe" install --triplet arm64-android
```

Para armv7 (32-bit):
```powershell
& "$env:VCPKG_ROOT\vcpkg.exe" install --triplet arm-neon-android
# Criar link: arm-android -> arm-neon-android
New-Item -ItemType Junction -Path "D:\vcpkg\installed\arm-android" -Target "D:\vcpkg\installed\arm-neon-android"
```

> Nota: vcpkg só mantém UM conjunto de pacotes por vez. Ao alternar entre Windows e Android, reinstale com o triplet correspondente.

### 2. Compilar Rust nativo

arm64:
```powershell
$env:ANDROID_NDK_HOME = "C:\Users\inter\AppData\Local\Android\sdk\ndk\28.2.13676358"
$env:SODIUM_LIB_DIR = "D:\vcpkg\installed\arm64-android\lib"
$env:OPENSSL_DIR = "D:\vcpkg\installed\arm64-android"
$env:AARCH64_LINUX_ANDROID_OPENSSL_NO_VENDOR = "1"
$env:PKG_CONFIG_PATH = "D:\vcpkg\installed\arm64-android\lib\pkgconfig"
cargo ndk --platform 21 --target aarch64-linux-android build --locked --release --features flutter,hwcodec
```

armv7 (32-bit):
```powershell
$env:SODIUM_LIB_DIR = "D:\vcpkg\installed\arm-neon-android\lib"
$env:OPENSSL_DIR = "D:\vcpkg\installed\arm-neon-android"
$env:ARMV7_LINUX_ANDROIDEABI_OPENSSL_NO_VENDOR = "1"
$env:PKG_CONFIG_PATH = "D:\vcpkg\installed\arm-neon-android\lib\pkgconfig"
cargo ndk --platform 21 --target armv7-linux-androideabi build --locked --release --features flutter,hwcodec
```

### 3. Compilar APK

```powershell
cd flutter

# APK split por arquitetura
flutter build apk --split-per-abi --target-platform android-arm64,android-arm --release --obfuscate --split-debug-info split-debug-info

# Ou APK único com todas arquiteturas
flutter build apk --target-platform android-arm64,android-arm --release --obfuscate --split-debug-info split-debug-info

# AAB para Play Store
flutter build appbundle --target-platform android-arm64,android-arm --release --obfuscate --split-debug-info split-debug-info
```

**Saída APK:** `flutter\build\app\outputs\flutter-apk\`
**Saída AAB:** `flutter\build\app\outputs\bundle\release\`

### 4. Instalar no dispositivo

```powershell
adb install build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

Se falhar com verificação Play Protect:
```powershell
adb shell settings put global package_verifier_enable 0
adb install -t build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

---

## Android via Docker (Linux, isola dependências)

```bash
docker build -t bmdesk-android -f Dockerfile.android .
docker run --rm -v "$(pwd):/workspace" bmdesk-android
```

---

## Correções NDK (Windows, necessário para compilar Android)

Estas correções são necessárias nos headers do NDK para resolver bugs de compatibilidade com bindgen:

### 1. `sys/cdefs.h`
Adicionar após `#define __END_DECLS`:
```c
#ifndef __INTRODUCED_IN
#define __INTRODUCED_IN(x)
#endif
```

### 2. `stdlib.h`
Remover `__attribute__((__nomerge__))` de:
```c
__noreturn void abort(void) __attribute__((__nomerge__));
```
Deixar apenas:
```c
__noreturn void abort(void);
```

**Caminhos dos arquivos:**
```
%LOCALAPPDATA%\Android\sdk\ndk\28.2.13676358\toolchains\llvm\prebuilt\windows-x86_64\sysroot\usr\include\
```

---

## CI (GitHub Actions)

Disparar build manual:
1. Acessar https://github.com/edbminfo/bmdesk/actions/workflows/flutter-nightly.yml
2. "Run workflow" → selecionar plataformas → "Run workflow"

Ou via CLI:
```bash
gh workflow run flutter-nightly.yml -f windows=true -f android=true --repo edbminfo/bmdesk
```
