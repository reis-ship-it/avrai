// Knot 3D Export Service
// 
// Service for exporting 3D knots to various formats
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 1: 3D Knot Visualization and Conversion

import 'dart:developer' as developer;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:avrai_knot/models/knot/knot_3d.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/services/knot/knot_3d_converter_service.dart';

/// Service for exporting 3D knots to various formats
/// 
/// **Supported Formats:**
/// - OBJ (text-based, widely supported)
/// - STL (for 3D printing)
/// - glTF (for web/AR/VR)
class Knot3DExportService {
  static const String _logName = 'Knot3DExportService';

  final Knot3DConverterService _converterService;

  Knot3DExportService({
    Knot3DConverterService? converterService,
  }) : _converterService = converterService ?? Knot3DConverterService();

  /// Export knot to OBJ format
  /// 
  /// Returns the file path where OBJ was saved
  Future<String> exportToOBJ({
    required PersonalityKnot knot,
    String? filename,
  }) async {
    try {
      developer.log(
        'Exporting knot to OBJ: ${knot.agentId.substring(0, 10)}...',
        name: _logName,
      );

      // Convert to 3D
      final knot3d = _converterService.convertTo3D(knot);
      
      // Generate mesh
      final mesh = Knot3DMesh.generateMesh(knot3d: knot3d);
      
      // Export to OBJ
      final objContent = Knot3DExport.toOBJ(
        mesh,
        objectName: filename ?? 'knot_${knot.agentId.substring(0, 8)}',
      );
      
      // Save to file
      final file = await _getExportFile(
        filename: filename ?? 'knot_${knot.agentId.substring(0, 8)}.obj',
      );
      
      await file.writeAsString(objContent);
      
      developer.log(
        '✅ Exported OBJ to: ${file.path}',
        name: _logName,
      );
      
      return file.path;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to export OBJ: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Export knot to STL format
  /// 
  /// Returns the file path where STL was saved
  Future<String> exportToSTL({
    required PersonalityKnot knot,
    String? filename,
  }) async {
    try {
      developer.log(
        'Exporting knot to STL: ${knot.agentId.substring(0, 10)}...',
        name: _logName,
      );

      // Convert to 3D
      final knot3d = _converterService.convertTo3D(knot);
      
      // Generate mesh
      final mesh = Knot3DMesh.generateMesh(knot3d: knot3d);
      
      // Export to STL
      final stlContent = Knot3DExport.toSTL(
        mesh,
        solidName: filename ?? 'knot_${knot.agentId.substring(0, 8)}',
      );
      
      // Save to file
      final file = await _getExportFile(
        filename: filename ?? 'knot_${knot.agentId.substring(0, 8)}.stl',
      );
      
      await file.writeAsString(stlContent);
      
      developer.log(
        '✅ Exported STL to: ${file.path}',
        name: _logName,
      );
      
      return file.path;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to export STL: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Export knot to glTF format (JSON)
  /// 
  /// Returns the file path where glTF was saved
  Future<String> exportToGLTF({
    required PersonalityKnot knot,
    String? filename,
  }) async {
    try {
      developer.log(
        'Exporting knot to glTF: ${knot.agentId.substring(0, 10)}...',
        name: _logName,
      );

      // Convert to 3D
      final knot3d = _converterService.convertTo3D(knot);
      
      // Generate mesh
      final mesh = Knot3DMesh.generateMesh(knot3d: knot3d);
      
      // Export to glTF (returns Map, need to convert to JSON)
      final gltfData = Knot3DExport.toGLTF(
        mesh,
        name: filename ?? 'knot_${knot.agentId.substring(0, 8)}',
      );
      
      // Convert to JSON string
      final jsonContent = _mapToJsonString(gltfData);
      
      // Save to file
      final file = await _getExportFile(
        filename: filename ?? 'knot_${knot.agentId.substring(0, 8)}.gltf',
      );
      
      await file.writeAsString(jsonContent);
      
      developer.log(
        '✅ Exported glTF to: ${file.path}',
        name: _logName,
      );
      
      return file.path;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to export glTF: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Get export file path
  Future<File> _getExportFile({required String filename}) async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/knot_exports');
    
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    
    return File('${exportDir.path}/$filename');
  }

  /// Convert Map to JSON string (simple implementation)
  String _mapToJsonString(Map<String, dynamic> map) {
    final buffer = StringBuffer();
    buffer.writeln('{');
    
    final entries = map.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final isLast = i == entries.length - 1;
      
      buffer.write('  "${entry.key}": ');
      
      if (entry.value is Map) {
        buffer.writeln('{');
        _writeMapContent(buffer, entry.value as Map<String, dynamic>, 2);
        buffer.write('  }');
      } else if (entry.value is List) {
        buffer.write('[');
        _writeListContent(buffer, entry.value as List);
        buffer.write(']');
      } else if (entry.value is String) {
        buffer.write('"${entry.value}"');
      } else {
        buffer.write(entry.value.toString());
      }
      
      if (!isLast) {
        buffer.writeln(',');
      } else {
        buffer.writeln();
      }
    }
    
    buffer.writeln('}');
    return buffer.toString();
  }

  void _writeMapContent(StringBuffer buffer, Map<String, dynamic> map, int indent) {
    final indentStr = ' ' * indent;
    final entries = map.entries.toList();
    
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final isLast = i == entries.length - 1;
      
      buffer.write('$indentStr"${entry.key}": ');
      
      if (entry.value is Map) {
        buffer.writeln('{');
        _writeMapContent(buffer, entry.value as Map<String, dynamic>, indent + 2);
        buffer.write('$indentStr}');
      } else if (entry.value is List) {
        buffer.write('[');
        _writeListContent(buffer, entry.value as List);
        buffer.write(']');
      } else if (entry.value is String) {
        buffer.write('"${entry.value}"');
      } else {
        buffer.write(entry.value.toString());
      }
      
      if (!isLast) {
        buffer.writeln(',');
      } else {
        buffer.writeln();
      }
    }
  }

  void _writeListContent(StringBuffer buffer, List list) {
    for (int i = 0; i < list.length; i++) {
      if (i > 0) buffer.write(', ');
      
      if (list[i] is Map) {
        buffer.write('{');
        _writeMapContent(buffer, list[i] as Map<String, dynamic>, 0);
        buffer.write('}');
      } else if (list[i] is String) {
        buffer.write('"${list[i]}"');
      } else {
        buffer.write(list[i].toString());
      }
    }
  }
}
