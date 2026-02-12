import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/core/theme/map_themes.dart';

class MapThemeManager {
  static const String _themeKey = 'selected_map_theme';

  // Get the current theme from storage or default to SPOTS Blue
  static Future<MapTheme> getCurrentTheme() async {
    if (!di.sl.isRegistered<SharedPreferences>()) {
      return MapThemes.spotsBlue;
    }
    final prefs = di.sl<SharedPreferences>();
    final themeName = prefs.getString(_themeKey) ?? 'SPOTS Blue';

    return MapThemes.allThemes.firstWhere(
      (theme) => theme.name == themeName,
      orElse: () => MapThemes.spotsBlue,
    );
  }

  // Save the selected theme to storage
  static Future<void> setTheme(MapTheme theme) async {
    if (!di.sl.isRegistered<SharedPreferences>()) {
      return;
    }
    final prefs = di.sl<SharedPreferences>();
    await prefs.setString(_themeKey, theme.name);
  }

  // Get all available themes
  static List<MapTheme> getAllThemes() {
    return MapThemes.allThemes;
  }

  // Get theme by name
  static MapTheme? getThemeByName(String name) {
    try {
      return MapThemes.allThemes.firstWhere((theme) => theme.name == name);
    } catch (e) {
      return null;
    }
  }

  // Apply CSS filters to map tiles (for web)
  static String getCssFilterForTheme(MapTheme theme) {
    switch (theme.name) {
      case 'Dark':
        return 'brightness(0.7) contrast(1.3) saturate(0.8) invert(0.9) hue-rotate(180deg)';
      case 'Nature':
        return 'brightness(1.1) contrast(1.1) saturate(1.3) hue-rotate(120deg)';
      case 'Sunset':
        return 'brightness(1.2) contrast(1.2) saturate(1.4) hue-rotate(30deg)';
      case 'Purple':
        return 'brightness(1.1) contrast(1.1) saturate(1.3) hue-rotate(280deg)';
      case 'Minimalist':
        return 'brightness(1.05) contrast(1.05) saturate(0.9)';
      default: // SPOTS Blue
        return 'brightness(1.0) contrast(1.0) saturate(1.0)';
    }
  }

  // Get custom tile URL for themes (if available)
  static String? getCustomTileUrl(MapTheme theme, int z, int x, int y) {
    switch (theme.name) {
      case 'Dark':
        // You could use a dark-themed tile server here
        return null;
      case 'Nature':
        // You could use a nature-themed tile server here
        return null;
      default:
        return null;
    }
  }
}
