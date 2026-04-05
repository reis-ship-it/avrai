package com.avrai.app

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter plugin for accessing Android's UsageStatsManager.
 * 
 * Provides app usage statistics for AI learning:
 * - What apps the user spends time in
 * - App usage patterns (time of day, duration)
 * - App categories (social, fitness, productivity, etc.)
 * 
 * Requires PACKAGE_USAGE_STATS permission (user must enable in Settings).
 * All data is processed locally on-device per SPOTS privacy philosophy.
 */
class AppUsagePlugin(private val context: Context) : MethodChannel.MethodCallHandler {
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkPermission" -> {
                val hasPermission = checkUsageStatsPermission()
                result.success(hasPermission)
            }
            "requestPermission" -> {
                openUsageAccessSettings()
                result.success(null)
            }
            "getUsageStats" -> {
                val startTime = call.argument<Long>("startTime") ?: 0L
                val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()
                val stats = getUsageStats(startTime, endTime)
                result.success(stats)
            }
            else -> result.notImplemented()
        }
    }
    
    /**
     * Check if the app has permission to access usage stats.
     * 
     * This is a special permission that the user must grant via Settings.
     */
    private fun checkUsageStatsPermission(): Boolean {
        return try {
            val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    context.packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    context.packageName
                )
            }
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Open the system Settings page for Usage Access permission.
     * 
     * The user must manually enable the permission for this app.
     */
    private fun openUsageAccessSettings() {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        } catch (e: Exception) {
            // Some devices may not support this intent
            // Fall back to general settings
            try {
                val fallbackIntent = Intent(Settings.ACTION_SETTINGS)
                fallbackIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(fallbackIntent)
            } catch (e2: Exception) {
                // Ignore - best effort
            }
        }
    }
    
    /**
     * Get app usage statistics for the specified time range.
     * 
     * Returns a map containing:
     * - apps: List of app usage data (packageName, totalTimeInForeground, etc.)
     * - startTime: Start of the query range
     * - endTime: End of the query range
     */
    private fun getUsageStats(startTime: Long, endTime: Long): Map<String, Any?> {
        if (!checkUsageStatsPermission()) {
            return mapOf(
                "error" to "permission_denied",
                "apps" to emptyList<Map<String, Any>>(),
                "startTime" to startTime,
                "endTime" to endTime
            )
        }
        
        return try {
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) 
                as UsageStatsManager
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )
            
            val apps = mutableListOf<Map<String, Any>>()
            
            for (stat in stats) {
                // Only include apps with actual foreground usage
                if (stat.totalTimeInForeground > 0) {
                    apps.add(mapOf(
                        "packageName" to stat.packageName,
                        "totalTimeInForeground" to stat.totalTimeInForeground,
                        "lastTimeUsed" to stat.lastTimeUsed,
                        "firstTimeStamp" to stat.firstTimeStamp,
                        "lastTimeStamp" to stat.lastTimeStamp
                    ))
                }
            }
            
            // Sort by usage time (descending)
            apps.sortByDescending { it["totalTimeInForeground"] as Long }
            
            mapOf(
                "apps" to apps,
                "startTime" to startTime,
                "endTime" to endTime,
                "appCount" to apps.size
            )
        } catch (e: Exception) {
            mapOf(
                "error" to e.message,
                "apps" to emptyList<Map<String, Any>>(),
                "startTime" to startTime,
                "endTime" to endTime
            )
        }
    }
}
