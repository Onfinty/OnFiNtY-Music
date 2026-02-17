import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _hiddenSongsKey = 'hidden_songs';
  static const String _favoriteSongsKey = 'favorite_songs';
  static const String _favoriteAlbumsKey = 'favorite_albums';
  static const String _lastScanTimeKey = 'last_scan_time';
  static const String _themeModeKey = 'theme_mode';
  static const String _dynamicArtThemeKey = 'dynamic_art_theme';
  static const String _artworkPaletteCacheKey = 'artwork_palette_cache_v1';

  static SharedPreferences? _prefsInstance;

  static Future<void> initialize() async {
    try {
      _prefsInstance = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('Error initializing SharedPreferences: $e');
    }
  }

  static Future<SharedPreferences?> _getPrefs() async {
    if (_prefsInstance != null) {
      return _prefsInstance;
    }

    try {
      _prefsInstance = await SharedPreferences.getInstance();
      return _prefsInstance;
    } catch (e) {
      debugPrint('Error getting SharedPreferences: $e');
      return null;
    }
  }

  // Hidden Songs
  static Future<List<int>> getHiddenSongs() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return [];

      final List<String>? hiddenList = prefs.getStringList(_hiddenSongsKey);
      if (hiddenList == null) return [];
      return hiddenList.map((e) => int.parse(e)).toList();
    } catch (e) {
      debugPrint('Error getting hidden songs: $e');
      return [];
    }
  }

  static Future<bool> saveHiddenSongs(List<int> hiddenSongs) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return false;

      final List<String> stringList = hiddenSongs
          .map((e) => e.toString())
          .toList();
      return await prefs.setStringList(_hiddenSongsKey, stringList);
    } catch (e) {
      debugPrint('Error saving hidden songs: $e');
      return false;
    }
  }

  static Future<bool> hideSong(int songId) async {
    try {
      final hiddenSongs = await getHiddenSongs();
      if (!hiddenSongs.contains(songId)) {
        hiddenSongs.add(songId);
        return await saveHiddenSongs(hiddenSongs);
      }
      return true;
    } catch (e) {
      debugPrint('Error hiding song: $e');
      return false;
    }
  }

  static Future<bool> unhideSong(int songId) async {
    try {
      final hiddenSongs = await getHiddenSongs();
      hiddenSongs.remove(songId);
      return await saveHiddenSongs(hiddenSongs);
    } catch (e) {
      debugPrint('Error unhiding song: $e');
      return false;
    }
  }

  static Future<bool> clearHiddenSongs() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return false;
      return await prefs.remove(_hiddenSongsKey);
    } catch (e) {
      debugPrint('Error clearing hidden songs: $e');
      return false;
    }
  }

  // Favorite Songs
  static Future<List<int>> getFavoriteSongs() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return [];

      final List<String>? favoriteList = prefs.getStringList(_favoriteSongsKey);
      if (favoriteList == null) return [];
      return favoriteList.map((e) => int.parse(e)).toList();
    } catch (e) {
      debugPrint('Error getting favorite songs: $e');
      return [];
    }
  }

  static Future<bool> saveFavoriteSongs(List<int> favoriteSongs) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return false;

      final List<String> stringList = favoriteSongs
          .map((e) => e.toString())
          .toList();
      return await prefs.setStringList(_favoriteSongsKey, stringList);
    } catch (e) {
      debugPrint('Error saving favorite songs: $e');
      return false;
    }
  }

  static Future<bool> toggleFavorite(int songId) async {
    try {
      final favorites = await getFavoriteSongs();
      if (favorites.contains(songId)) {
        favorites.remove(songId);
      } else {
        favorites.add(songId);
      }
      return await saveFavoriteSongs(favorites);
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }

  // Favorite Albums
  static Future<List<String>> getFavoriteAlbums() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return [];

      final List<String>? favoriteList = prefs.getStringList(
        _favoriteAlbumsKey,
      );
      return favoriteList ?? [];
    } catch (e) {
      debugPrint('Error getting favorite albums: $e');
      return [];
    }
  }

  static Future<bool> saveFavoriteAlbums(List<String> favoriteAlbums) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return false;

      return await prefs.setStringList(_favoriteAlbumsKey, favoriteAlbums);
    } catch (e) {
      debugPrint('Error saving favorite albums: $e');
      return false;
    }
  }

  static Future<bool> toggleFavoriteAlbum(String albumId) async {
    try {
      final favorites = await getFavoriteAlbums();
      if (favorites.contains(albumId)) {
        favorites.remove(albumId);
      } else {
        favorites.add(albumId);
      }
      return await saveFavoriteAlbums(favorites);
    } catch (e) {
      debugPrint('Error toggling favorite album: $e');
      return false;
    }
  }

  // Last Scan Time
  static Future<DateTime?> getLastScanTime() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return null;

      final String? timeString = prefs.getString(_lastScanTimeKey);
      if (timeString == null) return null;
      return DateTime.parse(timeString);
    } catch (e) {
      debugPrint('Error getting last scan time: $e');
      return null;
    }
  }

  static Future<bool> saveLastScanTime(DateTime time) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return false;

      return await prefs.setString(_lastScanTimeKey, time.toIso8601String());
    } catch (e) {
      debugPrint('Error saving last scan time: $e');
      return false;
    }
  }

  // Theme Mode
  static Future<bool> getIsDarkMode() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return true; // Default to dark
      return prefs.getBool(_themeModeKey) ?? true;
    } catch (e) {
      debugPrint('Error getting theme mode: $e');
      return true;
    }
  }

  static Future<bool> saveIsDarkMode(bool isDark) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return false;
      return await prefs.setBool(_themeModeKey, isDark);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
      return false;
    }
  }

  // Dynamic Artwork Theme
  static Future<bool> getUseDynamicArtworkTheme() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return false;
      return prefs.getBool(_dynamicArtThemeKey) ?? false;
    } catch (e) {
      debugPrint('Error getting dynamic artwork theme: $e');
      return false;
    }
  }

  static Future<bool> saveUseDynamicArtworkTheme(bool enabled) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return false;
      return await prefs.setBool(_dynamicArtThemeKey, enabled);
    } catch (e) {
      debugPrint('Error saving dynamic artwork theme: $e');
      return false;
    }
  }

  // Artwork Palette Cache
  static Future<Map<int, Map<String, int>>> getArtworkPaletteCache() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) {
        return <int, Map<String, int>>{};
      }

      final raw = prefs.getString(_artworkPaletteCacheKey);
      if (raw == null || raw.isEmpty) {
        return <int, Map<String, int>>{};
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return <int, Map<String, int>>{};
      }

      final parsed = <int, Map<String, int>>{};
      for (final entry in decoded.entries) {
        final songId = int.tryParse(entry.key);
        final value = entry.value;
        if (songId == null || value is! Map<String, dynamic>) {
          continue;
        }

        final glow = value['glow'];
        final primary = value['primary'];
        final secondary = value['secondary'];
        if (glow is int && primary is int && secondary is int) {
          parsed[songId] = <String, int>{
            'glow': glow,
            'primary': primary,
            'secondary': secondary,
          };
        }
      }

      return parsed;
    } catch (e) {
      debugPrint('Error reading artwork palette cache: $e');
      return <int, Map<String, int>>{};
    }
  }

  static Future<bool> saveArtworkPaletteCache(
    Map<int, Map<String, int>> cache,
  ) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) {
        return false;
      }

      final serializable = <String, Map<String, int>>{};
      for (final entry in cache.entries) {
        final value = entry.value;
        final glow = value['glow'];
        final primary = value['primary'];
        final secondary = value['secondary'];
        if (glow == null || primary == null || secondary == null) {
          continue;
        }

        serializable[entry.key.toString()] = <String, int>{
          'glow': glow,
          'primary': primary,
          'secondary': secondary,
        };
      }

      return await prefs.setString(
        _artworkPaletteCacheKey,
        jsonEncode(serializable),
      );
    } catch (e) {
      debugPrint('Error saving artwork palette cache: $e');
      return false;
    }
  }

  static Future<bool> clearArtworkPaletteCache() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) {
        return false;
      }
      return await prefs.remove(_artworkPaletteCacheKey);
    } catch (e) {
      debugPrint('Error clearing artwork palette cache: $e');
      return false;
    }
  }

  // Clear All
  static Future<bool> clearAll() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return false;
      return await prefs.clear();
    } catch (e) {
      debugPrint('Error clearing preferences: $e');
      return false;
    }
  }
}
