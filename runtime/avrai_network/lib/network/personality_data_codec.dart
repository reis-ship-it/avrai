import 'dart:developer' as developer;
import 'dart:convert';

import 'package:avrai_network/network/models/anonymized_vibe_data.dart';

/// Personality Data Codec
/// Encodes and decodes anonymized personality data for device discovery
/// Supports compact formats for BLE advertisements, TXT records, and WebRTC messages
class PersonalityDataCodec {
  static const String _logName = 'PersonalityDataCodec';

  // Magic bytes to identify SPOTS personality data
  static const List<int> _spotsMagicBytes = [
    0x53,
    0x50,
    0x4F,
    0x54,
    0x53,
  ]; // "SPOTS"

  /// Encode AnonymizedVibeData to compact binary format (for BLE manufacturer data)
  static List<int> encodeToBinary(AnonymizedVibeData data) {
    try {
      developer.log(
        'Encoding personality data to binary format',
        name: _logName,
      );

      final json = data.toJson();
      final jsonString = jsonEncode(json);
      final jsonBytes = utf8.encode(jsonString);

      // Create binary format: [magic bytes][length][json data]
      final encoded = <int>[
        ..._spotsMagicBytes,
        ..._encodeUint16(jsonBytes.length),
        ...jsonBytes,
      ];

      developer.log(
        'Encoded ${jsonBytes.length} bytes of personality data',
        name: _logName,
      );
      return encoded;
    } catch (e) {
      developer.log('Error encoding personality data: $e', name: _logName);
      return [];
    }
  }

  /// Decode binary format to AnonymizedVibeData (from BLE manufacturer data)
  static AnonymizedVibeData? decodeFromBinary(List<int> data) {
    try {
      if (data.length < _spotsMagicBytes.length + 2) {
        developer.log(
          'Data too short to contain personality data',
          name: _logName,
        );
        return null;
      }

      // Check magic bytes
      for (int i = 0; i < _spotsMagicBytes.length; i++) {
        if (data[i] != _spotsMagicBytes[i]) {
          developer.log('Invalid magic bytes', name: _logName);
          return null;
        }
      }

      // Extract length
      final length = _decodeUint16(data, _spotsMagicBytes.length);
      final dataStart = _spotsMagicBytes.length + 2;

      if (data.length < dataStart + length) {
        developer.log('Data length mismatch', name: _logName);
        return null;
      }

      // Extract JSON data
      final jsonBytes = data.sublist(dataStart, dataStart + length);
      final jsonString = utf8.decode(jsonBytes);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // Reconstruct AnonymizedVibeData
      return _jsonToAnonymizedVibeData(json);
    } catch (e) {
      developer.log(
        'Error decoding binary personality data: $e',
        name: _logName,
      );
      return null;
    }
  }

  /// Encode AnonymizedVibeData to base64 string (for TXT records and WebRTC)
  static String encodeToBase64(AnonymizedVibeData data) {
    try {
      developer.log('Encoding personality data to base64', name: _logName);

      final json = data.toJson();
      final jsonString = jsonEncode(json);
      final jsonBytes = utf8.encode(jsonString);
      final base64String = base64Encode(jsonBytes);

      developer.log(
        'Encoded personality data to ${base64String.length} base64 characters',
        name: _logName,
      );
      return base64String;
    } catch (e) {
      developer.log('Error encoding to base64: $e', name: _logName);
      return '';
    }
  }

  /// Decode base64 string to AnonymizedVibeData (from TXT records and WebRTC)
  static AnonymizedVibeData? decodeFromBase64(String base64String) {
    try {
      if (base64String.isEmpty) {
        return null;
      }

      final jsonBytes = base64Decode(base64String);
      final jsonString = utf8.decode(jsonBytes);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      return _jsonToAnonymizedVibeData(json);
    } catch (e) {
      developer.log(
        'Error decoding base64 personality data: $e',
        name: _logName,
      );
      return null;
    }
  }

  /// Encode AnonymizedVibeData to compact JSON string (for WebRTC messages)
  static String encodeToJson(AnonymizedVibeData data) {
    try {
      final json = data.toJson();
      return jsonEncode(json);
    } catch (e) {
      developer.log('Error encoding to JSON: $e', name: _logName);
      return '';
    }
  }

  /// Decode JSON string to AnonymizedVibeData (from WebRTC messages)
  static AnonymizedVibeData? decodeFromJson(String jsonString) {
    try {
      if (jsonString.isEmpty) {
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return _jsonToAnonymizedVibeData(json);
    } catch (e) {
      developer.log('Error decoding JSON personality data: $e', name: _logName);
      return null;
    }
  }

  /// Check if binary data contains SPOTS personality data
  static bool isSpotsPersonalityData(List<int> data) {
    if (data.length < _spotsMagicBytes.length) {
      return false;
    }

    for (int i = 0; i < _spotsMagicBytes.length; i++) {
      if (data[i] != _spotsMagicBytes[i]) {
        return false;
      }
    }

    return true;
  }

  /// Reconstruct AnonymizedVibeData from JSON
  static AnonymizedVibeData _jsonToAnonymizedVibeData(
    Map<String, dynamic> json,
  ) {
    return AnonymizedVibeData.fromJson(json);
  }

  /// Encode 16-bit unsigned integer to bytes (little-endian)
  static List<int> _encodeUint16(int value) {
    return [value & 0xFF, (value >> 8) & 0xFF];
  }

  /// Decode 16-bit unsigned integer from bytes (little-endian)
  static int _decodeUint16(List<int> data, int offset) {
    return data[offset] | (data[offset + 1] << 8);
  }
}
