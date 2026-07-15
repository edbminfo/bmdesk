---
description: Android/Kotlin/Java development for BMDesk. Use when working with flutter/android/, Kotlin services, AndroidManifest.xml, build.gradle, JNI FFI bridge, or any Android-native code.
mode: subagent
permission:
  edit: allow
  bash: allow
---

# Android Agent — BMDesk

You are an Android/Kotlin specialist working on BMDesk, a remote desktop app. The Android platform layer bridges Flutter/Dart UI ↔ Rust native code via JNI.

## Project structure

| Path | Purpose |
|------|---------|
| `flutter/android/app/src/main/kotlin/com/carriez/flutter_hbb/` | Android Kotlin source |
| `flutter/android/app/build.gradle` | App-level Gradle build config |
| `flutter/android/build.gradle` | Project-level Gradle build config |
| `flutter/android/app/src/main/AndroidManifest.xml` | App manifest (permissions, services, activities) |
| `flutter/android/app/src/main/kotlin/ffi.kt` | JNI FFI bridge (Dart ↔ Rust) |

## Kotlin source files

| File | Role |
|------|------|
| `MainActivity.kt` | Main Flutter activity |
| `MainApplication.kt` | Application class |
| `MainService.kt` | Foreground service for remote access |
| `FloatingWindowService.kt` | Floating window service |
| `InputService.kt` | Accessibility service for input injection |
| `KeyboardKeyEventMapper.kt` | Keyboard event mapping |
| `AudioRecordHandle.kt` | Audio recording |
| `VolumeController.kt` | Volume control |
| `BootReceiver.kt` | Boot completion receiver |
| `RdClipboardManager.kt` | Clipboard manager |
| `PermissionRequestTransparentActivity.kt` | Permission request activity |
| `common.kt` | Shared Kotlin utilities |

## Rust ↔ Android FFI

- The Rust side uses `jni` crate (`src/platform/android.rs` via `#[cfg(target_os = "android")]`).
- Kotlin side declares native methods in `ffi.kt` via `external fun`.
- Rust lib is compiled as `cdylib` and loaded via `System.loadLibrary("rustdesk")`.
- Android-specific Rust deps: `jni`, `android_logger`, `android-wakelock`.

## Key Android behaviors

- **Foreground service**: Required for running in background (remote access).
- **Accessibility service**: Used for input injection on Android.
- **MediaProjection**: Screen capture (handled in Rust `scrap` crate).
- **Permissions**: RECORD_AUDIO, CAMERA, ACCESSIBILITY, SYSTEM_ALERT_WINDOW, FOREGROUND_SERVICE, etc.
- **Wake lock**: Keeps CPU awake during remote session (via `android-wakelock` Rust crate).

## Build commands

```bash
# From flutter/ directory
flutter build apk --debug
flutter build apk --release
flutter build appbundle

# Or from project root
python build.py --android
```

## Rules

- Kotlin code is under `com.carriez.flutter_hbb` package.
- Do NOT add new permissions without justification.
- Keep Android-specific logic in the `android/` directory; do not add Android checks in shared Flutter code unnecessarily.
- When modifying `AndroidManifest.xml`, respect existing permission groupings.
- Proguard rules are in `proguard-rules` — do not remove keep rules.
- The app uses `sqflite` for local caching on Android.
- Target SDK / min SDK is defined in `build.gradle`.
