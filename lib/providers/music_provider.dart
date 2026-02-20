import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/artwork_palette_service.dart';
import '../services/preferences_service.dart';

// Audio query instance
final audioQueryProvider = Provider((ref) => OnAudioQuery());
final artworkPaletteServiceProvider = Provider<ArtworkPaletteService>((ref) {
  return ArtworkPaletteService(audioQuery: ref.watch(audioQueryProvider));
});

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

// Albums provider
final albumsProvider = FutureProvider<List<AlbumModel>>((ref) async {
  final audioQuery = ref.watch(audioQueryProvider);
  return await audioQuery.queryAlbums(
    sortType: AlbumSortType.ALBUM,
    orderType: OrderType.ASC_OR_SMALLER,
    uriType: UriType.EXTERNAL,
    ignoreCase: true,
  );
});

// Songs by album provider
final songsByAlbumProvider = FutureProvider.family<List<SongModel>, String>((
  ref,
  albumId,
) async {
  if (albumId == '-1') {
    // Return all favorite songs for the virtual "Liked Songs" album
    final songsAsync = await ref.watch(songsProvider.future);
    final favoriteIds = ref.watch(favoritesProvider);
    return songsAsync.where((s) => favoriteIds.contains(s.id)).toList();
  }

  final audioQuery = ref.watch(audioQueryProvider);
  final songs = await audioQuery.queryAudiosFrom(
    AudiosFromType.ALBUM_ID,
    albumId,
    sortType: SongSortType.TITLE,
    orderType: OrderType.ASC_OR_SMALLER,
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

// Filtered albums based on search
final filteredAlbumsProvider = Provider<AsyncValue<List<AlbumModel>>>((ref) {
  final albumsAsync = ref.watch(albumsProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

  return albumsAsync.whenData((albums) {
    if (searchQuery.isEmpty) {
      return albums;
    }

    return albums.where((album) {
      return album.album.toLowerCase().contains(searchQuery) ||
          (album.artist?.toLowerCase().contains(searchQuery) ?? false);
    }).toList();
  });
});

// ============================================================================
// AUDIO HANDLER PROVIDER (Centralized — C-01, C-06, C-07, M-01)
// ============================================================================

/// The audio handler is initialized in main.dart via AudioService.init()
/// and passed as an override into ProviderScope.
final audioHandlerProvider = Provider<OnFinityAudioHandler>((ref) {
  throw UnimplementedError(
    'audioHandlerProvider must be overridden in ProviderScope with the '
    'initialized AudioHandler from main.dart',
  );
});

// ============================================================================
// CENTRALIZED AUDIO STATE PROVIDERS (Replaces duplicate stream listeners)
// ============================================================================

/// Current song — derived from AudioHandler mediaItem (stable across queue swaps)
final currentSongProvider = StreamProvider<SongModel?>((ref) {
  final handler = ref.watch(audioHandlerProvider);

  return handler.mediaItem
      .map((item) {
        if (item == null) {
          return null;
        }

        final extrasSongId = item.extras?['songId'];
        int? songId;
        if (extrasSongId is int) {
          songId = extrasSongId;
        } else if (extrasSongId is num) {
          songId = extrasSongId.toInt();
        } else if (extrasSongId is String) {
          songId = int.tryParse(extrasSongId);
        }

        if (songId != null) {
          for (final song in handler.songPlaylist) {
            if (song.id == songId) {
              return song;
            }
          }
        }

        // Fallback by URI if extras are missing.
        final mediaId = item.id;
        for (final song in handler.songPlaylist) {
          if (song.uri == mediaId) {
            return song;
          }
        }
        return null;
      })
      .distinct((previous, next) {
        if (identical(previous, next)) {
          return true;
        }
        return previous?.id == next?.id;
      });
});

/// Current index (kept separate for advanced UI/prefetch use)
final currentIndexProvider = StreamProvider<int?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.currentIndexStream.map((index) {
    if (index != null && index >= 0) {
      return index;
    }
    return null;
  });
});

/// Is playing — derived from audioHandler.playerStateStream
final isPlayingProvider = StreamProvider<bool>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.playerStateStream.map((state) => state.playing);
});

/// Current position — derived from audioHandler.positionStream
final currentPositionProvider = StreamProvider<Duration>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.positionStream;
});

/// Current duration — derived from audioHandler.durationStream
final currentDurationProvider = StreamProvider<Duration>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.durationStream.map((d) => d ?? Duration.zero);
});

// Loop mode provider (UI state, synced to handler on change)
final loopModeProvider = StateProvider<AudioServiceRepeatMode>(
  (ref) => AudioServiceRepeatMode.none,
);

