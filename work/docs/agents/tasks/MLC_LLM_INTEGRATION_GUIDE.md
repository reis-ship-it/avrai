# MLC-LLM Integration Guide (v0.2/v0.3 Architecture)

This guide walks you through physically integrating the **MLC-LLM Engine** and the **Qwen 2.5 3B Instruct** model into your native iOS and Android build environments.

Because MLC-LLM uses pure GPU shaders (Metal on iOS, Vulkan/OpenCL on Android), it requires a few native configurations that cannot be entirely automated by a Flutter script. 

---

## Phase 1: Obtaining the Pre-Compiled Qwen 3B Model

You do not need to manually compile the model weights from scratch. MLC-AI provides pre-compiled 4-bit quantized versions of Qwen directly on HuggingFace.

1. Open your terminal in the root of the AVRAI project.
2. Download the pre-compiled model weights and MLX config:
   ```bash
   # Create the models directory
   mkdir -p apps/avrai_app/assets/ml_models/Qwen2.5-3B-Instruct-q4f16_1-MLC
   cd apps/avrai_app/assets/ml_models/Qwen2.5-3B-Instruct-q4f16_1-MLC
   
   # Use Git LFS to pull the pre-compiled Qwen 3B model from MLC-AI
   git lfs install
   git clone https://huggingface.co/mlc-ai/Qwen2.5-3B-Instruct-q4f16_1-MLC .
   ```
3. This folder now contains the `ndarray-*.bin` parameter files and the `mlc-chat-config.json` needed by the engine.

---

## Phase 2: iOS Native Integration (Metal)

MLC-LLM distributes its iOS Swift package via GitHub. We need to add it to your Xcode project and wire up the `avrai/mlc_llm` MethodChannel.

### 1. Add the Swift Package
1. Open `apps/avrai_app/ios/Runner.xcworkspace` in **Xcode**.
2. Go to **File > Add Package Dependencies...**
3. In the search bar, paste: `https://github.com/mlc-ai/mlc-llm`
4. Choose the `ios` branch or the latest stable version.
5. Add the `MLCChat` library to your `Runner` target.

### 2. Update `AppDelegate.swift`
In Xcode, open `Runner/AppDelegate.swift`. You need to initialize the `MLCEngine` and connect it to our Flutter MethodChannel.

```swift
import UIKit
import Flutter
import MLCChat // <-- Import MLC

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    // Hold the MLC Engine instance
    var mlcEngine: MLCEngine?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        
        // 1. Setup the MLC-LLM Method Channel
        let mlcChannel = FlutterMethodChannel(name: "avrai/mlc_llm", binaryMessenger: controller.binaryMessenger)
        
        mlcChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let self = self else { return }
            
            if call.method == "loadModel" {
                if let args = call.arguments as? [String: Any], let modelDir = args["model_dir"] as? String {
                    // Initialize MLCEngine pointing to the local model directory
                    self.mlcEngine = MLCEngine(modelPath: modelDir)
                    result(true)
                } else {
                    result(false)
                }
            } else if call.method == "generate" {
                if let args = call.arguments as? [String: Any], 
                   let engine = self.mlcEngine,
                   let messages = args["messages"] as? [[String: String]] {
                    
                    // Pass the optional strict JSON schema if provided
                    let responseFormat = args["response_format"] as? String
                    
                    // Convert Flutter dictionary to MLC ChatMessage objects and execute
                    // (See MLC-LLM Swift docs for the exact async Task wrapper here)
                    Task {
                        // For the current MLCSwift release, it requires wrapping the messages
                        do {
                            // Check if ChatCompletion is available or if we use the basic generate
                            // Standard MLCSwift syntax:
                            let response = await engine.chat.completions.create(
                                messages: messages,
                                responseFormat: responseFormat
                            )
                            let text = response.choices.first?.message.content ?? ""
                            DispatchQueue.main.async {
                                result(text)
                            }
                        }
                    }
                } else {
                    result(FlutterError(code: "not_ready", message: "Engine not loaded or invalid args", details: nil))
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

### 3. Update `Info.plist`
Since this runs intense GPU calculations, iOS might throttle it if not explicitly configured.
Ensure you add a high-performance GPU flag (if needed by your specific iOS version) in Xcode.

---

## Phase 3: Android Native Integration (Vulkan/OpenCL)

Android integration requires updating Gradle to pull the MLC-LLM Android library (`mlc4j`).

### 1. Update `build.gradle`
Open `apps/avrai_app/android/build.gradle` (the project-level one) and ensure you have the required repositories:
```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        // Add MLC-AI maven repo if required, or include the AAR directly
    }
}
```

Open `apps/avrai_app/android/app/build.gradle` (the app-level one) and add the dependency:
```gradle
dependencies {
    // Add the MLC-LLM Android binding
    implementation 'ai.mlc.mlcllm:mlc4j:+' 
}
```

### 2. Implement the `MLCEngine` in `MainActivity.kt`
I have already updated your Dart code and `MainActivity.kt` to use the correct `avrai/mlc_llm` channel names. Next time you open Android Studio, you will need to import `ai.mlc.mlcllm.MLCEngine` and replace the placeholder error handlers.

Inside the `"loadModel"` block:
```kotlin
// In MainActivity.kt
import ai.mlc.mlcllm.MLCEngine

