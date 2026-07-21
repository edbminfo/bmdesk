#!/bin/bash
set -e

MODE=${MODE:-release}

cd /workspace

echo "=== BMDesk Android Docker Build ==="
echo "Mode: $MODE"

# Build vcpkg deps for all ABIs
echo ">>> Building vcpkg deps..."
for abi in arm64-v8a armeabi-v7a x86_64 x86; do
    echo "  -> $abi"
    bash flutter/build_android_deps.sh "$abi"
done

# Build Rust native libs per ABI
echo ">>> Building Rust native libs..."
for target in aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android; do
    echo "  -> $target"
    cargo ndk --platform 21 --target "$target" build --locked --release --features flutter,hwcodec 2>&1 || \
    cargo ndk --platform 21 --target "$target" build --locked --release --features flutter 2>&1
done

# Pre-build Flutter
cd flutter
sed -i 's/extended_text:.*/extended_text: ^14.0.0/' pubspec.yaml
flutter pub get
cd ..

# Build APK (split per ABI)
echo ">>> Building APK (split per ABI)..."
cd flutter
flutter build apk --split-per-abi --target-platform android-arm64,android-arm,android-x64 --${MODE} --obfuscate --split-debug-info ./split-debug-info
cd ..

# Build AAB
echo ">>> Building AAB..."
cd flutter
flutter build appbundle --target-platform android-arm64,android-arm,android-x64 --${MODE} --obfuscate --split-debug-info ./split-debug-info
cd ..

echo "=== Build Complete ==="
echo "APK: flutter/build/app/outputs/flutter-apk/"
echo "AAB: flutter/build/app/outputs/bundle/release/"
