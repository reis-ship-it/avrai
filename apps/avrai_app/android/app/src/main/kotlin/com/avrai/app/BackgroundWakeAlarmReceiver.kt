package com.avrai.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.avrai.app.services.BackgroundWakeScheduler
import com.avrai.app.services.BackgroundWakeStore
import com.avrai.app.services.BackgroundWakeRuntimeHost

class BackgroundWakeAlarmReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent?) {
    BackgroundWakeStore.init(context)
    val pendingResult = goAsync()
    BackgroundWakeStore.enqueueInvocation(
      reason = "background_task_window",
      platformSource = "android_alarm_receiver",
    )
    BackgroundWakeScheduler.restore(context)
    BackgroundWakeRuntimeHost.executeNow(context, pendingResult)
  }
}
