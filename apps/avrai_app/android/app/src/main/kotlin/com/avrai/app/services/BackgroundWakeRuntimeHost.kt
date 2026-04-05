package com.avrai.app.services

import android.content.BroadcastReceiver
import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugins.GeneratedPluginRegistrant

object BackgroundWakeRuntimeHost {
  private const val ENTRYPOINT_NAME = "runAvraiBackgroundWake"
  private const val EXECUTION_TIMEOUT_MS = 25_000L

  private val mainHandler = Handler(Looper.getMainLooper())
  private val pendingResults = mutableListOf<BroadcastReceiver.PendingResult>()

  private var currentEngine: FlutterEngine? = null
  private var timeoutRunnable: Runnable? = null

  @Synchronized
  fun executeNow(
    context: Context,
    pendingResult: BroadcastReceiver.PendingResult? = null,
  ) {
    pendingResult?.let { pendingResults.add(it) }
    if (currentEngine != null) {
      return
    }

    val appContext = context.applicationContext
    BackgroundWakeStore.init(appContext)

    try {
      val flutterLoader = FlutterInjector.instance().flutterLoader()
      flutterLoader.startInitialization(appContext)
      flutterLoader.ensureInitializationComplete(appContext, null)

      val engine = FlutterEngine(appContext)
      currentEngine = engine
      GeneratedPluginRegistrant.registerWith(engine)
      BackgroundRuntimeChannelBindings.configure(
        context = appContext,
        binaryMessenger = engine.dartExecutor.binaryMessenger,
        onHeadlessExecutionComplete = { success, _, _ ->
          finishExecution(success = success)
        },
      )

      engine.dartExecutor.executeDartEntrypoint(
        DartExecutor.DartEntrypoint(
          flutterLoader.findAppBundlePath(),
          ENTRYPOINT_NAME,
        ),
      )

      val timeoutRunnable = Runnable {
        finishExecution(success = false)
      }
      this.timeoutRunnable = timeoutRunnable
      mainHandler.postDelayed(timeoutRunnable, EXECUTION_TIMEOUT_MS)
    } catch (_: Exception) {
      finishExecution(success = false)
    }
  }

  @Synchronized
  private fun finishExecution(success: Boolean) {
    timeoutRunnable?.let(mainHandler::removeCallbacks)
    timeoutRunnable = null

    currentEngine?.destroy()
    currentEngine = null

    val results = pendingResults.toList()
    pendingResults.clear()
    for (result in results) {
      try {
        result.finish()
      } catch (_: Exception) {
        // Best-effort cleanup.
      }
    }
  }
}
