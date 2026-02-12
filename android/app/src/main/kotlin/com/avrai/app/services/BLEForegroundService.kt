package com.avrai.app.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.ParcelUuid
import android.os.PowerManager
import android.util.Log
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import androidx.core.app.NotificationCompat
import com.avrai.app.R
import java.util.UUID

/**
 * Android foreground service used to keep the app process alive for background BLE work.
 *
 * NOTE:
 * - Android requires a persistent notification for foreground services.
 * - The actual BLE scan/advertise + GATT handshake logic will be layered on top of this runtime.
 */
class BLEForegroundService : Service() {
  private var wakeLock: PowerManager.WakeLock? = null

  // BLE peripheral runtime (advertising + GATT server)
  private var bluetoothManager: BluetoothManager? = null
  private var bluetoothAdapter: BluetoothAdapter? = null
  private var advertiser: BluetoothLeAdvertiser? = null
  private var advertiseCallback: AdvertiseCallback? = null
  private var gattServer: BluetoothGattServer? = null
  private var vibePayload: ByteArray = ByteArray(0)
  private var preKeyPayload: ByteArray = ByteArray(0)
  private var serviceDataFrameV1: ByteArray = ByteArray(0)
  private var isConnectable: Boolean = true

  private data class ReadRequest(val streamId: Int, val offset: Int)
  private val readRequests: MutableMap<String, ReadRequest> = HashMap()

  // Receiver-side msgId dedupe (best-effort): senderId:msgId -> expiresAtMs
  private val seenMsgIds: MutableMap<String, Long> = HashMap()

  private data class PartialMessage(
    val senderId: String,
    val msgId: Int,
    val totalLen: Int,
    val buffer: ByteArray,
    var nextOffset: Int,
    var lastUpdatedMs: Long,
  )

  private val partialMessages: MutableMap<String, PartialMessage> = HashMap()

  override fun onBind(intent: Intent?): IBinder? = null

  override fun onCreate() {
    super.onCreate()
    createNotificationChannel()

    bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    bluetoothAdapter = bluetoothManager?.adapter

    BleInboxStore.init(applicationContext)
    BleAckStore.init(applicationContext)
  }

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    when (intent?.action) {
      ACTION_START -> startForegroundRuntime()
      ACTION_STOP -> stopForegroundRuntime()
      ACTION_UPDATE_SCAN_INTERVAL -> {
        // Placeholder for adaptive scanning. Stored for later use by BLE runtime.
        val intervalMs = intent.getLongExtra(EXTRA_SCAN_INTERVAL_MS, -1L)
        Log.i(LOG_TAG, "Update scan interval request: ${intervalMs}ms")
      }
      ACTION_SET_VIBE_PAYLOAD, ACTION_SET_PERIPHERAL_PAYLOAD -> {
        val payload = intent.getByteArrayExtra(EXTRA_PERIPHERAL_PAYLOAD_BYTES)
        if (payload != null) {
          vibePayload = payload
          Log.i(LOG_TAG, "Updated vibe payload: ${payload.size} bytes")
        }
      }
      ACTION_SET_PREKEY_PAYLOAD -> {
        val payload = intent.getByteArrayExtra(EXTRA_PREKEY_PAYLOAD_BYTES)
        if (payload != null) {
          preKeyPayload = payload
          Log.i(LOG_TAG, "Updated prekey payload: ${payload.size} bytes")
        }
      }
      ACTION_SET_SERVICE_DATA_FRAME_V1 -> {
        val frame = intent.getByteArrayExtra(EXTRA_SERVICE_DATA_FRAME_V1_BYTES)
        if (frame != null) {
          serviceDataFrameV1 = frame
          val connectableOverride = computeConnectableFromFrameV1(frame)
          if (connectableOverride != null) {
            isConnectable = connectableOverride
          }
          Log.i(LOG_TAG, "Updated service data frame v1: ${frame.size} bytes")
          // Restart peripheral advertising so the service data takes effect.
          stopPeripheral()
          startPeripheral()
        }
      }
      ACTION_START_PERIPHERAL -> {
        val payload = intent.getByteArrayExtra(EXTRA_PERIPHERAL_PAYLOAD_BYTES)
        if (payload != null) vibePayload = payload
        startForegroundRuntime()
        startPeripheral()
      }
      ACTION_STOP_PERIPHERAL -> {
        stopPeripheral()
      }
      else -> {
        // If started without an explicit action, still ensure we stay alive.
        startForegroundRuntime()
      }
    }

