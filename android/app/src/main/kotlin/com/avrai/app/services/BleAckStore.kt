package com.avrai.app.services

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/**
 * Best-effort ACK store for BLE-delivered AI2AI packets.
 *
 * This is used by the sender (acting as a BLE central) to confirm delivery by
 * reading a dedicated GATT stream (streamId=2) from the receiver (peripheral).
 *
 * Notes:
 * - This is NOT security-sensitive data; packets are already encrypted end-to-end.
 * - We persist a small ring buffer so ACKs can survive process restarts.
 */
object BleAckStore {
  private const val PREFS_NAME = "spots_ble_ack"
  private const val PREFS_KEY_ACKS = "acks_v1"
  private const val MAX_PERSISTED_ACKS = 50

  private var prefs: SharedPreferences? = null
  private val acks: ArrayDeque<Ack> = ArrayDeque()

  data class Ack(
    val senderId: String,
    val msgId: Int,
    val ackedAtMs: Long,
  )

  fun init(context: Context) {
    if (prefs != null) return
    prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    loadFromDisk()
  }

  fun addAck(senderId: String, msgId: Int) {
    val now = System.currentTimeMillis()
    acks.addLast(Ack(senderId = senderId, msgId = msgId, ackedAtMs = now))
    while (acks.size > MAX_PERSISTED_ACKS) {
      acks.removeFirst()
    }
    persistToDisk()
  }

  fun snapshotPayloadBytes(): ByteArray {
    // Small JSON payload for cross-platform parsing.
    // {
    //   "v": 1,
    //   "acks": [{ "sender_id": "...", "msg_id": 123, "acked_at_ms": 1700000000000 }, ...]
    // }
    val root = JSONObject()
    root.put("v", 1)
    val arr = JSONArray()
    for (ack in acks) {
      val obj = JSONObject()
      obj.put("sender_id", ack.senderId)
      obj.put("msg_id", ack.msgId)
      obj.put("acked_at_ms", ack.ackedAtMs)
      arr.put(obj)
    }
    root.put("acks", arr)
    return root.toString().toByteArray(Charsets.UTF_8)
  }

  private fun loadFromDisk() {
    val p = prefs ?: return
    try {
      val raw = p.getString(PREFS_KEY_ACKS, null) ?: return
      val arr = JSONArray(raw)
      for (i in 0 until arr.length()) {
        val obj = arr.getJSONObject(i)
        val senderId = obj.optString("sender_id", "")
        val msgId = obj.optInt("msg_id", -1)
        val ackedAtMs = obj.optLong("acked_at_ms", 0L)
        if (senderId.isBlank() || msgId < 0) continue
        acks.addLast(Ack(senderId = senderId, msgId = msgId, ackedAtMs = ackedAtMs))
      }
      while (acks.size > MAX_PERSISTED_ACKS) {
        acks.removeFirst()
      }
    } catch (_: Exception) {
      // Best-effort: ignore corrupted state.
    }
  }

  private fun persistToDisk() {
    val p = prefs ?: return
    try {
      val arr = JSONArray()
      for (ack in acks) {
        val obj = JSONObject()
        obj.put("sender_id", ack.senderId)
        obj.put("msg_id", ack.msgId)
        obj.put("acked_at_ms", ack.ackedAtMs)
        arr.put(obj)
      }
      p.edit().putString(PREFS_KEY_ACKS, arr.toString()).apply()
    } catch (_: Exception) {
      // Best-effort: ignore persistence failures.
    }
  }
}

