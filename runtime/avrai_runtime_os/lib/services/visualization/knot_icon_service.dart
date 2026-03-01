// Knot Icon Service
//
// Service for managing dynamic app icons based on the user's personality knot.
// Maps knot characteristics to predefined archetype icons.
//
// Features:
// - Map knot invariants to archetype
// - Set alternate app icon on iOS
// - Track current icon state
//
// Usage:
//   final service = KnotIconService();
//   await service.setIconForKnot(knot);

import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:avrai_core/models/personality_knot.dart';

/// Service for managing dynamic app icons based on the user's knot.
///
/// Maps the user's personality knot characteristics to predefined
/// archetype icons that can be set as the app icon on iOS.
class KnotIconService {
  static const String _logName = 'KnotIconService';

  /// Method channel for native icon operations
  static const MethodChannel _channel = MethodChannel('avra/app_icon');

  /// Singleton instance
  static final KnotIconService _instance = KnotIconService._internal();

  factory KnotIconService() => _instance;

  KnotIconService._internal();

  /// Available knot archetype icons
  /// These correspond to CFBundleAlternateIcons entries in Info.plist
  static const List<KnotArchetype> archetypes = [
    KnotArchetype(
      id: 'explorer',
      name: 'Explorer',
      description: 'Curious and adventurous spirit',
      crossingRange: (3, 5),
      writheRange: (-2, 2),
    ),
    KnotArchetype(
      id: 'connector',
      name: 'Connector',
      description: 'Natural bridge builder between people',
      crossingRange: (4, 6),
      writheRange: (-1, 1),
    ),
    KnotArchetype(
      id: 'creator',
      name: 'Creator',
      description: 'Imaginative and innovative thinker',
      crossingRange: (5, 8),
      writheRange: (1, 3),
    ),
    KnotArchetype(
      id: 'analyzer',
      name: 'Analyzer',
      description: 'Logical and detail-oriented mind',
      crossingRange: (6, 9),
      writheRange: (-3, -1),
    ),
    KnotArchetype(
      id: 'harmonizer',
      name: 'Harmonizer',
      description: 'Peaceful and balanced presence',
      crossingRange: (3, 4),
      writheRange: (0, 0),
    ),
    KnotArchetype(
      id: 'visionary',
      name: 'Visionary',
      description: 'Future-focused and inspiring',
      crossingRange: (7, 10),
      writheRange: (2, 4),
    ),
    KnotArchetype(
      id: 'guardian',
      name: 'Guardian',
      description: 'Protective and dependable',
      crossingRange: (4, 6),
      writheRange: (-2, 0),
    ),
    KnotArchetype(
      id: 'catalyst',
      name: 'Catalyst',
      description: 'Energizing and transformative',
      crossingRange: (5, 7),
      writheRange: (1, 2),
    ),
    KnotArchetype(
      id: 'sage',
      name: 'Sage',
      description: 'Wise and contemplative',
      crossingRange: (8, 12),
      writheRange: (-1, 1),
    ),
    KnotArchetype(
      id: 'maverick',
      name: 'Maverick',
      description: 'Bold and unconventional',
      crossingRange: (6, 8),
      writheRange: (3, 5),
    ),
    KnotArchetype(
      id: 'nurturer',
      name: 'Nurturer',
      description: 'Caring and supportive',
      crossingRange: (3, 5),
      writheRange: (0, 1),
    ),
    KnotArchetype(
      id: 'pioneer',
      name: 'Pioneer',
      description: 'Trailblazing and determined',
      crossingRange: (7, 9),
      writheRange: (1, 3),
    ),
    KnotArchetype(
      id: 'diplomat',
      name: 'Diplomat',
      description: 'Tactful and collaborative',
      crossingRange: (4, 5),
      writheRange: (-1, 0),
    ),
    KnotArchetype(
      id: 'artisan',
      name: 'Artisan',
      description: 'Skilled and meticulous craftsperson',
      crossingRange: (5, 6),
      writheRange: (0, 2),
    ),
    KnotArchetype(
      id: 'champion',
      name: 'Champion',
      description: 'Enthusiastic and inspiring leader',
      crossingRange: (6, 7),
      writheRange: (2, 3),
    ),
  ];

  /// Current archetype (null if using default icon)
  KnotArchetype? _currentArchetype;

  /// Get the current archetype
  KnotArchetype? get currentArchetype => _currentArchetype;

