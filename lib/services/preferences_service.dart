import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _hiddenSongsKey = 'hidden_songs';
  static const String _favoriteSongsKey = 'favorite_songs';
  static const String _lastPlayingSongKey = 'last_playing_song';
  static const String _playbackPositionKey = 'playback_position';

  // Cache the SharedPreferences instance to avoid repeated async calls
  static SharedPreferences? _prefsInstance;

  // Initialize preferences - call this in main()
  static Future<void> initialize() async {
    try {
      _prefsInstance = await SharedPreferences.getInstance();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      // Continue without preferences if initialization fails
    }
  }

  // Get SharedPreferences instance with error handling
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

  // Get hidden songs list
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

  // Save hidden songs list
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

  // Add song to hidden list
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

  // Remove song from hidden list
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

  // Get favorite songs list
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

  // Save favorite songs list
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

  // Toggle favorite
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

  // Clear all preferences
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

  // Clear only hidden songs
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
}