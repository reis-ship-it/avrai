package com.avrai.app

import android.app.ActivityManager
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.Context
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.wifi.p2p.WifiP2pManager
import android.os.Build
import android.os.PowerManager
import android.os.StatFs
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import com.avrai.app.services.BleInboxStore
import com.avrai.app.services.BLEForegroundService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
  private var localLlmEventSink: EventChannel.EventSink? = null
  private var localLlmModelDir: String? = null
  private var engine: Any? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    BleInboxStore.init(applicationContext)

    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      CHANNEL_BLE_INBOX,
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "pollMessages" -> {
          val maxMessages = call.argument<Number>("maxMessages")?.toInt() ?: 50
          val drained = BleInboxStore.drain(maxMessages)
          val mapped = drained.map { msg ->
            mapOf(
              "senderId" to msg.senderId,
              "data" to msg.data,
              "receivedAtMs" to msg.receivedAtMs,
            )
          }
          result.success(mapped)
        }
        "clearMessages" -> {
          BleInboxStore.clear()
          result.success(true)
        }
        else -> result.notImplemented()
      }
    }

    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      CHANNEL_BLE_PERIPHERAL,
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "startPeripheral" -> {
          val payload = call.argument<ByteArray>("payload")
          if (payload == null) {
            result.success(false)
          } else {
            val ok = startBlePeripheral(payload)
            result.success(ok)
          }
        }
        "stopPeripheral" -> {
          val ok = stopBlePeripheral()
          result.success(ok)
        }
        "updatePayload" -> {
          val payload = call.argument<ByteArray>("payload")
          if (payload == null) {
            result.success(false)
          } else {
            val ok = updateBlePeripheralPayload(payload)
            result.success(ok)
          }
        }
        "updatePreKeyPayload" -> {
          val payload = call.argument<ByteArray>("payload")
          if (payload == null) {
            result.success(false)
          } else {
            val ok = updateBlePreKeyPayload(payload)
            result.success(ok)
          }
        }
        "updateServiceDataFrameV1" -> {
          val frame = call.argument<ByteArray>("frame")
          if (frame == null) {
            result.success(false)
          } else {
            val ok = updateBleServiceDataFrameV1(frame)
            result.success(ok)
          }
        }
        else -> result.notImplemented()
      }
    }

    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      CHANNEL_BLE_FOREGROUND,
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "startService" -> {
          val ok = startBleForegroundService()
          result.success(ok)
        }
        "stopService" -> {
          val ok = stopBleForegroundService()
          result.success(ok)
        }
        "updateScanInterval" -> {
          val intervalMs = call.argument<Number>("intervalMs")?.toLong()
          if (intervalMs == null || intervalMs < 0L) {
            result.success(false)
          } else {
            val ok = updateScanInterval(intervalMs)
            result.success(ok)
          }
        }
        else -> result.notImplemented()
      }
    }

    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      CHANNEL_WIFI_DIRECT,
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "scanPeers" -> {
          scanWifiDirectPeers(result)
        }
        "isSupported" -> result.success(isWifiP2pSupported())
        else -> result.notImplemented()
      }
    }

    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      CHANNEL_DEVICE_CAPABILITIES,
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "getCapabilities" -> {
          try {
            val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val mi = ActivityManager.MemoryInfo()
            am.getMemoryInfo(mi)
            val totalRamMb = (mi.totalMem / (1024L * 1024L)).toInt()

            val stat = StatFs(filesDir.absolutePath)
            val freeDiskMb = (stat.availableBytes / (1024L * 1024L)).toInt()
            val totalDiskMb = (stat.totalBytes / (1024L * 1024L)).toInt()

            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            val isLowPowerMode = pm.isPowerSaveMode

            val payload = mapOf(
              "platform" to "android",
              "deviceModel" to (Build.MODEL ?: ""),
              "osVersion" to Build.VERSION.SDK_INT,
              "totalRamMb" to totalRamMb,
              "freeDiskMb" to freeDiskMb,
              "totalDiskMb" to totalDiskMb,
              "cpuCores" to Runtime.getRuntime().availableProcessors(),
              "isLowPowerMode" to isLowPowerMode,
            )
            result.success(payload)
          } catch (e: Exception) {
            result.error("capabilities_error", e.toString(), null)
          }
        }
        else -> result.notImplemented()
      }
    }

    EventChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      CHANNEL_LOCAL_LLM_STREAM,
    ).setStreamHandler(object : EventChannel.StreamHandler {
      override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        localLlmEventSink = events
      }

      override fun onCancel(arguments: Any?) {
        localLlmEventSink = null
      }
    })

    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      CHANNEL_LOCAL_LLM,
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "loadModel" -> {
          val modelDir = call.argument<String>("model_dir") ?: ""
          if (modelDir.isEmpty()) {
            localLlmModelDir = null
            result.success(false)
          } else {
            val clazz = try {
              Class.forName("ai.mlc.mlcllm.MLCEngine")
            } catch (_: ClassNotFoundException) {
              null
            }
            if (clazz == null) {
              localLlmModelDir = null
              result.error("mlc_runtime_missing", "MLC-LLM Android runtime is not available in this build", null)
            } else {
              try {
                engine = clazz.getConstructor(String::class.java).newInstance(modelDir)
                localLlmModelDir = modelDir
                result.success(true)
              } catch (e: Exception) {
                localLlmModelDir = null
                engine = null
                result.error("mlc_runtime_error", "Failed to initialize MLCEngine", e.toString())
              }
            }
          }
        }
        "generate" -> {
          val modelDir = call.argument<String>("model_dir") ?: ""
          if (modelDir.isEmpty()) {
            result.error("no_model", "Missing model_dir", null)
          } else if (localLlmModelDir == null || localLlmModelDir != modelDir) {
            result.error("not_ready", "Local LLM not loaded", null)
          } else {
            try {
              // Get the underlying MLCEngine object
              val mlcEngine = engine
              if (mlcEngine == null) {
                 result.error("not_ready", "Engine is null", null)
                 return@setMethodCallHandler
              }

              // Use Kotlin reflection to invoke the chat method based on current mlc4j library format
              val messages = call.argument<List<Map<String, String>>>("messages") ?: emptyList()
              val responseFormat = call.argument<String>("response_format")
              
              // This is a stub that allows the app to compile while passing the correct types
              // We are using reflection here to avoid compile-time dependency errors if mlc4j updates
              val chatMethod = mlcEngine.javaClass.getMethod("chat", String::class.java)
              
              // For a simple single prompt implementation (we concatenate the messages for now)
              val prompt = messages.joinToString("\n") { "${it["role"]}: ${it["content"]}" }
              val rawOutput = chatMethod.invoke(mlcEngine, prompt) as String
              
              result.success(rawOutput)
            } catch (e: Exception) {
              result.error("generate_error", "Failed to generate text: ${e.message}", e.toString())
            }
          }
        }
        "startStream" -> {
          val modelDir = call.argument<String>("model_dir") ?: ""
          if (modelDir.isEmpty()) {
            localLlmEventSink?.success(mapOf("type" to "error", "message" to "Missing model_dir"))
            localLlmEventSink?.success(mapOf("type" to "done"))
            result.success(false)
          } else if (localLlmModelDir == null || localLlmModelDir != modelDir) {
            localLlmEventSink?.success(mapOf("type" to "error", "message" to "Local LLM not loaded"))
            localLlmEventSink?.success(mapOf("type" to "done"))
            result.success(true)
          } else {
            val sink = localLlmEventSink
            if (sink == null) {
              result.success(false)
              return@setMethodCallHandler
            }
            runOnUiThread {
              sink.success(mapOf("type" to "error", "message" to "Local LLM not yet active on Android"))
              sink.success(mapOf("type" to "done"))
            }
            result.success(true)
          }
        }
        else -> result.notImplemented()
      }
    }

    // App Usage Stats for AI Learning (Cross-App Tracking)
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      CHANNEL_APP_USAGE,
    ).setMethodCallHandler(AppUsagePlugin(applicationContext))
  }

  private fun startBleForegroundService(): Boolean {
    return try {
      val intent = Intent(this, BLEForegroundService::class.java).apply {
        action = BLEForegroundService.ACTION_START
      }
      ContextCompat.startForegroundService(this, intent)
      true
    } catch (e: Exception) {
      false
    }
  }

  private fun stopBleForegroundService(): Boolean {
    return try {
      val intent = Intent(this, BLEForegroundService::class.java).apply {
        action = BLEForegroundService.ACTION_STOP
      }
      startService(intent)
      stopService(Intent(this, BLEForegroundService::class.java))
      true
    } catch (e: Exception) {
      false
    }
  }

  private fun updateScanInterval(intervalMs: Long): Boolean {
    return try {
      val intent = Intent(this, BLEForegroundService::class.java).apply {
        action = BLEForegroundService.ACTION_UPDATE_SCAN_INTERVAL
        putExtra(BLEForegroundService.EXTRA_SCAN_INTERVAL_MS, intervalMs)
      }
      startService(intent)
      true
    } catch (e: Exception) {
      false
    }
  }

  private fun startBlePeripheral(payload: ByteArray): Boolean {
    return try {
      val intent = Intent(this, BLEForegroundService::class.java).apply {
        action = BLEForegroundService.ACTION_START_PERIPHERAL
        putExtra(BLEForegroundService.EXTRA_PERIPHERAL_PAYLOAD_BYTES, payload)
      }
      ContextCompat.startForegroundService(this, intent)
      true
    } catch (e: Exception) {
      false
    }
  }

  private fun stopBlePeripheral(): Boolean {
    return try {
      val intent = Intent(this, BLEForegroundService::class.java).apply {
        action = BLEForegroundService.ACTION_STOP_PERIPHERAL
      }
      startService(intent)
      true
    } catch (e: Exception) {
      false
    }
  }

  private fun updateBlePeripheralPayload(payload: ByteArray): Boolean {
    return try {
      val intent = Intent(this, BLEForegroundService::class.java).apply {
        action = BLEForegroundService.ACTION_SET_VIBE_PAYLOAD
        putExtra(BLEForegroundService.EXTRA_PERIPHERAL_PAYLOAD_BYTES, payload)
      }
      startService(intent)
      true
    } catch (e: Exception) {
      false
    }
  }

  private fun updateBlePreKeyPayload(payload: ByteArray): Boolean {
    return try {
      val intent = Intent(this, BLEForegroundService::class.java).apply {
        action = BLEForegroundService.ACTION_SET_PREKEY_PAYLOAD
        putExtra(BLEForegroundService.EXTRA_PREKEY_PAYLOAD_BYTES, payload)
      }
      startService(intent)
      true
    } catch (e: Exception) {
      false
    }
  }

  private fun updateBleServiceDataFrameV1(frame: ByteArray): Boolean {
    return try {
      val intent = Intent(this, BLEForegroundService::class.java).apply {
        action = BLEForegroundService.ACTION_SET_SERVICE_DATA_FRAME_V1
        putExtra(BLEForegroundService.EXTRA_SERVICE_DATA_FRAME_V1_BYTES, frame)
      }
      startService(intent)
      true
    } catch (e: Exception) {
      false
    }
  }

  private fun isWifiP2pSupported(): Boolean {
    return packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI_DIRECT)
  }

  private fun scanWifiDirectPeers(result: MethodChannel.Result) {
    if (!isWifiP2pSupported()) {
      result.success(
        mapOf(
          "status" to "unsupported",
          "reason" to "WiFi Direct is not available on this device",
          "peers" to emptyList<Any>(),
          "fallback_transport" to "bluetooth",
        ),
      )
      return
    }

    val manager = getSystemService(Context.WIFI_P2P_SERVICE) as? WifiP2pManager
    if (manager == null) {
      result.success(
        mapOf(
          "status" to "unsupported",
          "reason" to "WiFi P2P system service unavailable",
          "peers" to emptyList<Any>(),
          "fallback_transport" to "bluetooth",
        ),
      )
      return
    }

    val p2pChannel = manager.initialize(this, mainLooper, null)
    val peers = mutableListOf<Map<String, Any?>>()
    val timeoutHandler = Handler(Looper.getMainLooper())
    var completed = false
    var receiverRegistered = false

    lateinit var peerReceiver: BroadcastReceiver

    fun finalizeScan(
      status: String,
      reason: String?,
      discoveredPeers: List<Map<String, Any?>> = peers,
    ) {
      if (completed) return
      completed = true

      timeoutHandler.removeCallbacksAndMessages(null)

      if (receiverRegistered) {
        try {
          unregisterReceiver(peerReceiver)
          receiverRegistered = false
        } catch (_: Exception) {}
      }

      try {
        manager.stopPeerDiscovery(
          p2pChannel,
          object : WifiP2pManager.ActionListener {
            override fun onSuccess() {}
            override fun onFailure(reason: Int) {}
          },
        )
      } catch (_: Exception) {}

      val payload = hashMapOf<String, Any>(
        "status" to status,
        "peers" to discoveredPeers,
        "fallback_transport" to "bluetooth",
      )
      if (reason != null) {
        payload["reason"] = reason
      }

      result.success(payload)
    }

    peerReceiver = object : BroadcastReceiver() {
      override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action != WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION) return

        manager.requestPeers(
          p2pChannel,
          WifiP2pManager.PeerListListener { peerList ->
            peers.clear()

            peerList?.deviceList?.forEach { peer ->
              val deviceId = peer.deviceAddress
              if (deviceId.isNullOrBlank()) return@forEach

              peers.add(
                mapOf(
                  "device_id" to deviceId,
                  "device_name" to (peer.deviceName ?: "WiFi Direct Device"),
                  "device_type" to "wifi_direct",
                  "spots_enabled" to true,
                ),
              )
            }

            finalizeScan(
              if (peers.isNotEmpty()) "ok" else "empty",
              if (peers.isNotEmpty()) null else "No SPOTS-capable WiFi Direct peers discovered",
            )
          },
        )
      }
    }

    registerReceiver(
      peerReceiver,
      IntentFilter(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION),
    )
    receiverRegistered = true

    timeoutHandler.postDelayed(
      {
        finalizeScan("timeout", "WiFi Direct peer discovery timed out")
      },
      3500L,
    )

    manager.discoverPeers(
      p2pChannel,
      object : WifiP2pManager.ActionListener {
        override fun onSuccess() {
          // Wait for peers changed broadcast; fallback timer will finalize if none found.
        }

        override fun onFailure(reason: Int) {
          finalizeScan("error", "WiFi P2P discovery failed (code=$reason)")
        }
      },
    )
  }

  companion object {
    private const val CHANNEL_BLE_FOREGROUND = "avra/ble_foreground"
    private const val CHANNEL_BLE_PERIPHERAL = "avra/ble_peripheral"
    private const val CHANNEL_BLE_INBOX = "avra/ble_inbox"
    private const val CHANNEL_WIFI_DIRECT = "avra/wifi_direct"
    private const val CHANNEL_DEVICE_CAPABILITIES = "avra/device_capabilities"
    private const val CHANNEL_LOCAL_LLM = "avrai/mlc_llm"
    private const val CHANNEL_LOCAL_LLM_STREAM = "avrai/mlc_llm_stream"
    private const val CHANNEL_APP_USAGE = "com.avrai.app_usage"
  }
} 