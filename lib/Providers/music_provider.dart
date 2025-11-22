import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import '../models/song_model.dart';
import '../services/audio_service.dart';
import '../services/preferences_service.dart';

// Audio query instance
final audioQueryProvider = Provider((ref) => OnAudioQuery());

// All songs provider - sorted by date added (newest first)
final songsProvider = FutureProvider<List<SongModel>>((ref) async {
  final audioQuery = ref.watch(audioQueryProvider);
  
  final songs = await audioQuery.querySongs(
    sortType: SongSortType.DATE_ADDED,
    orderType: OrderType.DESC_OR_GREATER,
    uriType: UriType.EXTERNAL,
    ignoreCase: true,
  );
  
  return songs.map((song) => SongModel.fromOnAudioQuery(song)).toList();
});

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered songs based on search
final filteredSongsProvider = Provider<AsyncValue<List<SongModel>>>((ref) {
  final songsAsync = ref.watch(songsProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  
  return songsAsync.whenData((songs) {
    if (searchQuery.isEmpty) {
      return songs;
    }
    
    return songs.where((song) {
      return song.title.toLowerCase().contains(searchQuery) ||
             song.artist.toLowerCase().contains(searchQuery) ||
             (song.album?.toLowerCase().contains(searchQuery) ?? false);
    }).toList();
  });
});

// Audio service provider
final audioServiceProvider = Provider((ref) => AudioPlayerService());

// Current playing song provider
final currentSongProvider = StateProvider<SongModel?>((ref) => null);

// Is playing provider
final isPlayingProvider = StateProvider<bool>((ref) => false);

// Current position provider
final currentPositionProvider = StateProvider<Duration>((ref) => Duration.zero);

// Current duration provider
final currentDurationProvider = StateProvider<Duration>((ref) => Duration.zero);

// Loop mode provider
final loopModeProvider = StateProvider<LoopMode>((ref) => LoopMode.off);

// Playback speed provider
final playbackSpeedProvider = StateProvider<double>((ref) => 1.0);

// Favorites provider with SharedPreferences
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<int>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<List<int>> {
  FavoritesNotifier() : super([]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    state = await PreferencesService.getFavoriteSongs();
  }

  Future<void> toggleFavorite(int songId) async {
    await PreferencesService.toggleFavorite(songId);
    state = await PreferencesService.getFavoriteSongs();
  }
}

// Hidden songs provider with SharedPreferences
final hiddenSongsProvider = StateNotifierProvider<HiddenSongsNotifier, List<int>>((ref) {
  return HiddenSongsNotifier();
});

class HiddenSongsNotifier extends StateNotifier<List<int>> {
  HiddenSongsNotifier() : super([]) {
    _loadHiddenSongs();
  }

  Future<void> _loadHiddenSongs() async {
    state = await PreferencesService.getHiddenSongs();
  }

  Future<void> toggleHidden(int songId) async {
    if (state.contains(songId)) {
      await PreferencesService.unhideSong(songId);
    } else {
      await PreferencesService.hideSong(songId);
    }
    state = await PreferencesService.getHiddenSongs();
  }

  Future<void> clearAll() async {
    await PreferencesService.clearHiddenSongs();
    state = [];
  }
}