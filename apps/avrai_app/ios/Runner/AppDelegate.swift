import UIKit
import Flutter
import CoreBluetooth
import BackgroundTasks

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let backgroundRefreshIdentifier = "com.avrai.app.background_runtime_refresh"
    private var significantLocationWakeCoordinator: SignificantLocationWakeCoordinator?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let backgroundWakeStore = BackgroundWakeStore.shared
        let launchedForBackgroundWake = backgroundWakeStore.captureLaunchOptions(launchOptions)
        registerBackgroundRefreshTasks(backgroundWakeStore: backgroundWakeStore)
        significantLocationWakeCoordinator = SignificantLocationWakeCoordinator(
            backgroundWakeStore: backgroundWakeStore,
            backgroundRefreshIdentifier: backgroundRefreshIdentifier
        )
        significantLocationWakeCoordinator?.start()
        GeneratedPluginRegistrant.register(with: self)
        if let controller = window?.rootViewController as? FlutterViewController {
            configureUiRuntimeChannels(
                controller: controller,
                backgroundWakeStore: backgroundWakeStore
            )
        }
        if launchedForBackgroundWake {
            BackgroundRuntimeEngineHost.shared.executeNow(
                backgroundWakeStore: backgroundWakeStore,
                backgroundRefreshIdentifier: backgroundRefreshIdentifier
            )
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        return super.application(app, open: url, options: options)
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        BackgroundWakeStore.shared.scheduleBackgroundRefresh(
            taskIdentifier: backgroundRefreshIdentifier,
            earliestInSeconds: 30 * 60
        )
        super.applicationDidEnterBackground(application)
    }

    private func registerBackgroundRefreshTasks(backgroundWakeStore: BackgroundWakeStore) {
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: backgroundRefreshIdentifier,
                using: nil
            ) { task in
                guard let refreshTask = task as? BGAppRefreshTask else {
                    task.setTaskCompleted(success: false)
                    return
                }
                backgroundWakeStore.enqueueInvocation(
                    reason: "background_task_window",
                    platformSource: "ios_bg_task"
                )
                backgroundWakeStore.scheduleBackgroundRefresh(
                    taskIdentifier: self.backgroundRefreshIdentifier,
                    earliestInSeconds: 30 * 60
                )
                var completionReported = false
                let complete: (Bool) -> Void = { success in
                    guard !completionReported else { return }
                    completionReported = true
                    refreshTask.setTaskCompleted(success: success)
                }
                refreshTask.expirationHandler = {
                    BackgroundRuntimeEngineHost.shared.cancelCurrentExecution()
                    complete(false)
                }
                BackgroundRuntimeEngineHost.shared.executeNow(
                    backgroundWakeStore: backgroundWakeStore,
                    backgroundRefreshIdentifier: self.backgroundRefreshIdentifier,
                    completion: complete
                )
            }
        }
    }

    private func configureUiRuntimeChannels(
        controller: FlutterViewController,
        backgroundWakeStore: BackgroundWakeStore
    ) {
        let mlcChannel = FlutterMethodChannel(name: "avrai/mlc_llm", binaryMessenger: controller.binaryMessenger)

        mlcChannel.setMethodCallHandler { call, result in
            switch call.method {
            case "loadModel", "generate", "startStream":
                result(
                    FlutterError(
                        code: "unavailable",
                        message: "Local iOS LLM runtime is not bundled in this beta build.",
                        details: nil
                    )
                )
            default:
                result(FlutterMethodNotImplemented)
            }
        }

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

        configureBackgroundRuntimeChannel(
            binaryMessenger: controller.binaryMessenger,
            backgroundWakeStore: backgroundWakeStore,
            backgroundRefreshIdentifier: backgroundRefreshIdentifier
        )
    }
}
