#!/bin/bash
export PATH=/root/.cargo/bin:/usr/local/bin:/usr/bin:/bin
export ANDROID_NDK_HOME=/opt/android-ndk/android-ndk-r28c
export ANDROID_NDK_ROOT=$ANDROID_NDK_HOME
export VCPKG_ROOT=/opt/vcpkg
export OPENSSL_NO_VENDOR=1
export AARCH64_LINUX_ANDROID_OPENSSL_DIR=/opt/vcpkg/installed/arm64-android
export PKG_CONFIG_ALLOW_CROSS=1
export CLANG_PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/clang
export BINDGEN_EXTRA_CLANG_ARGS="--sysroot=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot --target=aarch64-linux-android21"

echo "Cargo build starting..."
cd /mnt/d/bmdesk
cargo ndk --platform 21 --target aarch64-linux-android build --locked --release --features flutter,hwcodec 2>&1
RC=$?
echo "Build exit code: $RC"
exit $RC
