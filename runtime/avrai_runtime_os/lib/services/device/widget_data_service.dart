// Widget Data Service
//
// Service for sharing data between Flutter and iOS WidgetKit widgets.
// Uses App Groups to share data via UserDefaults.
//
// Features:
// - Save knot data for widget display
// - Save nearby spot data
// - Save reservation data
// - Trigger widget refresh
//
// Usage:
//   final service = WidgetDataService();
//   await service.updateKnotData(knot);

import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:avrai_core/models/personality_knot.dart';

/// Service for sharing data with iOS WidgetKit widgets.
///
/// Uses App Groups and UserDefaults to share data between
/// the Flutter app and native iOS widget extensions.
class WidgetDataService {
  static const String _logName = 'WidgetDataService';

  /// Method channel for widget operations
  static const MethodChannel _channel = MethodChannel('avra/widget_data');

  /// App Group identifier (must match Xcode configuration)
  static const String appGroupId = 'group.com.avrai.app';

  /// Singleton instance
  static final WidgetDataService _instance = WidgetDataService._internal();

  factory WidgetDataService() => _instance;

  WidgetDataService._internal();

  /// Update the knot data for the widget
  ///
  /// Saves a simplified knot representation that the widget can display.
  Future<bool> updateKnotData({
    required String agentId,
    required int crossingNumber,
    required double writhe,
    required int bridgeNumber,
    String? archetypeName,
  }) async {
    if (!Platform.isIOS) return false;

    try {
      final data = {
        'agentId': agentId,
        'crossingNumber': crossingNumber,
        'writhe': writhe,
        'bridgeNumber': bridgeNumber,
        'archetypeName': archetypeName,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final result = await _channel.invokeMethod<bool>('updateKnotData', data);

      if (result == true) {
        developer.log(
          'Knot data updated for widget',
          name: _logName,
        );
        await refreshWidget('KnotWidget');
      }

      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Error updating knot data: ${e.message}',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  /// Update knot data from a PersonalityKnot object
  Future<bool> updateKnotFromModel(PersonalityKnot knot, String agentId) async {
    return updateKnotData(
      agentId: agentId,
      crossingNumber: knot.invariants.crossingNumber,
      writhe: knot.invariants.writhe.toDouble(),
      bridgeNumber: knot.invariants.bridgeNumber,
    );
  }

  /// Update nearby spot data for the widget
  Future<bool> updateNearbySpotData({
    required String spotId,
    required String spotName,
    required String category,
    required double distance,
    required double rating,
    String? address,
    String? imageUrl,
  }) async {
    if (!Platform.isIOS) return false;

    try {
      final data = {
        'spotId': spotId,
        'spotName': spotName,
        'category': category,
        'distance': distance,
        'rating': rating,
        'address': address,
        'imageUrl': imageUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final result = await _channel.invokeMethod<bool>('updateSpotData', data);

      if (result == true) {
        developer.log(
          'Spot data updated for widget: $spotName',
          name: _logName,
        );
        await refreshWidget('NearbySpotWidget');
      }

      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Error updating spot data: ${e.message}',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  /// Update reservation data for the widget
  Future<bool> updateReservationData({
    required String reservationId,
    required String spotName,
    required DateTime reservationTime,
    required int partySize,
    required String status,
    String? spotAddress,
    String? confirmationCode,
  }) async {
    if (!Platform.isIOS) return false;

    try {
      final data = {
        'reservationId': reservationId,
        'spotName': spotName,
        'reservationTime': reservationTime.toIso8601String(),
        'partySize': partySize,
        'status': status,
        'spotAddress': spotAddress,
        'confirmationCode': confirmationCode,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final result =
          await _channel.invokeMethod<bool>('updateReservationData', data);

      if (result == true) {
        developer.log(
          'Reservation data updated for widget: $spotName',
          name: _logName,
        );
        await refreshWidget('ReservationWidget');
      }

      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Error updating reservation data: ${e.message}',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  /// Clear all widget data
  Future<bool> clearAllData() async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('clearAllData');

      if (result == true) {
        developer.log(
          'All widget data cleared',
          name: _logName,
        );
        await refreshAllWidgets();
      }

      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Error clearing widget data: ${e.message}',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  /// Request a widget refresh
  Future<bool> refreshWidget(String widgetName) async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('refreshWidget', {
        'widgetName': widgetName,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Error refreshing widget $widgetName: ${e.message}',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  /// Refresh all widgets
  Future<bool> refreshAllWidgets() async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('refreshAllWidgets');
      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Error refreshing all widgets: ${e.message}',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  /// Save the knot image data for widget display
  ///
  /// The image should be a PNG encoded as base64.
  Future<bool> saveKnotImage(String base64Image) async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('saveKnotImage', {
        'imageData': base64Image,
      });

      if (result == true) {
        developer.log(
          'Knot image saved for widget',
          name: _logName,
        );
      }

      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Error saving knot image: ${e.message}',
        error: e,
        name: _logName,
      );
      return false;
    }
  }
}

/// Data model for widget knot data
class WidgetKnotData {
  final String agentId;
  final int crossingNumber;
  final double writhe;
  final int bridgeNumber;
  final String? archetypeName;
  final DateTime updatedAt;

  WidgetKnotData({
    required this.agentId,
    required this.crossingNumber,
    required this.writhe,
    required this.bridgeNumber,
    this.archetypeName,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'agentId': agentId,
        'crossingNumber': crossingNumber,
        'writhe': writhe,
        'bridgeNumber': bridgeNumber,
        'archetypeName': archetypeName,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory WidgetKnotData.fromJson(Map<String, dynamic> json) => WidgetKnotData(
        agentId: json['agentId'] as String,
        crossingNumber: json['crossingNumber'] as int,
        writhe: (json['writhe'] as num).toDouble(),
        bridgeNumber: json['bridgeNumber'] as int,
        archetypeName: json['archetypeName'] as String?,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

/// Data model for widget spot data
class WidgetSpotData {
  final String spotId;
  final String spotName;
  final String category;
  final double distance;
  final double rating;
  final String? address;
  final String? imageUrl;
  final DateTime updatedAt;

  WidgetSpotData({
    required this.spotId,
    required this.spotName,
    required this.category,
    required this.distance,
    required this.rating,
    this.address,
    this.imageUrl,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'spotId': spotId,
        'spotName': spotName,
        'category': category,
        'distance': distance,
        'rating': rating,
        'address': address,
        'imageUrl': imageUrl,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// Data model for widget reservation data
class WidgetReservationData {
  final String reservationId;
  final String spotName;
  final DateTime reservationTime;
  final int partySize;
  final String status;
  final String? spotAddress;
  final String? confirmationCode;
  final DateTime updatedAt;

  WidgetReservationData({
    required this.reservationId,
    required this.spotName,
    required this.reservationTime,
    required this.partySize,
    required this.status,
    this.spotAddress,
    this.confirmationCode,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'reservationId': reservationId,
        'spotName': spotName,
        'reservationTime': reservationTime.toIso8601String(),
        'partySize': partySize,
        'status': status,
        'spotAddress': spotAddress,
        'confirmationCode': confirmationCode,
        'updatedAt': updatedAt.toIso8601String(),
      };
}
