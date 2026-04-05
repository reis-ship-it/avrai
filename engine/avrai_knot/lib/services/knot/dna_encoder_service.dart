import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:avrai_core/models/personality_knot.dart';

/// Service responsible for serializing a [PersonalityKnot] into a highly
/// compressed binary format suitable for 5-second BLE broadcast windows.
///
/// Part of the v0.1 Reality Check "Math String" payload optimization.
class DnaEncoderService {
  static const int _version = 1;

  /// Encodes a [PersonalityKnot] into a highly compressed binary payload.
  Uint8List encode(PersonalityKnot knot) {
    try {
      final builder = BytesBuilder();

      // Version
      builder.addByte(_version);

      // AgentId (UTF-8 string)
      final agentIdBytes = utf8.encode(knot.agentId);
      if (agentIdBytes.length > 255) {
        throw const FormatException('agentId too long (max 255 bytes)');
      }
      builder.addByte(agentIdBytes.length);
      builder.add(agentIdBytes);

      // Timestamps
      _addInt64(builder, knot.createdAt.millisecondsSinceEpoch);
      _addInt64(builder, knot.lastUpdated.millisecondsSinceEpoch);

      // Braid data
      if (knot.braidData.length > 65535) {
        throw const FormatException('braidData too long (max 65535 elements)');
      }
      _addUint16(builder, knot.braidData.length);
      for (final value in knot.braidData) {
        _addFloat32(builder, value);
      }

      // Physics (optional)
      if (knot.physics != null) {
        builder.addByte(1);
        _addFloat32(builder, knot.physics!.energy);
        _addFloat32(builder, knot.physics!.stability);
        _addFloat32(builder, knot.physics!.length);
      } else {
        builder.addByte(0);
      }

      // Invariants
      _encodeInvariants(builder, knot.invariants);

      final result = builder.toBytes();
      developer.log(
        'Encoded knot ${knot.agentId} to ${result.length} bytes',
        name: 'DnaEncoderService',
      );

      return result;
    } catch (e, st) {
      developer.log(
        'Failed to encode knot',
        error: e,
        stackTrace: st,
        name: 'DnaEncoderService',
      );
      throw FormatException('Failed to encode PersonalityKnot: $e');
    }
  }

  /// Encodes the knot to a hex string for easy sharing over limited protocols
  String encodeToHex(PersonalityKnot knot) {
    final bytes = encode(knot);
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Decodes a [PersonalityKnot] from a highly compressed binary payload.
  PersonalityKnot decode(Uint8List bytes) {
    try {
      final bd = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
      int offset = 0;

      final version = bd.getUint8(offset++);
      if (version != _version) {
        throw FormatException('Unsupported format version: $version');
      }

      final agentIdLen = bd.getUint8(offset++);
      final agentId = utf8.decode(bytes.sublist(offset, offset + agentIdLen));
      offset += agentIdLen;

      final createdAtMs = bd.getInt64(offset, Endian.little);
      offset += 8;

      final lastUpdatedMs = bd.getInt64(offset, Endian.little);
      offset += 8;

      final braidLen = bd.getUint16(offset, Endian.little);
      offset += 2;

      final braidData = <double>[];
      for (int i = 0; i < braidLen; i++) {
        // Round to 5 decimals to fix float32 reconstruction precision issues
        braidData.add(_cleanFloat32(bd.getFloat32(offset, Endian.little)));
        offset += 4;
      }

      final hasPhysics = bd.getUint8(offset++) == 1;
      KnotPhysics? physics;
      if (hasPhysics) {
        final energy = _cleanFloat32(bd.getFloat32(offset, Endian.little));
        offset += 4;
        final stability = _cleanFloat32(bd.getFloat32(offset, Endian.little));
        offset += 4;
        final length = _cleanFloat32(bd.getFloat32(offset, Endian.little));
        offset += 4;
        physics = KnotPhysics(
          energy: energy,
          stability: stability,
          length: length,
        );
      }

      final crossingNumber = bd.getInt16(offset, Endian.little);
      offset += 2;

      final writhe = bd.getInt16(offset, Endian.little);
      offset += 2;

      final signature = bd.getInt16(offset, Endian.little);
      offset += 2;

      final bridgeNumber = bd.getInt16(offset, Endian.little);
      offset += 2;

      final braidIndex = bd.getInt16(offset, Endian.little);
      offset += 2;

      final determinant = bd.getInt32(offset, Endian.little);
      offset += 4;

      int? unknottingNumber;
      if (bd.getUint8(offset++) == 1) {
        unknottingNumber = bd.getInt16(offset, Endian.little);
        offset += 2;
      }

      int? arfInvariant;
      if (bd.getUint8(offset++) == 1) {
        arfInvariant = bd.getInt8(offset++);
      }

      double? hyperbolicVolume;
      if (bd.getUint8(offset++) == 1) {
        hyperbolicVolume = _cleanFloat32(bd.getFloat32(offset, Endian.little));
        offset += 4;
      }

      final jonesLen = bd.getUint8(offset++);
      final jonesPolynomial = <double>[];
      for (int i = 0; i < jonesLen; i++) {
        jonesPolynomial.add(
          _cleanFloat32(bd.getFloat32(offset, Endian.little)),
        );
        offset += 4;
      }

      final alexLen = bd.getUint8(offset++);
      final alexanderPolynomial = <double>[];
      for (int i = 0; i < alexLen; i++) {
        alexanderPolynomial.add(
          _cleanFloat32(bd.getFloat32(offset, Endian.little)),
        );
        offset += 4;
      }

      List<double>? homflyPolynomial;
      if (bd.getUint8(offset++) == 1) {
        final homflyLen = bd.getUint8(offset++);
        homflyPolynomial = [];
        for (int i = 0; i < homflyLen; i++) {
          homflyPolynomial.add(
            _cleanFloat32(bd.getFloat32(offset, Endian.little)),
          );
          offset += 4;
        }
      }

      final invariants = KnotInvariants(
        crossingNumber: crossingNumber,
        writhe: writhe,
        signature: signature,
        bridgeNumber: bridgeNumber,
        braidIndex: braidIndex,
        determinant: determinant,
        unknottingNumber: unknottingNumber,
        arfInvariant: arfInvariant,
        hyperbolicVolume: hyperbolicVolume,
        jonesPolynomial: jonesPolynomial,
        alexanderPolynomial: alexanderPolynomial,
        homflyPolynomial: homflyPolynomial,
      );

      developer.log(
        'Decoded knot $agentId from ${bytes.length} bytes',
        name: 'DnaEncoderService',
      );

      return PersonalityKnot(
        agentId: agentId,
        invariants: invariants,
        physics: physics,
        braidData: braidData,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(lastUpdatedMs),
      );
    } catch (e, st) {
      developer.log(
        'Failed to decode knot bytes',
        error: e,
        stackTrace: st,
        name: 'DnaEncoderService',
      );
      throw FormatException('Failed to decode PersonalityKnot: $e');
    }
  }

  /// Decodes a [PersonalityKnot] from a hex string.
  PersonalityKnot decodeFromHex(String hex) {
    if (hex.length % 2 != 0) {
      throw const FormatException('Invalid hex string: length must be even');
    }

    final bytes = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < bytes.length; i++) {
      final byteHex = hex.substring(i * 2, i * 2 + 2);
      bytes[i] = int.parse(byteHex, radix: 16);
    }

    return decode(bytes);
  }

