import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import '../models/song_model.dart';
import '../providers/music_provider.dart';
import '../widgets/song_tile.dart';
import '../widgets/cached_artwork_widget.dart';

class AlbumDetailScreen extends ConsumerWidget {
  final AlbumModel album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songsByAlbumProvider(album.id.toString()));
    final favoriteAlbums = ref.watch(favoriteAlbumsProvider);
    final hiddenSongs = ref.watch(hiddenSongsProvider);
    final isFavorite = favoriteAlbums.contains(album.id.toString());
    final isDark = ref.watch(isDarkModeProvider);

    final isLikedSongsAlbum = album.id == -1;

    final backgroundColor = isDark ? Colors.black : const Color(0xFFF8F7FC);
    final textColor = isDark ? Colors.white : const Color(0xFF1C1B1F);
    final appBarColor = isDark ? Colors.black : Colors.white;
    final iconColor = isDark
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: appBarColor,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? Colors.black : Colors.white).withValues(
                  alpha: 0.5,
                ),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.1,
                  ),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : const Color(0xFF1C1B1F),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              if (!isLikedSongsAlbum)
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? Colors.black : Colors.white).withValues(
                      alpha: 0.5,
                    ),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.1,
                      ),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? Colors.red
                          : (isDark ? Colors.white : const Color(0xFF1C1B1F)),
                    ),
                    onPressed: () {
                      ref
                          .read(favoriteAlbumsProvider.notifier)
                          .toggleFavoriteAlbum(album.id.toString());
                    },
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Album artwork background
                  if (isLikedSongsAlbum)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF8B5CF6),
                            const Color(0xFFEC4899), // Pinkish for favorites
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 140,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    )
                  else
                    CachedArtworkWidget(
                      id: album.id,
                      type: ArtworkType.ALBUM,
                      width: MediaQuery.of(context).size.width,
                      height: 350,
                      quality: 100,
                      fit: BoxFit.cover,
                      nullArtworkWidget: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                              const Color(0xFF6D28D9).withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                        child: Icon(Icons.album, size: 120, color: iconColor),
                      ),
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          backgroundColor.withValues(alpha: 0.7),
                          backgroundColor,
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                  ),
                  // Album info at bottom
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLikedSongsAlbum ? 'Liked Songs' : album.album,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: isDark
                                ? [
                                    const Shadow(
                                      color: Colors.black,
                                      blurRadius: 10,
                                    ),
                                  ]
                                : [],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLikedSongsAlbum
                              ? 'Your Favorites'
                              : (album.artist ?? 'Unknown Artist'),
                          style: TextStyle(
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                            fontSize: 18,
                            shadows: isDark
                                ? [
                                    const Shadow(
                                      color: Colors.black,
                                      blurRadius: 10,
                                    ),
                                  ]
                                : [],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isLikedSongsAlbum
                              ? 'Special Collection'
                              : '${album.numOfSongs} songs',
                          style: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          songsAsync.when(
            data: (songs) {
              // Filter out hidden songs
              final visibleSongs = songs
                  .where(
                    (song) =>
                        !hiddenSongs.contains(song.id) &&
                        song.duration >= 60000,
                  )
                  .toList();

              if (visibleSongs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLikedSongsAlbum
                              ? Icons.favorite_border
                              : Icons.music_off,
                          size: 60,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isLikedSongsAlbum
                              ? 'No favorite songs yet'
                              : 'No songs in this album',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return SongTile(
                      song: visibleSongs[index],
                      onTap: () async {
                        final selectedSong = visibleSongs[index];
                        final selectedIndex = visibleSongs.indexWhere(
                          (song) => song.id == selectedSong.id,
                        );
                        final startIndex = selectedIndex >= 0
                            ? selectedIndex
                            : 0;
                        final audioHandler = ref.read(audioHandlerProvider);
                        await audioHandler.setPlaylist(
                          visibleSongs,
                          startIndex,
                        );
                        await audioHandler.play();
                      },
                      onLongPress: () {
                        _showSongOptions(
                          context,
                          ref,
                          visibleSongs[index],
                          isDark,
                        );
                      },
                    );
                  }, childCount: visibleSongs.length),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
              ),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading songs',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSongOptions(
    BuildContext context,
    WidgetRef ref,
    SongModel song,
    bool isDark,
  ) {
    final hiddenSongs = ref.read(hiddenSongsProvider);
    final isHidden = hiddenSongs.contains(song.id);

    final bgColor = isDark
        ? const Color(0xFF1A1A1A).withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.95);
    final textColor = isDark ? Colors.white : const Color(0xFF1C1B1F);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  top: BorderSide(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.1,
                    ),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: Icon(
                        isHidden ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF8B5CF6),
                      ),
                      title: Text(
                        isHidden ? 'Unhide Song' : 'Hide Song',
                        style: TextStyle(color: textColor),
                      ),
                      onTap: () {
                        ref
                            .read(hiddenSongsProvider.notifier)
                            .toggleHidden(song.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isHidden ? 'Song unhidden' : 'Song hidden',
                            ),
                            backgroundColor: const Color(0xFF8B5CF6),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
