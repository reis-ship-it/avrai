#!/bin/bash
# Extract native libraries from Signal's Maven packages for Android using Gradle
# Phase 14: Signal Protocol Implementation - Hybrid Approach

set -e

echo "📦 Extracting Signal Protocol libraries for Android (using Gradle)"
echo ""

# Create directory structure
echo "Creating directory structure..."
mkdir -p native/signal_ffi/android/{armeabi-v7a,arm64-v8a,x86,x86_64}
mkdir -p temp/gradle_extract

# Create temporary Gradle project to download dependencies
echo "Creating temporary Gradle project..."
mkdir -p temp/gradle_extract/app
cd temp/gradle_extract

# Create build.gradle
cat > build.gradle << 'EOF'
buildscript {
    repositories {
        google()
        mavenCentral()
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            name = "SignalBuildArtifacts"
            url = uri("https://build-artifacts.signal.org/libraries/maven/")
        }
    }
}

configurations {
    signalLibs
}

dependencies {
    signalLibs 'org.signal:libsignal-android:0.16.0'
}

task extractLibs(type: Copy) {
    from configurations.signalLibs
    into 'extracted'
}
EOF

# Create settings.gradle
echo "rootProject.name = 'signal-extract'" > settings.gradle

echo "Downloading libsignal-android using Gradle..."
./gradlew extractLibs 2>&1 | grep -v "Downloading\|BUILD" || true

# Find the downloaded JAR
JAR_FILE=$(find .gradle -name "libsignal-android-*.jar" | head -1)

if [ -z "$JAR_FILE" ] || [ ! -f "$JAR_FILE" ]; then
    echo "❌ Error: Could not find downloaded JAR file"
    echo ""
    echo "Alternative: Manual download"
    echo "1. Visit: https://build-artifacts.signal.org/libraries/maven/org/signal/libsignal-android/"
    echo "2. Download the latest version JAR"
    echo "3. Extract manually: unzip libsignal-android-*.jar"
    exit 1
fi

echo "✅ Found JAR: $JAR_FILE"
echo ""

# Extract JAR
echo "Extracting JAR file..."
cd extracted
unzip -q "$JAR_FILE" -d jar_contents 2>/dev/null || {
    echo "⚠️  Direct extraction failed, trying alternative..."
    # Try extracting from Gradle cache
    cd ..
    JAR_FILE=$(find .gradle/caches -name "libsignal-android-*.jar" | head -1)
    if [ -f "$JAR_FILE" ]; then
        unzip -q "$JAR_FILE" -d extracted/jar_contents
    else
        echo "❌ Could not extract JAR"
        exit 1
    fi
    cd extracted
}

# Find native libraries
echo "Looking for native libraries..."
if [ -d "jar_contents/lib" ]; then
    LIB_DIR="jar_contents/lib"
elif [ -d "jar_contents/jni" ]; then
    LIB_DIR="jar_contents/jni"
else
    echo "⚠️  Warning: Could not find native libraries in expected location"
    echo "JAR contents:"
    find jar_contents -type f -name "*.so" 2>/dev/null | head -10
    echo ""
    echo "Please manually extract libraries from the JAR file"
    exit 1
fi

# Copy libraries for each architecture
echo "Copying native libraries..."
for arch in armeabi-v7a arm64-v8a x86 x86_64; do
    if [ -f "${LIB_DIR}/${arch}/libsignal_jni.so" ]; then
        cp "${LIB_DIR}/${arch}/libsignal_jni.so" "../../native/signal_ffi/android/${arch}/"
        echo "✅ Copied ${arch}/libsignal_jni.so"
    elif [ -f "${LIB_DIR}/${arch}/signal_jni.so" ]; then
        cp "${LIB_DIR}/${arch}/signal_jni.so" "../../native/signal_ffi/android/${arch}/libsignal_jni.so"
        echo "✅ Copied ${arch}/signal_jni.so (renamed to libsignal_jni.so)"
    else
        echo "⚠️  Warning: Library not found for ${arch}"
    fi
done

# Clean up
cd ../..
echo ""
echo "Cleaning up temporary files..."
rm -rf temp/gradle_extract

echo ""
echo "✅ Android libraries extracted successfully!"
echo ""
echo "Libraries are now in: native/signal_ffi/android/"
echo ""
echo "Next steps:"
echo "1. Verify libraries exist: ls -la native/signal_ffi/android/*/"
echo "2. Test Android build: flutter build apk --debug"
