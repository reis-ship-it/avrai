// Visualization Style Tests
//
// Unit tests for visualization style models
// Part of 3D Visualization System
// Patent #31: Topological Knot Theory for Personality Representation

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/misc/visualization_style.dart';

void main() {
  group('KnotVisualizationStyle', () {
    test('should create default metallic style', () {
      final style = KnotVisualizationStyle.metallic();

      expect(style.type, equals('metallic'));
      expect(style.primaryColor, equals(0x00FF66)); // AppColors.electricGreen
      expect(style.emissiveIntensity, equals(0.1));
      expect(style.glowIntensity, equals(0.3));
      expect(style.lod, equals(VisualizationLOD.medium));
    });

    test('should create glowing style for meditation', () {
      final style = KnotVisualizationStyle.glowing();

      expect(style.type, equals('glowing'));
      expect(style.emissiveIntensity, equals(0.5));
      expect(style.glowIntensity, equals(0.8));
    });

    test('should create translucent style', () {
      final style = KnotVisualizationStyle.translucent();

      expect(style.type, equals('translucent'));
      expect(style.emissiveIntensity, equals(0.2));
      expect(style.glowIntensity, equals(0.4));
    });

    test('should create profile icon style with auto-rotate', () {
      final style = KnotVisualizationStyle.profileIcon();

      expect(style.type, equals('metallic'));
      expect(style.lod, equals(VisualizationLOD.low));
      expect(style.autoRotate, isTrue);
      expect(style.autoRotateSpeed, equals(0.3));
    });

    test('should create birth experience style with maximum glow', () {
      final style = KnotVisualizationStyle.birthExperience();

      expect(style.type, equals('glowing'));
      expect(style.emissiveIntensity, equals(0.7));
      expect(style.glowIntensity, equals(1.0));
      expect(style.lod, equals(VisualizationLOD.high));
    });

    test('should serialize to JSON correctly', () {
      final style = KnotVisualizationStyle(
        type: 'metallic',
        primaryColor: 0xFF0000,
        secondaryColor: 0x00FF00,
        emissiveIntensity: 0.5,
        glowIntensity: 0.8,
        lod: VisualizationLOD.high,
        autoRotate: true,
        autoRotateSpeed: 1.5,
      );

      final json = style.toJson();

      expect(json['type'], equals('metallic'));
      expect(json['primaryColor'], equals(0xFF0000));
      expect(json['secondaryColor'], equals(0x00FF00));
      expect(json['emissiveIntensity'], equals(0.5));
      expect(json['glowIntensity'], equals(0.8));
      expect(json['lod'], equals('high'));
      expect(json['autoRotate'], isTrue);
      expect(json['autoRotateSpeed'], equals(1.5));
    });

    test('should create copy with updated fields', () {
      final original = KnotVisualizationStyle.metallic();
      final copy = original.copyWith(
        type: 'glowing',
        emissiveIntensity: 0.9,
      );

      expect(copy.type, equals('glowing'));
      expect(copy.emissiveIntensity, equals(0.9));
      // Unchanged fields
      expect(copy.primaryColor, equals(original.primaryColor));
      expect(copy.lod, equals(original.lod));
    });
  });

  group('FabricVisualizationStyle', () {
    test('should create default woven style', () {
      final style = FabricVisualizationStyle.woven();

      expect(style.strandRadius, equals(0.05));
      expect(style.showWeave, isTrue);
      expect(style.glowIntensity, equals(0.3));
      expect(style.lod, equals(VisualizationLOD.medium));
    });

    test('should serialize to JSON correctly', () {
      final style = FabricVisualizationStyle(
        strandRadius: 0.08,
        showWeave: false,
        highlightColor: 0xFFFFFF,
        glowIntensity: 0.5,
        lod: VisualizationLOD.high,
      );

      final json = style.toJson();

      expect(json['strandRadius'], equals(0.08));
      expect(json['showWeave'], isFalse);
      expect(json['highlightColor'], equals(0xFFFFFF));
      expect(json['glowIntensity'], equals(0.5));
      expect(json['lod'], equals('high'));
    });
  });

  group('WorldsheetVisualizationStyle', () {
    test('should create default flowing style', () {
      final style = WorldsheetVisualizationStyle.flowing();

      expect(style.primaryColor, equals(0x00FF66));
      expect(style.transparency, equals(0.3));
      expect(style.showWireframe, isTrue);
      expect(style.wireframeOpacity, equals(0.1));
    });

    test('should serialize to JSON correctly', () {
      final style = WorldsheetVisualizationStyle(
        primaryColor: 0xFF0000,
        secondaryColor: 0x00FF00,
        transparency: 0.5,
        showWireframe: true,
        wireframeOpacity: 0.2,
        glowIntensity: 0.6,
        lod: VisualizationLOD.low,
      );

      final json = style.toJson();

      expect(json['primaryColor'], equals(0xFF0000));
      expect(json['secondaryColor'], equals(0x00FF00));
      expect(json['transparency'], equals(0.5));
      expect(json['showWireframe'], isTrue);
      expect(json['wireframeOpacity'], equals(0.2));
      expect(json['glowIntensity'], equals(0.6));
      expect(json['lod'], equals('low'));
    });
  });

  group('NetworkVisualizationStyle', () {
    test('should create default scifi style', () {
      final style = NetworkVisualizationStyle.scifi();

      expect(style.nodeColor, equals(0x00FF66));
      expect(style.edgeColor, equals(0x00FF66));
      expect(style.centerColor, equals(0xFFFFFF));
      expect(style.showFlow, isTrue);
      expect(style.glowIntensity, equals(0.6));
    });

    test('should serialize to JSON correctly', () {
      final style = NetworkVisualizationStyle(
        nodeColor: 0xFF0000,
        edgeColor: 0x00FF00,
        centerColor: 0x0000FF,
        edgeOpacity: 0.7,
        showFlow: false,
        glowIntensity: 0.8,
      );

      final json = style.toJson();

      expect(json['nodeColor'], equals(0xFF0000));
      expect(json['edgeColor'], equals(0x00FF00));
      expect(json['centerColor'], equals(0x0000FF));
      expect(json['edgeOpacity'], equals(0.7));
      expect(json['showFlow'], isFalse);
      expect(json['glowIntensity'], equals(0.8));
    });
  });

  group('VisualizationStyleFactory', () {
    test('should create knot style from brand colors', () {
      final style = VisualizationStyleFactory.knotFromBrand();

      expect(style.primaryColor, equals(0x00FF66));
      expect(style.secondaryColor, equals(0x66FF99));
    });

    test('should create fabric style from brand colors', () {
      final style = VisualizationStyleFactory.fabricFromBrand();

      expect(style.highlightColor, equals(0xFFFFFF));
    });

    test('should create worldsheet style from brand colors', () {
      final style = VisualizationStyleFactory.worldsheetFromBrand();

      expect(style.primaryColor, equals(0x00FF66));
      expect(style.secondaryColor, equals(0x66FF99));
    });

    test('should create network style from brand colors', () {
      final style = VisualizationStyleFactory.networkFromBrand();

      expect(style.nodeColor, equals(0x00FF66));
      expect(style.edgeColor, equals(0x00FF66));
      expect(style.centerColor, equals(0xFFFFFF));
    });
  });
}
