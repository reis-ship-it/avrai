#!/bin/bash
# Extract native libraries from Signal's Maven packages for Android
# Uses the existing Android Gradle wrapper in the Flutter project
# Phase 14: Signal Protocol Implementation - Hybrid Approach

set -e

echo "📦 Extracting Signal Protocol libraries for Android (via Gradle)"
echo ""

# Check if we're in the right directory
if [ ! -d "android" ]; then
    echo "❌ Error: Must run from SPOTS project root"
    exit 1
fi

# Create directory structure
echo "Creating directory structure..."
mkdir -p native/signal_ffi/android/{armeabi-v7a,arm64-v8a,x86,x86_64}

# Create a temporary Gradle task to download and extract
cd android

# Create a temporary build file for extraction
cat > extract_signal_libs.gradle << 'EOF'
// Temporary Gradle script to extract Signal libraries
configurations {
    signalLibs
}

repositories {
    google()
    mavenCentral()
    maven {
        name = "SignalBuildArtifacts"
        url = uri("https://build-artifacts.signal.org/libraries/maven/")
    }
}

dependencies {
    signalLibs 'org.signal:libsignal-android:0.86.9'
}

task extractSignalLibs {
    doLast {
        def signalLibs = configurations.signalLibs
        signalLibs.each { file ->
            println "Found: ${file.name}"
            copy {
                from zipTree(file)
                into "${projectDir}/../temp/signal_extract"
            }
        }
    }
}
EOF

echo "Downloading libsignal-android using Gradle..."
if [ -f "gradlew" ]; then
    ./gradlew -b extract_signal_libs.gradle extractSignalLibs 2>&1 | grep -E "(Found|Download|BUILD)" || true
else
    echo "❌ Error: gradlew not found in android/ directory"
    echo "Please run: cd android && flutter build apk --debug (to generate gradlew)"
    exit 1
fi

# Find and extract native libraries
cd ../temp/signal_extract

echo ""
echo "Looking for native libraries..."

# Find .so files
SO_FILES=$(find . -name "*.so" 2>/dev/null)

if [ -z "$SO_FILES" ]; then
    echo "❌ Error: No .so files found in extracted JAR"
    echo ""
    echo "JAR contents:"
    find . -type f | head -20
    echo ""
    echo "Alternative approach:"
    echo "1. Add libsignal-android to android/app/build.gradle dependencies"
    echo "2. Build APK: flutter build apk --debug"
    echo "3. Extract from built APK: unzip app-debug.apk lib/*/libsignal_jni.so"
    exit 1
fi

echo "Found native libraries:"
echo "$SO_FILES" | head -10

# Copy libraries to appropriate architecture directories
echo ""
echo "Copying native libraries..."

for so_file in $SO_FILES; do
    # Determine architecture from path
    if echo "$so_file" | grep -q "armeabi-v7a"; then
        ARCH="armeabi-v7a"
    elif echo "$so_file" | grep -q "arm64-v8a"; then
        ARCH="arm64-v8a"
    elif echo "$so_file" | grep -q "/x86/"; then
        ARCH="x86"
    elif echo "$so_file" | grep -q "x86_64"; then
        ARCH="x86_64"
    else
        echo "⚠️  Warning: Could not determine architecture for $so_file"
        continue
    fi
    
    # Get library name
    LIB_NAME=$(basename "$so_file")
    
    # Copy to target directory
    cp "$so_file" "../../native/signal_ffi/android/${ARCH}/${LIB_NAME}"
    echo "✅ Copied to ${ARCH}/${LIB_NAME}"
done

# Clean up
cd ../..
rm -rf temp/signal_extract
rm -f android/extract_signal_libs.gradle

echo ""
echo "✅ Android libraries extracted successfully!"
echo ""
echo "Libraries are now in: native/signal_ffi/android/"
echo ""
echo "Verifying..."
for arch in armeabi-v7a arm64-v8a x86 x86_64; do
    if [ -f "native/signal_ffi/android/${arch}/libsignal_jni.so" ] || [ -f "native/signal_ffi/android/${arch}/signal_jni.so" ]; then
        echo "  ✅ ${arch}: Library found"
    else
        echo "  ⚠️  ${arch}: Library not found"
    fi
done
echo ""
echo "Next steps:"
echo "1. Verify libraries: ls -la native/signal_ffi/android/*/"
echo "2. Test Android build: flutter build apk --debug"