  // --- Binary formatting helpers ---

  void _encodeInvariants(BytesBuilder builder, KnotInvariants inv) {
    // crossingNumber, writhe, signature, bridgeNumber, braidIndex: Int16
    _addInt16(builder, inv.crossingNumber);
    _addInt16(builder, inv.writhe);
    _addInt16(builder, inv.signature);
    _addInt16(builder, inv.bridgeNumber);
    _addInt16(builder, inv.braidIndex);

    // determinant: Int32
    _addInt32(builder, inv.determinant);

    // Optional ints/doubles
    _addOptionalInt16(builder, inv.unknottingNumber);
    _addOptionalInt8(builder, inv.arfInvariant);
    _addOptionalFloat32(builder, inv.hyperbolicVolume);

    // Lists
    _addDoubleList(builder, inv.jonesPolynomial);
    _addDoubleList(builder, inv.alexanderPolynomial);

    if (inv.homflyPolynomial != null) {
      builder.addByte(1);
      _addDoubleList(builder, inv.homflyPolynomial!);
    } else {
      builder.addByte(0);
    }
  }

  void _addInt8(BytesBuilder builder, int value) {
    final bd = ByteData(1);
    bd.setInt8(0, value);
    builder.add(bd.buffer.asUint8List());
  }

  void _addInt16(BytesBuilder builder, int value) {
    final bd = ByteData(2);
    bd.setInt16(0, value, Endian.little);
    builder.add(bd.buffer.asUint8List());
  }

  void _addUint16(BytesBuilder builder, int value) {
    final bd = ByteData(2);
    bd.setUint16(0, value, Endian.little);
    builder.add(bd.buffer.asUint8List());
  }

  void _addInt32(BytesBuilder builder, int value) {
    final bd = ByteData(4);
    bd.setInt32(0, value, Endian.little);
    builder.add(bd.buffer.asUint8List());
  }

  void _addInt64(BytesBuilder builder, int value) {
    final bd = ByteData(8);
    bd.setInt64(0, value, Endian.little);
    builder.add(bd.buffer.asUint8List());
  }

  void _addFloat32(BytesBuilder builder, double value) {
    final bd = ByteData(4);
    bd.setFloat32(0, value, Endian.little);
    builder.add(bd.buffer.asUint8List());
  }

  void _addOptionalInt8(BytesBuilder builder, int? value) {
    if (value != null) {
      builder.addByte(1);
      _addInt8(builder, value);
    } else {
      builder.addByte(0);
    }
  }

  void _addOptionalInt16(BytesBuilder builder, int? value) {
    if (value != null) {
      builder.addByte(1);
      _addInt16(builder, value);
    } else {
      builder.addByte(0);
    }
  }

  void _addOptionalFloat32(BytesBuilder builder, double? value) {
    if (value != null) {
      builder.addByte(1);
      _addFloat32(builder, value);
    } else {
      builder.addByte(0);
    }
  }

  void _addDoubleList(BytesBuilder builder, List<double> list) {
    if (list.length > 255) {
      throw const FormatException('List too long (max 255 elements)');
    }
    builder.addByte(list.length);
    for (final value in list) {
      _addFloat32(builder, value);
    }
  }

  /// Cleans float32 noise when converting back to double.
  ///
  /// Since float32 is lower precision, 1.2 might become 1.2000000476837158.
  /// This rounds it to 5 decimal places for clean equality checks.
  double _cleanFloat32(double value) {
    return double.parse(value.toStringAsFixed(5));
  }
}
