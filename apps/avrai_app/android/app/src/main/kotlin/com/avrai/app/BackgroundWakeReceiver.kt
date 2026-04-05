package com.avrai.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.avrai.app.services.BackgroundWakeScheduler
import com.avrai.app.services.BackgroundWakeStore
import com.avrai.app.services.BackgroundWakeRuntimeHost

class BackgroundWakeReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent?) {
    BackgroundWakeStore.init(context)
    when (intent?.action) {
      Intent.ACTION_BOOT_COMPLETED,
      Intent.ACTION_MY_PACKAGE_REPLACED -> {
        val pendingResult = goAsync()
        BackgroundWakeStore.enqueueInvocation(
          reason = "boot_completed",
          platformSource = "android_boot_receiver",
        )
        BackgroundWakeScheduler.restore(context)
        BackgroundWakeRuntimeHost.executeNow(context, pendingResult)
      }
    }
  }
}
