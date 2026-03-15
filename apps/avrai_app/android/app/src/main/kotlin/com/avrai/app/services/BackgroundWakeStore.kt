package com.avrai.app.services

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Small persisted queue of native background wake invocation payloads.
 *
 * The Flutter runtime drains this queue on next foreground/headless startup and
 * routes the payloads through the shared background coordinator.
 */
object BackgroundWakeStore {
  private const val PREFS_NAME = "avrai_background_wake_store"
  private const val PREFS_KEY_QUEUE = "pending_wake_invocations_v2"
  private const val MAX_PERSISTED_INVOCATIONS = 48

  private var prefs: SharedPreferences? = null

  fun init(context: Context) {
    if (prefs != null) return
    prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
  }

  fun enqueue(reason: String) {
    enqueueInvocation(
      reason = reason,
      platformSource = "android_legacy_queue",
    )
  }

  fun enqueueInvocation(
    reason: String,
    platformSource: String,
    isWifiAvailable: Boolean? = null,
    isIdle: Boolean? = null,
    wakeTimestampUtcMs: Long = System.currentTimeMillis(),
  ) {
    val p = prefs ?: return
    try {
      val existing = loadSnapshot(p)
      val payload = JSONObject().apply {
        put("reason", reason)
        put("platform_source", platformSource)
        put("wake_timestamp_utc", isoUtc(wakeTimestampUtcMs))
        if (isWifiAvailable != null) {
          put("is_wifi_available", isWifiAvailable)
        }
        if (isIdle != null) {
          put("is_idle", isIdle)
        }
      }
      existing.add(payload)
      val start = (existing.size - MAX_PERSISTED_INVOCATIONS).coerceAtLeast(0)
      val capped = existing.subList(start, existing.size)
      val arr = JSONArray()
      for (entry in capped) {
        arr.put(entry)
      }
      p.edit().putString(PREFS_KEY_QUEUE, arr.toString()).apply()
    } catch (_: Exception) {
      // Best-effort store.
    }
  }

  fun drain(): List<String> {
    return drainInvocations().mapNotNull { it["reason"] as? String }
  }

  fun drainInvocations(): List<Map<String, Any?>> {
    val p = prefs ?: return emptyList()
    return try {
      val snapshot = loadSnapshot(p)
      p.edit().remove(PREFS_KEY_QUEUE).apply()
      snapshot.map { invocation ->
        buildMap<String, Any?> {
          put("reason", invocation.optString("reason"))
          put("platform_source", invocation.optString("platform_source"))
          put("wake_timestamp_utc", invocation.optString("wake_timestamp_utc"))
          if (invocation.has("is_wifi_available")) {
            put("is_wifi_available", invocation.optBoolean("is_wifi_available"))
          }
          if (invocation.has("is_idle")) {
            put("is_idle", invocation.optBoolean("is_idle"))
          }
        }
      }
    } catch (_: Exception) {
      emptyList()
    }
  }

  fun hasPendingInvocations(): Boolean {
    val p = prefs ?: return false
    return try {
      loadSnapshot(p).isNotEmpty()
    } catch (_: Exception) {
      false
    }
  }

  private fun loadSnapshot(p: SharedPreferences): MutableList<JSONObject> {
    val raw = p.getString(PREFS_KEY_QUEUE, null) ?: return mutableListOf()
    val arr = JSONArray(raw)
    val out = mutableListOf<JSONObject>()
    for (i in 0 until arr.length()) {
      val value = arr.optJSONObject(i)
      if (value != null && value.optString("reason").isNotBlank()) {
        out.add(value)
      } else {
        val legacyValue = arr.optString(i, "")
        if (legacyValue.isNotBlank()) {
          out.add(
            JSONObject().apply {
              put("reason", legacyValue)
              put("platform_source", "android_legacy_queue")
              put("wake_timestamp_utc", isoUtc(System.currentTimeMillis()))
            },
          )
        }
      }
    }
    return out
  }

  private fun isoUtc(epochMs: Long): String {
    val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
    formatter.timeZone = TimeZone.getTimeZone("UTC")
    return formatter.format(Date(epochMs))
  }
}