// Playback speed provider
final playbackSpeedProvider = StateProvider<double>((ref) => 1.0);

// Audio effects state from handler (quick presets + EQ + reverb)
final audioEffectsProvider = StreamProvider<AudioEffectsState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.audioEffectsStateStream.distinct();
});

// Favorites provider with SharedPreferences
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<int>>((
  ref,
) {
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

  bool isFavorite(int songId) => state.contains(songId);
}

// Favorite Albums provider
final favoriteAlbumsProvider =
    StateNotifierProvider<FavoriteAlbumsNotifier, List<String>>((ref) {
      return FavoriteAlbumsNotifier();
    });

class FavoriteAlbumsNotifier extends StateNotifier<List<String>> {
  FavoriteAlbumsNotifier() : super([]) {
    _loadFavoriteAlbums();
  }

  Future<void> _loadFavoriteAlbums() async {
    state = await PreferencesService.getFavoriteAlbums();
  }

  Future<void> toggleFavoriteAlbum(String albumId) async {
    await PreferencesService.toggleFavoriteAlbum(albumId);
    state = await PreferencesService.getFavoriteAlbums();
  }

  bool isFavoriteAlbum(String albumId) => state.contains(albumId);
}

// Hidden songs provider with SharedPreferences
final hiddenSongsProvider =
    StateNotifierProvider<HiddenSongsNotifier, List<int>>((ref) {
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

// Library refresh trigger
final libraryRefreshProvider = StateProvider<int>((ref) => 0);

// Theme mode provider (persisted)
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<bool> {
  // state = true means dark mode (default)
  ThemeModeNotifier() : super(true) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    state = await PreferencesService.getIsDarkMode();
  }

  Future<void> toggle() async {
    state = !state;
    await PreferencesService.saveIsDarkMode(state);
  }

  Future<void> setDark(bool isDark) async {
    state = isDark;
    await PreferencesService.saveIsDarkMode(isDark);
  }
}

// Convenience provider
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeModeProvider);
});

// Dynamic artwork theme mode (persisted)
final dynamicArtworkThemeProvider =
    StateNotifierProvider<DynamicArtworkThemeNotifier, bool>((ref) {
      return DynamicArtworkThemeNotifier();
    });

class DynamicArtworkThemeNotifier extends StateNotifier<bool> {
  DynamicArtworkThemeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    state = await PreferencesService.getUseDynamicArtworkTheme();
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await PreferencesService.saveUseDynamicArtworkTheme(enabled);
  }
}

final artworkFullGradientThemeProvider =
    StateNotifierProvider<ArtworkFullGradientThemeNotifier, bool>((ref) {
      return ArtworkFullGradientThemeNotifier();
    });

class ArtworkFullGradientThemeNotifier extends StateNotifier<bool> {
  ArtworkFullGradientThemeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    state = await PreferencesService.getUseArtworkFullGradientTheme();
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await PreferencesService.saveUseArtworkFullGradientTheme(enabled);
  }
}

final currentThemePaletteProvider =
    StateNotifierProvider<CurrentThemePaletteNotifier, SongPalette>((ref) {
      return CurrentThemePaletteNotifier(ref);
    });

class CurrentThemePaletteNotifier extends StateNotifier<SongPalette> {
  CurrentThemePaletteNotifier(this._ref) : super(SongPalette.fallback) {
    _ref.listen<bool>(dynamicArtworkThemeProvider, (_, __) {
      unawaited(_syncPalette());
    });

    _ref.listen<AsyncValue<SongModel?>>(currentSongProvider, (_, __) {
      unawaited(_syncPalette());
    });

    unawaited(_syncPalette());
  }

  final Ref _ref;
  int _paletteRequestToken = 0;
  bool _isDisposed = false;

  Future<void> _syncPalette() async {
    final useDynamicTheme = _ref.read(dynamicArtworkThemeProvider);
    if (!useDynamicTheme) {
      _paletteRequestToken++;
      if (state != SongPalette.fallback) {
        state = SongPalette.fallback;
      }
      return;
    }

    final currentSong = _ref.read(currentSongProvider).value;
    if (currentSong == null) {
      // Keep the last palette while track metadata is transitioning.
      return;
    }

    final paletteService = _ref.read(artworkPaletteServiceProvider);
    final cached = paletteService.getCachedPalette(currentSong.id);
    if (cached != null && cached != state) {
      state = cached;
    }

    final token = ++_paletteRequestToken;
    try {
      final resolved = await paletteService.getPalette(currentSong.id);
      if (_isDisposed || token != _paletteRequestToken) {
        return;
      }
      if (resolved != state) {
        state = resolved;
      }
    } catch (_) {
      // Keep previous palette to avoid visual flicker.
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
