import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import '../models/song_model.dart';
import '../services/audio_service.dart';

// Audio query instance
final audioQueryProvider = Provider((ref) => OnAudioQuery());

// All songs provider
final songsProvider = FutureProvider<List<SongModel>>((ref) async {
  final audioQuery = ref.watch(audioQueryProvider);
  
  final songs = await audioQuery.querySongs(
    sortType: SongSortType.TITLE,
    orderType: OrderType.ASC_OR_SMALLER,
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
      return song.title.toLowerCase().startsWith(searchQuery) ||
             song.artist.toLowerCase().startsWith(searchQuery) ||
             song.album?.toLowerCase().startsWith(searchQuery) == true;
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

// Loop mode provider - using LoopMode from audio_service.dart
final loopModeProvider = StateProvider<LoopMode>((ref) => LoopMode.off);

// Playback speed provider
final playbackSpeedProvider = StateProvider<double>((ref) => 1.0);

// Favorites provider (simple list for now)
final favoritesProvider = StateProvider<List<int>>((ref) => []);