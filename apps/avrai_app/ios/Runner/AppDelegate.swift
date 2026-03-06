import UIKit
import Flutter
import MLCSwift

@main
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
                    // Initialize or reuse MLCEngine for the local model directory
                    if self.mlcEngine == nil {
                        self.mlcEngine = MLCEngine()
                    }
                    result(true)
                } else {
                    result(false)
                }
            } else if call.method == "generate" {
                if let args = call.arguments as? [String: Any], 
                   let engine = self.mlcEngine,
                   let messages = args["messages"] as? [[String: String]] {
                    
                    let responseFormat = args["response_format"] as? String
                    
                    Task {
                        var mlcMessages: [ChatCompletionMessage] = []
                        for msg in messages {
                            if let roleString = msg["role"], let content = msg["content"] {
                                let role: ChatCompletionRole = (roleString == "system") ? .system : (roleString == "user" ? .user : .assistant)
                                mlcMessages.append(ChatCompletionMessage(role: role, content: content))
                            }
                        }

                        var format: ResponseFormat? = nil
                        if let schema = responseFormat {
                            format = ResponseFormat(type: "json_object", schema: schema)
                        }

                        let stream = await engine.chat.completions.create(
                            messages: mlcMessages,
                            response_format: format
                        )

                        var fullContent = ""
                        for await chunk in stream {
                            if let delta = chunk.choices.first?.delta.content {
                                fullContent += delta.asText()
                            }
                        }

                        DispatchQueue.main.async {
                            result(fullContent)
                        }
                    }
                } else {
                    result(FlutterError(code: "not_ready", message: "Engine not loaded or invalid args", details: nil))
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        // 2. Stub BLE Peripheral channel for iOS-native fallback path
        let blePeripheralChannel = FlutterMethodChannel(
            name: "avra/ble_peripheral",
            binaryMessenger: controller.binaryMessenger,
        )
        blePeripheralChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "startPeripheral", "stopPeripheral", "updatePayload", "updatePreKeyPayload", "updateServiceDataFrameV1":
                print("[AVRAI] iOS BLE Peripheral channel is currently stubbed; fallback to non-BLE lane")
                result(false)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // 3. Stub BLE foreground channel for parity with Android transport bridge
        let bleForegroundChannel = FlutterMethodChannel(
            name: "avra/ble_foreground",
            binaryMessenger: controller.binaryMessenger,
        )
        bleForegroundChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "startService", "stopService", "updateScanInterval":
                print("[AVRAI] iOS BLE Foreground channel is currently stubbed; fallback to non-foreground lane")
                result(false)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // 4. Stub BLE inbox channel for parity with Android transport bridge
        let bleInboxChannel = FlutterMethodChannel(
            name: "avra/ble_inbox",
            binaryMessenger: controller.binaryMessenger,
        )
        bleInboxChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "pollMessages":
                result([])
            case "clearMessages":
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        return super.application(app, open: url, options: options)
    }
}
