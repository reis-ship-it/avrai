package com.avrai.app.services

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

object BackgroundRuntimeChannelBindings {
  const val CHANNEL_NAME = "avra/background_runtime"

  fun configure(
    context: Context,
    binaryMessenger: BinaryMessenger,
    onHeadlessExecutionComplete: ((Boolean, Int, String?) -> Unit)? = null,
  ) {
    BackgroundWakeStore.init(context)

    MethodChannel(binaryMessenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
      when (call.method) {
        "consumePendingWakeInvocations" -> {
          result.success(BackgroundWakeStore.drainInvocations())
        }
        "consumePendingWakeReasons" -> {
          result.success(BackgroundWakeStore.drain())
        }
        "notifyForegroundReady" -> {
          result.success(true)
        }
        "scheduleBackgroundTaskWindow" -> {
          val intervalSeconds = call.argument<Number>("intervalSeconds")?.toLong()
          if (intervalSeconds == null || intervalSeconds <= 0L) {
            result.success(false)
          } else {
            BackgroundWakeScheduler.schedule(context.applicationContext, intervalSeconds)
            result.success(true)
          }
        }
        "cancelBackgroundTaskWindow" -> {
          BackgroundWakeScheduler.cancel(context.applicationContext)
          result.success(true)
        }
        "notifyHeadlessExecutionComplete" -> {
          val success = call.argument<Boolean>("success") ?: false
          val handledInvocationCount =
            call.argument<Number>("handledInvocationCount")?.toInt() ?: 0
          val failureSummary = call.argument<String>("failureSummary")
          onHeadlessExecutionComplete?.invoke(
            success,
            handledInvocationCount,
            failureSummary,
          )
          result.success(true)
        }
        "getPlatformWakeCapabilities" -> {
          result.success(
            mapOf(
              "platform" to "android",
              "supports_boot_restore" to true,
              "supports_background_task_window" to true,
              "supports_connectivity_wifi" to true,
              "supports_ble_encounter" to true,
              "supports_significant_location" to true,
              "supports_headless_execution" to true,
            ),
          )
        }
        else -> result.notImplemented()
      }
    }
  }
}
