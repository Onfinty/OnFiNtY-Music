import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _hiddenSongsKey = 'hidden_songs';
  static const String _favoriteSongsKey = 'favorite_songs';
  static const String _favoriteAlbumsKey = 'favorite_albums';
  static const String _lastScanTimeKey = 'last_scan_time';

  static SharedPreferences? _prefsInstance;

  static Future<void> initialize() async {
    try {
      _prefsInstance = await SharedPreferences.getInstance();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
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
      print('Error getting SharedPreferences: $e');
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
      print('Error getting hidden songs: $e');
      return [];
    }
  }

  static Future<bool> saveHiddenSongs(List<int> hiddenSongs) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return false;
      
      final List<String> stringList = hiddenSongs.map((e) => e.toString()).toList();
      return await prefs.setStringList(_hiddenSongsKey, stringList);
    } catch (e) {
      print('Error saving hidden songs: $e');
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
      print('Error hiding song: $e');
      return false;
    }
  }

  static Future<bool> unhideSong(int songId) async {
    try {
      final hiddenSongs = await getHiddenSongs();
      hiddenSongs.remove(songId);
      return await saveHiddenSongs(hiddenSongs);
    } catch (e) {
      print('Error unhiding song: $e');
      return false;
    }
  }

  static Future<bool> clearHiddenSongs() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return false;
      return await prefs.remove(_hiddenSongsKey);
    } catch (e) {
      print('Error clearing hidden songs: $e');
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
      print('Error getting favorite songs: $e');
      return [];
    }
  }

  static Future<bool> saveFavoriteSongs(List<int> favoriteSongs) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return false;
      
      final List<String> stringList = favoriteSongs.map((e) => e.toString()).toList();
      return await prefs.setStringList(_favoriteSongsKey, stringList);
    } catch (e) {
      print('Error saving favorite songs: $e');
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
      print('Error toggling favorite: $e');
      return false;
    }
  }

  // Favorite Albums
  static Future<List<String>> getFavoriteAlbums() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return [];
      
      final List<String>? favoriteList = prefs.getStringList(_favoriteAlbumsKey);
      return favoriteList ?? [];
    } catch (e) {
      print('Error getting favorite albums: $e');
      return [];
    }
  }

  static Future<bool> saveFavoriteAlbums(List<String> favoriteAlbums) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return false;
      
      return await prefs.setStringList(_favoriteAlbumsKey, favoriteAlbums);
    } catch (e) {
      print('Error saving favorite albums: $e');
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
      print('Error toggling favorite album: $e');
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
      print('Error getting last scan time: $e');
      return null;
    }
  }

  static Future<bool> saveLastScanTime(DateTime time) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return false;
      
      return await prefs.setString(_lastScanTimeKey, time.toIso8601String());
    } catch (e) {
      print('Error saving last scan time: $e');
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
      print('Error clearing preferences: $e');
      return false;
    }
  }
}