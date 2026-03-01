package com.avrai.app.services

import android.content.Context
import android.content.SharedPreferences
import android.util.Base64
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.ConcurrentLinkedQueue

/**
 * Simple in-memory inbox for BLE-delivered AI2AI packets.
 *
 * This store is intentionally process-local and best-effort:
 * - It enables "silent" background handshakes while the app process is alive.
 * - Messages are drained by Dart via a MethodChannel.
 */
object BleInboxStore {
  private const val PREFS_NAME = "spots_ble_inbox"
  private const val PREFS_KEY_QUEUE = "queue_v1"
  private const val MAX_PERSISTED_MESSAGES = 25

  private var prefs: SharedPreferences? = null

  data class InboxMessage(
    val senderId: String,
    val data: ByteArray,
    val receivedAtMs: Long,
  )

  private val queue: ConcurrentLinkedQueue<InboxMessage> = ConcurrentLinkedQueue()

  fun init(context: Context) {
    if (prefs != null) return
    prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    loadFromDisk()
  }

  fun add(senderId: String, data: ByteArray) {
    queue.add(InboxMessage(senderId = senderId, data = data, receivedAtMs = System.currentTimeMillis()))
    persistToDisk()
  }

  fun drain(maxMessages: Int = 50): List<InboxMessage> {
    val out = ArrayList<InboxMessage>()
    var count = 0
    while (count < maxMessages) {
      val msg = queue.poll() ?: break
      out.add(msg)
      count++
    }
    if (out.isNotEmpty()) {
      persistToDisk()
    }
    return out
  }

  fun clear() {
    queue.clear()
    persistToDisk()
  }

  private fun loadFromDisk() {
    val p = prefs ?: return
    try {
      val raw = p.getString(PREFS_KEY_QUEUE, null) ?: return
      val arr = JSONArray(raw)
      for (i in 0 until arr.length()) {
        val obj = arr.getJSONObject(i)
        val senderId = obj.optString("senderId", "")
        val receivedAtMs = obj.optLong("receivedAtMs", 0L)
        val dataB64 = obj.optString("dataB64", "")
        if (senderId.isBlank() || dataB64.isBlank()) continue
        val bytes = Base64.decode(dataB64, Base64.NO_WRAP)
        queue.add(InboxMessage(senderId = senderId, data = bytes, receivedAtMs = receivedAtMs))
      }
    } catch (_: Exception) {
      // Best-effort: ignore corrupted state.
    }
  }

  private fun persistToDisk() {
    val p = prefs ?: return
    try {
      // Snapshot (cap to last N messages)
      val snapshot = ArrayList<InboxMessage>()
      for (msg in queue) {
        snapshot.add(msg)
      }
      val start = (snapshot.size - MAX_PERSISTED_MESSAGES).coerceAtLeast(0)
      val capped = snapshot.subList(start, snapshot.size)

      val arr = JSONArray()
      for (msg in capped) {
        val obj = JSONObject()
        obj.put("senderId", msg.senderId)
        obj.put("receivedAtMs", msg.receivedAtMs)
        obj.put("dataB64", Base64.encodeToString(msg.data, Base64.NO_WRAP))
        arr.put(obj)
      }
      p.edit().putString(PREFS_KEY_QUEUE, arr.toString()).apply()
    } catch (_: Exception) {
      // Best-effort: ignore persistence failures.
    }
  }
}

