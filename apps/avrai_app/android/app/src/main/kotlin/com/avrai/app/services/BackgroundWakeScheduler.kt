package com.avrai.app.services

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.avrai.app.BackgroundWakeAlarmReceiver

object BackgroundWakeScheduler {
  private const val PREFS_NAME = "avrai_background_wake_scheduler"
  private const val PREFS_KEY_INTERVAL_SECONDS = "interval_seconds_v1"
  private const val DEFAULT_INTERVAL_SECONDS = 30 * 60L
  private const val REQUEST_CODE = 44017

  fun schedule(context: Context, intervalSeconds: Long) {
    val safeIntervalSeconds = intervalSeconds.coerceAtLeast(15 * 60L)
    persistInterval(context, safeIntervalSeconds)
    val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
    alarmManager.cancel(pendingIntent(context))
    alarmManager.setInexactRepeating(
      AlarmManager.RTC_WAKEUP,
      System.currentTimeMillis() + (safeIntervalSeconds * 1000L),
      safeIntervalSeconds * 1000L,
      pendingIntent(context),
    )
  }

  fun cancel(context: Context) {
    val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
    alarmManager.cancel(pendingIntent(context))
    context
      .applicationContext
      .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
      .edit()
      .remove(PREFS_KEY_INTERVAL_SECONDS)
      .apply()
  }

  fun restore(context: Context) {
    val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    val intervalSeconds = prefs.getLong(PREFS_KEY_INTERVAL_SECONDS, DEFAULT_INTERVAL_SECONDS)
    if (intervalSeconds > 0L) {
      schedule(context, intervalSeconds)
    }
  }

  private fun persistInterval(context: Context, intervalSeconds: Long) {
    context
      .applicationContext
      .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
      .edit()
      .putLong(PREFS_KEY_INTERVAL_SECONDS, intervalSeconds)
      .apply()
  }

  private fun pendingIntent(context: Context): PendingIntent {
    val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    return PendingIntent.getBroadcast(
      context,
      REQUEST_CODE,
      Intent(context, BackgroundWakeAlarmReceiver::class.java),
      flags,
    )
  }
}
