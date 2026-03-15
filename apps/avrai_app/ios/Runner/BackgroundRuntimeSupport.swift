import Foundation
import Flutter
import BackgroundTasks
import CoreLocation

final class BackgroundWakeStore {
    static let shared = BackgroundWakeStore()

    private let defaults = UserDefaults.standard
    private let storageKey = "avrai_background_wake_invocations_v2"
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    func captureLaunchOptions(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        guard let launchOptions else { return false }
        var launchedForBackgroundWake = false
        if launchOptions[.location] != nil {
            enqueueInvocation(
                reason: "significant_location",
                platformSource: "ios_launch_location"
            )
            launchedForBackgroundWake = true
        }
        if launchOptions[.bluetoothCentrals] != nil || launchOptions[.bluetoothPeripherals] != nil {
            enqueueInvocation(
                reason: "ble_encounter",
                platformSource: "ios_launch_bluetooth"
            )
            launchedForBackgroundWake = true
        }
        if launchOptions[.remoteNotification] != nil {
            enqueueInvocation(
                reason: "background_task_window",
                platformSource: "ios_launch_remote_notification"
            )
            launchedForBackgroundWake = true
        }
        return launchedForBackgroundWake
    }

    func enqueueInvocation(
        reason: String,
        platformSource: String,
        isWifiAvailable: Bool? = nil,
        isIdle: Bool? = nil,
        wakeTimestampUtc: Date = Date()
    ) {
        var pending = loadInvocations()
        var payload: [String: Any] = [
            "reason": reason,
            "platform_source": platformSource,
            "wake_timestamp_utc": isoFormatter.string(from: wakeTimestampUtc),
        ]
        if let isWifiAvailable {
            payload["is_wifi_available"] = isWifiAvailable
        }
        if let isIdle {
            payload["is_idle"] = isIdle
        }
        pending.append(payload)
        if pending.count > 48 {
            pending = Array(pending.suffix(48))
        }
        defaults.set(pending, forKey: storageKey)
    }

    func drainInvocations() -> [[String: Any]] {
        let invocations = loadInvocations()
        defaults.removeObject(forKey: storageKey)
        return invocations
    }

    func drain() -> [String] {
        return drainInvocations().compactMap { $0["reason"] as? String }
    }

    func hasPendingInvocations() -> Bool {
        return !loadInvocations().isEmpty
    }

    func scheduleBackgroundRefresh(taskIdentifier: String, earliestInSeconds: Double) {
        guard #available(iOS 13.0, *) else { return }
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: max(earliestInSeconds, 15 * 60))
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Best-effort scheduling.
        }
    }

    func cancelBackgroundRefresh(taskIdentifier: String) {
        guard #available(iOS 13.0, *) else { return }
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
    }

    private func loadInvocations() -> [[String: Any]] {
        let raw = defaults.array(forKey: storageKey) ?? []
        return raw.compactMap { $0 as? [String: Any] }.filter {
            (($0["reason"] as? String)?.isEmpty == false)
        }
    }
}

final class SignificantLocationWakeCoordinator: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let backgroundWakeStore: BackgroundWakeStore
    private let backgroundRefreshIdentifier: String

    init(
        backgroundWakeStore: BackgroundWakeStore,
        backgroundRefreshIdentifier: String
    ) {
        self.backgroundWakeStore = backgroundWakeStore
        self.backgroundRefreshIdentifier = backgroundRefreshIdentifier
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        manager.pausesLocationUpdatesAutomatically = true
    }

    func start() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        let authorizationStatus = CLLocationManager.authorizationStatus()
        switch authorizationStatus {
        case .authorizedAlways:
            manager.startMonitoringSignificantLocationChanges()
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways {
            manager.startMonitoringSignificantLocationChanges()
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard !locations.isEmpty else { return }
        backgroundWakeStore.enqueueInvocation(
            reason: "significant_location",
            platformSource: "ios_significant_location_update"
        )
        BackgroundRuntimeEngineHost.shared.executeNow(
            backgroundWakeStore: backgroundWakeStore,
            backgroundRefreshIdentifier: backgroundRefreshIdentifier
        )
    }
}