  /// Check if dynamic icons are supported on this platform
  Future<bool> get isSupported async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isSupported');
      return result ?? false;
    } catch (e) {
      developer.log(
        'Error checking icon support: $e',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  /// Get the current app icon name (null = default)
  Future<String?> get currentIconName async {
    if (!Platform.isIOS) return null;

    try {
      return await _channel.invokeMethod<String?>('getCurrentIcon');
    } catch (e) {
      developer.log(
        'Error getting current icon: $e',
        error: e,
        name: _logName,
      );
      return null;
    }
  }

  /// Set the app icon based on the user's knot
  ///
  /// Maps the knot's invariants to the closest archetype and sets
  /// the corresponding app icon.
  Future<bool> setIconForKnot(PersonalityKnot knot) async {
    if (!Platform.isIOS) return false;

    // Find the closest archetype
    final archetype = findClosestArchetype(knot);

    if (archetype == null) {
      developer.log(
        'No matching archetype found, keeping default icon',
        name: _logName,
      );
      return false;
    }

    return setIcon(archetype.id);
  }

  /// Set a specific archetype icon
  Future<bool> setIcon(String archetypeId) async {
    if (!Platform.isIOS) return false;

    try {
      final iconName = 'knot_$archetypeId';
      final result = await _channel.invokeMethod<bool>('setIcon', {
        'iconName': iconName,
      });

      if (result == true) {
        _currentArchetype = archetypes.firstWhere(
          (a) => a.id == archetypeId,
          orElse: () => archetypes.first,
        );
        developer.log(
          'App icon set to: $iconName',
          name: _logName,
        );
      }

      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Error setting app icon: ${e.message}',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  /// Reset to the default app icon
  Future<bool> resetToDefault() async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('resetIcon');

      if (result == true) {
        _currentArchetype = null;
        developer.log(
          'App icon reset to default',
          name: _logName,
        );
      }

      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Error resetting app icon: ${e.message}',
        error: e,
        name: _logName,
      );
      return false;
    }
  }

  /// Find the closest archetype for a given knot
  KnotArchetype? findClosestArchetype(PersonalityKnot knot) {
    final crossingNumber = knot.invariants.crossingNumber;
    final writhe = knot.invariants.writhe;

    KnotArchetype? bestMatch;
    double bestScore = double.infinity;

    for (final archetype in archetypes) {
      final score = archetype.distanceFrom(crossingNumber, writhe);
      if (score < bestScore) {
        bestScore = score;
        bestMatch = archetype;
      }
    }

    return bestMatch;
  }

  /// Get all available archetypes
  List<KnotArchetype> getAllArchetypes() => List.unmodifiable(archetypes);

  /// Get archetype by ID
  KnotArchetype? getArchetypeById(String id) {
    try {
      return archetypes.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Represents a knot archetype with associated icon
class KnotArchetype {
  /// Unique identifier (used in icon filename)
  final String id;

  /// Human-readable name
  final String name;

  /// Description of the personality type
  final String description;

  /// Expected crossing number range (min, max)
  final (int, int) crossingRange;

  /// Expected writhe range (min, max)
  final (int, int) writheRange;

  const KnotArchetype({
    required this.id,
    required this.name,
    required this.description,
    required this.crossingRange,
    required this.writheRange,
  });

  /// Calculate distance from given knot invariants
  ///
  /// Returns a score where lower is better (closer match)
  double distanceFrom(int crossingNumber, int writhe) {
    // Calculate how far the crossing number is from the range
    double crossingDistance = 0;
    if (crossingNumber < crossingRange.$1) {
      crossingDistance = (crossingRange.$1 - crossingNumber).toDouble();
    } else if (crossingNumber > crossingRange.$2) {
      crossingDistance = (crossingNumber - crossingRange.$2).toDouble();
    }

    // Calculate how far the writhe is from the range
    double writheDistance = 0;
    if (writhe < writheRange.$1) {
      writheDistance = (writheRange.$1 - writhe).toDouble();
    } else if (writhe > writheRange.$2) {
      writheDistance = (writhe - writheRange.$2).toDouble();
    }

    // Euclidean distance (weighted)
    return (crossingDistance * crossingDistance +
        writheDistance * writheDistance * 0.5);
  }

  /// Check if a knot matches this archetype
  bool matches(int crossingNumber, int writhe) {
    return crossingNumber >= crossingRange.$1 &&
        crossingNumber <= crossingRange.$2 &&
        writhe >= writheRange.$1 &&
        writhe <= writheRange.$2;
  }

  @override
  String toString() => 'KnotArchetype($id: $name)';
}
