# BMDesk Customizations

This project is a fork of RustDesk, branded as **BMDesk**.

## Brand Identity

- **App name:** `BMDesk` (set in `libs/hbb_common/src/config.rs:72`)
- **Update server:** `https://bmdesk-down.bmhelp.click`
- **GitHub org:** `edbminfo`
- **GitHub repo:** `bmdesk`

## Key Customizations from Upstream RustDesk

### 1. Update Server

| File | Change |
|------|--------|
| `src/common.rs:1028` | Custom update URL `https://bmdesk-down.bmhelp.click/releases/latest` |
| `src/updater.rs:334-350` | URL validation for `bmdesk-down.bmhelp.click` |
| `src/common.rs:2303` | `is_custom_client()` returns `true` when APP_NAME != "RustDesk" |

### 2. Flutter UI - Update Notifications (UNBLOCKED for custom clients)

| File | Change |
|------|--------|
| `flutter/lib/common.dart:4070` | Removed `!bind.isCustomClient()` guard - update event handler now works for BMDesk |
| `flutter/lib/desktop/pages/desktop_home_page.dart:451` | Removed `!bind.isCustomClient()` guard - update card now shows for BMDesk |
| `flutter/lib/desktop/pages/desktop_home_page.dart:457` | Download URL changed to `https://bmdesk-down.bmhelp.click` |
| `flutter/lib/mobile/pages/connection_page.dart:88` | Removed `!bind.isCustomClient()` guard - mobile update card shows |
| `flutter/lib/mobile/pages/connection_page.dart:127` | URL changed from `rustdesk.com/download` to `bmdesk-down.bmhelp.click` |

### 3. Android Build Fixes

| File | Change |
|------|--------|
| `flutter/pubspec.yaml` | `external_path: 2.2.0`, `flutter_plugin_android_lifecycle: 2.0.35`, `file_picker: 8.3.7`, `sqflite: 2.4.3`, `uni_links: 0.5.1` (hosted) |
| `flutter/android/settings.gradle` | AGP `8.9.1`, Kotlin `2.2.20` |
| `flutter/android/gradle-wrapper.properties` | Gradle `8.14` |
| `flutter/android/app/build.gradle` | `compileSdk 36`, `ndkVersion 28.2.13676358`, namespace `com.carriez.flutter_hbb`, core desugaring |
| `flutter/android/gradle.properties` | `kotlin.incremental=false`, `org.gradle.jvmargs=-Xmx4096M` |
| `flutter/android/app/AndroidManifest.xml` | Removed `package=` attribute |

### 4. ExternalPath API Migration

| File | Change |
|------|--------|
| `flutter/lib/models/native_model.dart:157` | Null check for `ExternalPath.getExternalStorageDirectories()` (v2.2.0 returns nullable) |

### 5. Version

| File | Value |
|------|-------|
| `src/version.rs` | `1.4.10` |
| `Cargo.toml` | `1.4.10` |
| `flutter/pubspec.yaml` | `1.4.9+67` |
| `flutter/android/local.properties` | `flutter.versionName=1.4.10` |

## Building

### Windows
```powershell
python build.py --portable --flutter
```
Output: `rustdesk-1.4.10-install.exe`

### Android
1. Compile .so in WSL (arm64 + armv7)
2. Copy to `flutter/android/app/src/main/jniLibs/<abi>/`
3. Copy `libc++_shared.so` from NDK
4. `flutter build apk --release --target-platform android-arm64,android-arm --split-per-abi`
