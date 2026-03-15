import 'dart:developer' as developer;

import 'package:avrai_runtime_os/services/background/background_execution_models.dart';
import 'package:flutter/services.dart';

abstract class BackgroundPlatformWakePort {
  Future<void> notifyForegroundReady();

  Future<List<BackgroundWakeInvocationPayload>> consumePendingWakeInvocations();

  Future<Map<String, dynamic>> getPlatformWakeCapabilities();

  Future<void> scheduleBackgroundTaskWindow({
    required Duration interval,
  });

  Future<void> cancelBackgroundTaskWindow();

  Future<void> notifyHeadlessExecutionComplete({
    required bool success,
    int handledInvocationCount = 0,
    String? failureSummary,
  });
}

class MethodChannelBackgroundPlatformWakeBridge
    implements BackgroundPlatformWakePort {
  MethodChannelBackgroundPlatformWakeBridge({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'avra/background_runtime';
  static const String _logName = 'BackgroundPlatformWakeBridge';

  final MethodChannel _channel;

  @override
  Future<void> notifyForegroundReady() async {
    try {
      await _channel.invokeMethod<void>('notifyForegroundReady');
    } catch (error, stackTrace) {
      developer.log(
        'Failed to notify native background runtime that foreground is ready',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<BackgroundWakeInvocationPayload>>
      consumePendingWakeInvocations() async {
    try {
      final rawInvocations = await _channel
          .invokeMethod<List<Object?>>('consumePendingWakeInvocations');
      if (rawInvocations == null || rawInvocations.isEmpty) {
        return const <BackgroundWakeInvocationPayload>[];
      }
      final invocations = <BackgroundWakeInvocationPayload>[];
      for (final entry in rawInvocations.whereType<Map>()) {
        try {
          invocations.add(
            BackgroundWakeInvocationPayload.fromJson(
              entry.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            ),
          );
        } catch (_) {
          // Ignore malformed or unsupported wake payloads.
        }
      }
      return invocations;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to consume native background wake invocations',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <BackgroundWakeInvocationPayload>[];
    }
  }

  @override
  Future<Map<String, dynamic>> getPlatformWakeCapabilities() async {
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getPlatformWakeCapabilities',
      );
      if (raw == null) {
        return const <String, dynamic>{};
      }
      return raw.map(
        (key, value) => MapEntry(
          key?.toString() ?? '',
          value,
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to fetch native background wake capabilities',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <String, dynamic>{};
    }
  }

  @override
  Future<void> scheduleBackgroundTaskWindow({
    required Duration interval,
  }) async {
    try {
      await _channel.invokeMethod<void>(
        'scheduleBackgroundTaskWindow',
        <String, Object>{
          'intervalSeconds': interval.inSeconds,
        },
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to schedule native background task window',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> cancelBackgroundTaskWindow() async {
    try {
      await _channel.invokeMethod<void>('cancelBackgroundTaskWindow');
    } catch (error, stackTrace) {
      developer.log(
        'Failed to cancel native background task window',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> notifyHeadlessExecutionComplete({
    required bool success,
    int handledInvocationCount = 0,
    String? failureSummary,
  }) async {
    try {
      await _channel.invokeMethod<void>(
        'notifyHeadlessExecutionComplete',
        <String, Object?>{
          'success': success,
          'handledInvocationCount': handledInvocationCount,
          if (failureSummary != null) 'failureSummary': failureSummary,
        },
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to notify native runtime that headless execution completed',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