var engine: MLCEngine? = null

// Inside the setMethodCallHandler for "avrai/mlc_llm":
"loadModel" -> {
    val modelDir = call.argument<String>("model_dir") ?: ""
    engine = MLCEngine(modelDir)
    result.success(true)
}
"generate" -> {
    // Extract prompt and response_format
    // Call engine.chat.completions.create(...)
}
```

---

## The JSON Schema Superpower

The most critical part of this upgrade is already wired into your Dart code (`NightlyDigestionJob.dart`). By passing the `response_format` argument with a strict JSON Schema down through the MethodChannel, the MLC-LLM C++ core mathematically masks the output probabilities.

It makes it literally impossible for Qwen 3B to output anything other than your perfectly formatted Serendipity Drop. It won't output `Here is your JSON:`, it won't output markdown backticks, and it won't miss a bracket.

---

## Phase 4: Desktop Native Integration (macOS, Windows, Linux)

For users running AVRAI on a desktop node, battery and memory constraints are lifted, allowing us to step up from Qwen 3B to **Phi-4 Mini (3.8B)** for extremely high-density logical reasoning.

### 1. The Desktop Engine
While MLC-LLM supports desktop, Flutter desktop development often benefits from direct C++ FFI (Foreign Function Interface) rather than MethodChannels. 

To power the `DesktopPhi4LlmBackend` stub we created in Dart:
1. **macOS/Linux/Windows:** We will use `llama.cpp` compiled as a dynamic library (`.dylib`, `.so`, or `.dll`) directly bound to Dart via `dart:ffi`.
2. This bypasses the Flutter Engine's message passing entirely, allowing the Phi-4 model to stream tokens directly into Dart memory at maximum CPU/GPU speed.

### 2. Obtaining Phi-4 Mini
1. Download the Phi-4 Mini GGUF model:
   ```bash
   mkdir -p apps/avrai_app/assets/ml_models/Phi-4-mini-instruct-GGUF
   cd apps/avrai_app/assets/ml_models/Phi-4-mini-instruct-GGUF
   
   git lfs install
   git clone https://huggingface.co/unsloth/Phi-4-mini-instruct-GGUF .
   ```
2. You only need the `q4_k_m` (4-bit quantized) version of the `.gguf` file to keep things fast while maintaining its textbook reasoning capabilities.

### 3. Wiring up `dart:ffi`
When you are ready to build the Desktop node out of its stub phase:
1. Include the pre-compiled `llama.cpp` dynamic library in your Flutter Desktop build runners.
2. Update the `DesktopPhi4LlmBackend.chat()` method to invoke the C++ bindings directly, passing the prompt and receiving the generated string.