func configureBackgroundRuntimeChannel(
    binaryMessenger: FlutterBinaryMessenger,
    backgroundWakeStore: BackgroundWakeStore,
    backgroundRefreshIdentifier: String,
    onHeadlessExecutionComplete: ((Bool, Int, String?) -> Void)? = nil
) {
    let backgroundRuntimeChannel = FlutterMethodChannel(
        name: "avra/background_runtime",
        binaryMessenger: binaryMessenger
    )
    backgroundRuntimeChannel.setMethodCallHandler { call, result in
        switch call.method {
        case "consumePendingWakeInvocations":
            result(backgroundWakeStore.drainInvocations())
        case "consumePendingWakeReasons":
            result(backgroundWakeStore.drain())
        case "notifyForegroundReady":
            result(true)
        case "scheduleBackgroundTaskWindow":
            if let arguments = call.arguments as? [String: Any],
               let intervalSeconds = arguments["intervalSeconds"] as? NSNumber {
                backgroundWakeStore.scheduleBackgroundRefresh(
                    taskIdentifier: backgroundRefreshIdentifier,
                    earliestInSeconds: intervalSeconds.doubleValue
                )
                result(true)
            } else {
                result(false)
            }
        case "cancelBackgroundTaskWindow":
            backgroundWakeStore.cancelBackgroundRefresh(taskIdentifier: backgroundRefreshIdentifier)
            result(true)
        case "notifyHeadlessExecutionComplete":
            let arguments = call.arguments as? [String: Any]
            let success = arguments?["success"] as? Bool ?? false
            let handledInvocationCount = arguments?["handledInvocationCount"] as? NSNumber
            let failureSummary = arguments?["failureSummary"] as? String
            onHeadlessExecutionComplete?(success, handledInvocationCount?.intValue ?? 0, failureSummary)
            result(true)
        case "getPlatformWakeCapabilities":
            result([
                "platform": "ios",
                "supports_boot_restore": false,
                "supports_background_task_window": true,
                "supports_connectivity_wifi": false,
                "supports_ble_encounter": true,
                "supports_significant_location": true,
                "supports_headless_execution": true,
            ])
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

final class BackgroundRuntimeEngineHost {
    static let shared = BackgroundRuntimeEngineHost()

    private let entrypoint = "runAvraiBackgroundWake"
    private var engine: FlutterEngine?
    private var completionHandlers: [(Bool) -> Void] = []
    private var timeoutWorkItem: DispatchWorkItem?

    func executeNow(
        backgroundWakeStore: BackgroundWakeStore,
        backgroundRefreshIdentifier: String,
        completion: ((Bool) -> Void)? = nil
    ) {
        if let completion {
            completionHandlers.append(completion)
        }
        guard engine == nil else {
            return
        }
        guard backgroundWakeStore.hasPendingInvocations() else {
            finish(success: true)
            return
        }

        let engine = FlutterEngine(
            name: "avrai.background.runtime",
            project: nil,
            allowHeadlessExecution: true
        )
        self.engine = engine
        GeneratedPluginRegistrant.register(with: engine)
        configureBackgroundRuntimeChannel(
            binaryMessenger: engine.binaryMessenger,
            backgroundWakeStore: backgroundWakeStore,
            backgroundRefreshIdentifier: backgroundRefreshIdentifier
        ) { [weak self] success, _, _ in
            self?.finish(success: success)
        }
        _ = engine.run(withEntrypoint: entrypoint)

        let timeoutWorkItem = DispatchWorkItem { [weak self] in
            self?.finish(success: false)
        }
        self.timeoutWorkItem = timeoutWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 25, execute: timeoutWorkItem)
    }

    func cancelCurrentExecution() {
        finish(success: false)
    }

    private func finish(success: Bool) {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil

        let completions = completionHandlers
        completionHandlers.removeAll()

        engine?.destroyContext()
        engine = nil

        completions.forEach { $0(success) }
    }
}
