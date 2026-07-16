#!/bin/bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export ANDROID_HOME=/mnt/c/Users/inter/AppData/Local/Android/Sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export ANDROID_NDK_HOME=/opt/android-ndk/android-ndk-r28c
export PATH=/opt/flutter-stable/bin:$JAVA_HOME/bin:/usr/bin:/bin

echo "Flutter version:"
flutter --version 2>&1 | head -3
echo "JAVA_HOME=$JAVA_HOME"
java -version 2>&1

# Clear Gradle cache
rm -rf /mnt/c/Users/inter/.gradle/caches/7.6.4 2>/dev/null

cd /mnt/d/bmdesk/flutter
flutter build apk --release --target-platform android-arm64 --split-per-abi 2>&1
RC=$?
echo "Build exit code: $RC"
exit $RC
