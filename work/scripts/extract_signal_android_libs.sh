#!/bin/bash
# Extract native libraries from Signal's Maven packages for Android
# Phase 14: Signal Protocol Implementation - Hybrid Approach

set -e

echo "📦 Extracting Signal Protocol libraries for Android"
echo ""

# Configuration
MAVEN_REPO="https://build-artifacts.signal.org/libraries/maven"
GROUP_ID="org.signal"
ARTIFACT_ID="libsignal-android"
VERSION="0.86.9"  # Latest version as of Dec 2025 (checked via maven-metadata.xml)

# Create directory structure
echo "Creating directory structure..."
mkdir -p native/signal_ffi/android/{armeabi-v7a,arm64-v8a,x86,x86_64}
mkdir -p temp/maven_extract

# Maven artifact path
ARTIFACT_PATH="${GROUP_ID//./\/}/${ARTIFACT_ID}/${VERSION}"
JAR_URL="${MAVEN_REPO}/${ARTIFACT_PATH}/${ARTIFACT_ID}-${VERSION}.jar"

echo "Downloading libsignal-android from Maven..."
echo "URL: ${JAR_URL}"
echo ""

# Check if wget or curl is available
if command -v wget &> /dev/null; then
    wget -O temp/maven_extract/libsignal-android.jar "${JAR_URL}"
elif command -v curl &> /dev/null; then
    curl -L -o temp/maven_extract/libsignal-android.jar "${JAR_URL}"
else
    echo "❌ Error: Neither wget nor curl found. Please install one of them."
    echo ""
    echo "Manual steps:"
    echo "1. Download from: ${JAR_URL}"
    echo "2. Save as: temp/maven_extract/libsignal-android.jar"
    echo "3. Run this script again"
    exit 1
fi

if [ ! -f "temp/maven_extract/libsignal-android.jar" ]; then
    echo "❌ Error: Failed to download JAR file"
    echo ""
    echo "Manual download steps:"
    echo "1. Visit: ${MAVEN_REPO}/${ARTIFACT_PATH}/"
    echo "2. Download: ${ARTIFACT_ID}-${VERSION}.jar"
    echo "3. Save as: temp/maven_extract/libsignal-android.jar"
    echo "4. Run this script again"
    exit 1
fi

echo "✅ JAR downloaded"
echo ""

# Extract JAR file
echo "Extracting JAR file..."
cd temp/maven_extract
unzip -q libsignal-android.jar
cd ../..

# Copy native libraries
echo "Copying native libraries..."

# Check if libraries exist in extracted JAR
if [ -d "temp/maven_extract/lib" ]; then
    # Standard Maven structure
    LIB_DIR="temp/maven_extract/lib"
elif [ -d "temp/maven_extract/jni" ]; then
    # Alternative structure
    LIB_DIR="temp/maven_extract/jni"
else
    echo "⚠️  Warning: Could not find native libraries in expected location"
    echo "JAR contents:"
    ls -la temp/maven_extract/
    echo ""
    echo "Please manually extract libraries from the JAR file"
    exit 1
fi

# Copy libraries for each architecture
for arch in armeabi-v7a arm64-v8a x86 x86_64; do
    if [ -f "${LIB_DIR}/${arch}/libsignal_jni.so" ]; then
        cp "${LIB_DIR}/${arch}/libsignal_jni.so" "native/signal_ffi/android/${arch}/"
        echo "✅ Copied ${arch}/libsignal_jni.so"
    elif [ -f "${LIB_DIR}/${arch}/signal_jni.so" ]; then
        cp "${LIB_DIR}/${arch}/signal_jni.so" "native/signal_ffi/android/${arch}/libsignal_jni.so"
        echo "✅ Copied ${arch}/signal_jni.so (renamed to libsignal_jni.so)"
    else
        echo "⚠️  Warning: Library not found for ${arch}"
    fi
done

# Clean up
echo ""
echo "Cleaning up temporary files..."
rm -rf temp/maven_extract

echo ""
echo "✅ Android libraries extracted successfully!"
echo ""
echo "Libraries are now in: native/signal_ffi/android/"
echo ""
echo "Next steps:"
echo "1. Update android/app/build.gradle to include jniLibs.srcDirs"
echo "2. Update signal_ffi_bindings.dart to load libsignal_jni.so"
echo "3. Test Android build: flutter build apk --debug"