    // Keep running unless explicitly stopped.
    return START_STICKY
  }

  override fun onDestroy() {
    stopForegroundRuntime()
    super.onDestroy()
  }

  private fun startForegroundRuntime() {
    try {
      acquireWakeLock()
      val notification = buildNotification()
      startForeground(NOTIFICATION_ID, notification)
      Log.i(LOG_TAG, "BLE foreground service started")
    } catch (e: Exception) {
      Log.e(LOG_TAG, "Failed to start BLE foreground service", e)
      // Fail-safe: stop service if we can't run foreground.
      stopSelf()
    }
  }

  private fun stopForegroundRuntime() {
    try {
      stopPeripheral()
      releaseWakeLock()
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        stopForeground(STOP_FOREGROUND_REMOVE)
      } else {
        @Suppress("DEPRECATION")
        stopForeground(true)
      }
      Log.i(LOG_TAG, "BLE foreground service stopped")
    } catch (e: Exception) {
      Log.e(LOG_TAG, "Failed to stop BLE foreground service", e)
    } finally {
      stopSelf()
    }
  }

  private fun startPeripheral() {
    try {
      val adapter = bluetoothAdapter
      if (adapter == null) {
        Log.w(LOG_TAG, "Bluetooth adapter unavailable; cannot start peripheral")
        return
      }
      if (!adapter.isEnabled) {
        Log.w(LOG_TAG, "Bluetooth is disabled; cannot start peripheral")
        return
      }

      // Start GATT server
      if (gattServer == null) {
        val manager = bluetoothManager
        if (manager == null) {
          Log.w(LOG_TAG, "Bluetooth manager unavailable; cannot open GATT server")
          return
        }
        gattServer = manager.openGattServer(this, gattServerCallback)

        val service = BluetoothGattService(
          SPOTS_SERVICE_UUID,
          BluetoothGattService.SERVICE_TYPE_PRIMARY,
        )

        val readChar = BluetoothGattCharacteristic(
          SPOTS_READ_CHARACTERISTIC_UUID,
          BluetoothGattCharacteristic.PROPERTY_READ,
          BluetoothGattCharacteristic.PERMISSION_READ,
        )

        val writeChar = BluetoothGattCharacteristic(
          SPOTS_WRITE_CHARACTERISTIC_UUID,
          BluetoothGattCharacteristic.PROPERTY_WRITE or BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE,
          BluetoothGattCharacteristic.PERMISSION_WRITE,
        )

        service.addCharacteristic(readChar)
        service.addCharacteristic(writeChar)
        gattServer?.addService(service)
      }

      // Start advertising (connectable so centrals can read the GATT characteristic)
      if (advertiser == null) {
        advertiser = adapter.bluetoothLeAdvertiser
      }
      val adv = advertiser
      if (adv == null) {
        Log.w(LOG_TAG, "BLE advertiser unavailable; cannot advertise")
        return
      }

      if (advertiseCallback == null) {
        advertiseCallback = object : AdvertiseCallback() {
          override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
            Log.i(LOG_TAG, "BLE advertising started")
          }

          override fun onStartFailure(errorCode: Int) {
            Log.e(LOG_TAG, "BLE advertising failed: $errorCode")
          }
        }
      }

      val settings = AdvertiseSettings.Builder()
        .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_POWER)
        .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_LOW)
        .setConnectable(isConnectable)
        .setTimeout(0)
        .build()

      val data = AdvertiseData.Builder()
        .addServiceUuid(ParcelUuid(SPOTS_SERVICE_UUID))
        .apply {
          val frame = serviceDataFrameV1
          if (frame.isNotEmpty()) {
            addServiceData(ParcelUuid(SPOTS_SERVICE_UUID), frame)
          }
        }
        .setIncludeDeviceName(false)
        .build()

      adv.startAdvertising(settings, data, advertiseCallback)
    } catch (e: SecurityException) {
      Log.e(LOG_TAG, "Missing Bluetooth permissions for peripheral mode", e)
    } catch (e: Exception) {
      Log.e(LOG_TAG, "Failed to start BLE peripheral", e)
    }
  }

  private fun stopPeripheral() {
    try {
      val adv = advertiser
      val cb = advertiseCallback
      if (adv != null && cb != null) {
        try {
          adv.stopAdvertising(cb)
        } catch (e: Exception) {
          Log.w(LOG_TAG, "Error stopping BLE advertising", e)
        }
      }
      advertiseCallback = null

      try {
        gattServer?.close()
      } catch (e: Exception) {
        Log.w(LOG_TAG, "Error closing GATT server", e)
      } finally {
        gattServer = null
        readRequests.clear()
      }
    } catch (e: Exception) {
      Log.e(LOG_TAG, "Failed to stop BLE peripheral", e)
    }
  }

  private fun payloadForStream(streamId: Int): ByteArray {
    return when (streamId) {
      STREAM_VIBE -> vibePayload
      STREAM_PREKEY -> preKeyPayload
      STREAM_ACK -> BleAckStore.snapshotPayloadBytes()
      else -> ByteArray(0)
    }
  }

  private fun buildReadFrame(
    streamId: Int,
    offset: Int,
    payload: ByteArray,
  ): ByteArray {
    val totalLen = payload.size
    val safeOffset = offset.coerceAtLeast(0).coerceAtMost(totalLen)
    val remaining = totalLen - safeOffset
    val chunkLen = remaining.coerceAtMost(MAX_CHUNK_DATA)

    // Header (16 bytes):
    // [0..3]  magic "SPTS"
    // [4]     version
    // [5]     streamId
    // [6..9]  totalLen (uint32 LE)
    // [10..13] offset (uint32 LE)
    // [14..15] chunkLen (uint16 LE)
    val frame = ByteArray(READ_HEADER_LEN + chunkLen)
    frame[0] = 'S'.code.toByte()
    frame[1] = 'P'.code.toByte()
    frame[2] = 'T'.code.toByte()
    frame[3] = 'S'.code.toByte()
    frame[4] = PROTOCOL_VERSION.toByte()
    frame[5] = streamId.toByte()

    writeUint32Le(frame, 6, totalLen)
    writeUint32Le(frame, 10, safeOffset)
    writeUint16Le(frame, 14, chunkLen)

    if (chunkLen > 0) {
      System.arraycopy(payload, safeOffset, frame, READ_HEADER_LEN, chunkLen)
    }
    return frame
  }

  private fun writeUint16Le(buf: ByteArray, offset: Int, value: Int) {
    buf[offset] = (value and 0xFF).toByte()
    buf[offset + 1] = ((value shr 8) and 0xFF).toByte()
  }

  private fun writeUint32Le(buf: ByteArray, offset: Int, value: Int) {
    buf[offset] = (value and 0xFF).toByte()
    buf[offset + 1] = ((value shr 8) and 0xFF).toByte()
    buf[offset + 2] = ((value shr 16) and 0xFF).toByte()
    buf[offset + 3] = ((value shr 24) and 0xFF).toByte()
  }

  private fun readUint16Le(buf: ByteArray, offset: Int): Int {
    return (buf[offset].toInt() and 0xFF) or ((buf[offset + 1].toInt() and 0xFF) shl 8)
  }

  private fun readUint32Le(buf: ByteArray, offset: Int): Int {
    return (buf[offset].toInt() and 0xFF) or
      ((buf[offset + 1].toInt() and 0xFF) shl 8) or
      ((buf[offset + 2].toInt() and 0xFF) shl 16) or
      ((buf[offset + 3].toInt() and 0xFF) shl 24)
  }

  private fun parseControlFrame(value: ByteArray): ReadRequest? {
    // Control frame (10 bytes):
    // [0..3] magic "SPTS"
    // [4] version
    // [5] streamId
    // [6..9] offset (uint32 LE)
    if (value.size < CONTROL_FRAME_LEN) return null
    if (value[0] != 'S'.code.toByte() ||
      value[1] != 'P'.code.toByte() ||
      value[2] != 'T'.code.toByte() ||
      value[3] != 'S'.code.toByte()
    ) return null
    if (value[4].toInt() != PROTOCOL_VERSION) return null
    val streamId = value[5].toInt() and 0xFF
    val offset = (value[6].toInt() and 0xFF) or
      ((value[7].toInt() and 0xFF) shl 8) or
      ((value[8].toInt() and 0xFF) shl 16) or
      ((value[9].toInt() and 0xFF) shl 24)
    return ReadRequest(streamId = streamId, offset = offset)
  }

  private fun computeConnectableFromFrameV1(frame: ByteArray): Boolean? {
    // Frame v1 (24 bytes): magic "SPTS" + ver + flags + epoch + ...
    if (frame.size < 6) return null
    if (frame[0] != 'S'.code.toByte() ||
      frame[1] != 'P'.code.toByte() ||
      frame[2] != 'T'.code.toByte() ||
      frame[3] != 'S'.code.toByte()
    ) return null
    val ver = frame[4].toInt() and 0xFF
    if (ver != 1) return null
    val flags = frame[5].toInt() and 0xFF
    val eventModeEnabled = (flags and 0x01) != 0
    val connectOk = (flags and 0x02) != 0
    // In Event Mode, advertise non-connectable by default unless connectOk=true.
    // Outside Event Mode, remain connectable for existing flows.
    return if (eventModeEnabled) connectOk else true
  }

  private data class MessageFrame(
    val senderId: String,
    val msgId: Int,
    val totalLen: Int,
    val offset: Int,
    val chunk: ByteArray,
  )

  private fun parseMessageFrame(value: ByteArray): MessageFrame? {
    // Message frame v1 (20 bytes header):
    // [0..3]  magic "SPTM"
    // [4]     version=1
    // [5]     reserved
    // [6..9]  msgId (uint32 LE)
    // [10..13] totalLen (uint32 LE)
    // [14..17] offset (uint32 LE)
    // [18..19] chunkLen (uint16 LE)
    //
    // Message frame v2 (56 bytes header):
    // v1 header + senderId(36 bytes ASCII, padded)
    if (value.size < MESSAGE_HEADER_LEN_V1) return null
    if (value[0] != 'S'.code.toByte() ||
      value[1] != 'P'.code.toByte() ||
      value[2] != 'T'.code.toByte() ||
      value[3] != 'M'.code.toByte()
    ) return null
    val version = value[4].toInt()
    if (version != MESSAGE_VERSION_V1 && version != MESSAGE_VERSION_V2) return null

    val msgId = readUint32Le(value, 6)
    val totalLen = readUint32Le(value, 10)
    val offset = readUint32Le(value, 14)
    val chunkLen = readUint16Le(value, 18)

    if (totalLen <= 0) return null
    if (chunkLen < 0) return null
    val headerLen = if (version == MESSAGE_VERSION_V2) MESSAGE_HEADER_LEN_V2 else MESSAGE_HEADER_LEN_V1
    if (value.size < headerLen + chunkLen) return null

    val senderId = if (version == MESSAGE_VERSION_V2 && value.size >= MESSAGE_HEADER_LEN_V2) {
      try {
        val raw = value.copyOfRange(MESSAGE_HEADER_LEN_V1, MESSAGE_HEADER_LEN_V2)
        String(raw, Charsets.US_ASCII).trim()
      } catch (_: Exception) {
        ""
      }
    } else {
      ""
    }

    val chunk = value.copyOfRange(headerLen, headerLen + chunkLen)
    return MessageFrame(senderId = senderId, msgId = msgId, totalLen = totalLen, offset = offset, chunk = chunk)
  }

  private fun partialKey(senderId: String, msgId: Int): String {
    return "$senderId:$msgId"
  }

  private fun cleanupSeenMsgIds(nowMs: Long) {
    val it = seenMsgIds.entries.iterator()
    while (it.hasNext()) {
      val entry = it.next()
      if (entry.value <= nowMs) {
        it.remove()
      }
    }
  }

  private fun isDuplicateAndMarkSeen(senderId: String, msgId: Int, nowMs: Long): Boolean {
    cleanupSeenMsgIds(nowMs)
    val key = "$senderId:$msgId"
    val existingExpiry = seenMsgIds[key] ?: 0L
    val isDup = existingExpiry > nowMs
    seenMsgIds[key] = nowMs + 10 * 60 * 1000L
    return isDup
  }

  private fun cleanupPartialMessages(nowMs: Long) {
    val it = partialMessages.entries.iterator()
    while (it.hasNext()) {
      val entry = it.next()
      val ageMs = nowMs - entry.value.lastUpdatedMs
      if (ageMs > 60_000L) {
        it.remove()
      }
    }
  }

  private val gattServerCallback = object : BluetoothGattServerCallback() {
    override fun onConnectionStateChange(device: android.bluetooth.BluetoothDevice, status: Int, newState: Int) {
      val state = when (newState) {
        BluetoothProfile.STATE_CONNECTED -> "connected"
        BluetoothProfile.STATE_DISCONNECTED -> "disconnected"
        else -> "state=$newState"
      }
      Log.i(LOG_TAG, "GATT client ${device.address} $state (status=$status)")
    }

    override fun onCharacteristicReadRequest(
      device: android.bluetooth.BluetoothDevice,
      requestId: Int,
      offset: Int,
      characteristic: BluetoothGattCharacteristic,
    ) {
      if (characteristic.uuid != SPOTS_READ_CHARACTERISTIC_UUID) {
        gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, offset, null)
        return
      }

      val addr = device.address ?: ""
      val request = readRequests[addr] ?: ReadRequest(streamId = STREAM_VIBE, offset = offset)
      val payload = payloadForStream(request.streamId)
      val value = buildReadFrame(request.streamId, request.offset, payload)
      gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, value)
    }

    override fun onCharacteristicWriteRequest(
      device: android.bluetooth.BluetoothDevice,
      requestId: Int,
      characteristic: BluetoothGattCharacteristic,
      preparedWrite: Boolean,
      responseNeeded: Boolean,
      offset: Int,
      value: ByteArray,
    ) {
      if (characteristic.uuid == SPOTS_WRITE_CHARACTERISTIC_UUID) {
        val addr = device.address ?: ""
        val parsed = parseControlFrame(value)
        if (parsed != null) {
          readRequests[addr] = parsed
          Log.i(LOG_TAG, "Control frame set for $addr: stream=${parsed.streamId} offset=${parsed.offset}")
        } else {
          val msgFrame = parseMessageFrame(value)
          if (msgFrame != null) {
            cleanupPartialMessages(System.currentTimeMillis())
            val senderId = if (msgFrame.senderId.isNotBlank()) msgFrame.senderId else addr
            val key = partialKey(senderId, msgFrame.msgId)
            val existing = partialMessages[key]
            val partial = if (existing == null || existing.totalLen != msgFrame.totalLen) {
              PartialMessage(
                senderId = senderId,
                msgId = msgFrame.msgId,
                totalLen = msgFrame.totalLen,
                buffer = ByteArray(msgFrame.totalLen),
                nextOffset = 0,
                lastUpdatedMs = System.currentTimeMillis(),
              )
            } else {
              existing
            }

            if (msgFrame.offset == partial.nextOffset) {
              val end = (msgFrame.offset + msgFrame.chunk.size).coerceAtMost(partial.totalLen)
              val toCopy = end - msgFrame.offset
              if (toCopy > 0) {
                System.arraycopy(msgFrame.chunk, 0, partial.buffer, msgFrame.offset, toCopy)
                partial.nextOffset = end
                partial.lastUpdatedMs = System.currentTimeMillis()
              }
            }

            if (partial.nextOffset >= partial.totalLen) {
              // ACK is emitted even if duplicate (so sender can confirm).
              BleAckStore.addAck(senderId = senderId, msgId = partial.msgId)

              val isDup = isDuplicateAndMarkSeen(senderId, partial.msgId, System.currentTimeMillis())
              if (!isDup) {
                BleInboxStore.add(senderId = senderId, data = partial.buffer)
              }
              partialMessages.remove(key)
              Log.i(LOG_TAG, "Received full BLE message from $senderId msgId=${partial.msgId} (len=${partial.totalLen}) dup=$isDup")
            } else {
              partialMessages[key] = partial
            }
          } else {
            Log.i(LOG_TAG, "Received peripheral write (${value.size} bytes) from ${device.address}")
          }
        }
      }

      if (responseNeeded) {
        gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, null)
      }
    }
  }

  private fun buildNotification(): Notification {
    return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
      .setContentTitle("SPOTS is running")
      .setContentText("Background AI2AI discovery is active")
      .setSmallIcon(R.mipmap.ic_launcher)
      .setOngoing(true)
      .setSilent(true)
      .setPriority(NotificationCompat.PRIORITY_MIN)
      .build()
  }

  private fun createNotificationChannel() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
    val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    val channel = NotificationChannel(
      NOTIFICATION_CHANNEL_ID,
      "SPOTS background AI2AI",
      NotificationManager.IMPORTANCE_MIN,
    )
    channel.description = "Keeps background AI2AI discovery running"
    channel.setShowBadge(false)
    manager.createNotificationChannel(channel)
  }

  private fun acquireWakeLock() {
    if (wakeLock?.isHeld == true) return
    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
    wakeLock = pm.newWakeLock(
      PowerManager.PARTIAL_WAKE_LOCK,
      "SPOTS:BLEForegroundService",
    ).apply {
      setReferenceCounted(false)
      acquire()
    }
  }

  private fun releaseWakeLock() {
    try {
      if (wakeLock?.isHeld == true) {
        wakeLock?.release()
      }
    } catch (e: Exception) {
      Log.w(LOG_TAG, "Error releasing wake lock", e)
    } finally {
      wakeLock = null
    }
  }

  companion object {
    private const val LOG_TAG = "BLEForegroundService"

    private const val NOTIFICATION_CHANNEL_ID = "spots_ble_foreground"
    private const val NOTIFICATION_ID = 4242

    private val SPOTS_SERVICE_UUID: UUID =
      UUID.fromString("0000ff00-0000-1000-8000-00805f9b34fb")
    private val SPOTS_READ_CHARACTERISTIC_UUID: UUID =
      UUID.fromString("0000ff01-0000-1000-8000-00805f9b34fb")
    private val SPOTS_WRITE_CHARACTERISTIC_UUID: UUID =
      UUID.fromString("0000ff02-0000-1000-8000-00805f9b34fb")

    private const val PROTOCOL_VERSION = 1
    private const val STREAM_VIBE = 0
    private const val STREAM_PREKEY = 1
    private const val STREAM_ACK = 2
    private const val READ_HEADER_LEN = 16
    private const val CONTROL_FRAME_LEN = 10
    private const val MAX_CHUNK_DATA = 180

    private const val MESSAGE_VERSION_V1 = 1
    private const val MESSAGE_VERSION_V2 = 2
    private const val MESSAGE_HEADER_LEN_V1 = 20
    private const val MESSAGE_HEADER_LEN_V2 = 56

    const val ACTION_START = "com.avra.app.services.action.START"
    const val ACTION_STOP = "com.avra.app.services.action.STOP"
    const val ACTION_UPDATE_SCAN_INTERVAL = "com.avra.app.services.action.UPDATE_SCAN_INTERVAL"
    const val ACTION_START_PERIPHERAL = "com.avra.app.services.action.START_PERIPHERAL"
    const val ACTION_STOP_PERIPHERAL = "com.avra.app.services.action.STOP_PERIPHERAL"
    const val ACTION_SET_PERIPHERAL_PAYLOAD = "com.avra.app.services.action.SET_PERIPHERAL_PAYLOAD" // legacy alias
    const val ACTION_SET_VIBE_PAYLOAD = "com.avra.app.services.action.SET_VIBE_PAYLOAD"
    const val ACTION_SET_PREKEY_PAYLOAD = "com.avra.app.services.action.SET_PREKEY_PAYLOAD"
    const val ACTION_SET_SERVICE_DATA_FRAME_V1 =
      "com.avra.app.services.action.SET_SERVICE_DATA_FRAME_V1"

    const val EXTRA_SCAN_INTERVAL_MS = "scanIntervalMs"
    const val EXTRA_PERIPHERAL_PAYLOAD_BYTES = "peripheralPayloadBytes"
    const val EXTRA_PREKEY_PAYLOAD_BYTES = "preKeyPayloadBytes"
    const val EXTRA_SERVICE_DATA_FRAME_V1_BYTES = "serviceDataFrameV1Bytes"
  }
}

