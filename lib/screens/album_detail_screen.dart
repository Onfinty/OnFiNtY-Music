import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Colors.black,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.5),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.5),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
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
                      child: const Icon(
                        Icons.album,
                        size: 120,
                        color: Color(0xFF8B5CF6),
                      ),
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
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black,
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
                          album.album,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          album.artist ?? 'Unknown Artist',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 18,
                            shadows: const [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${album.numOfSongs} songs',
                          style: TextStyle(
                            color: Colors.grey[500],
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
                  .where((song) =>
                      !hiddenSongs.contains(song.id) && song.duration >= 60000)
                  .toList();

              if (visibleSongs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_off, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No songs in this album',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return SongTile(
                        song: visibleSongs[index],
                        onTap: () async {
                          ref.read(currentSongProvider.notifier).state =
                              visibleSongs[index];
                          final audioService = ref.read(audioServiceProvider);
                          await audioService.setPlaylist(visibleSongs, index);
                          await audioService.play();
                          ref.read(isPlayingProvider.notifier).state = true;

                          if (context.mounted) {
                            context.push('/player', extra: visibleSongs[index]);
                          }
                        },
                        onLongPress: () {
                          _showSongOptions(context, ref, visibleSongs[index]);
                        },
                      );
                    },
                    childCount: visibleSongs.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF8B5CF6),
                ),
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

  void _showSongOptions(BuildContext context, WidgetRef ref, SongModel song) {
    final hiddenSongs = ref.read(hiddenSongsProvider);
    final isHidden = hiddenSongs.contains(song.id);

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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1A1A).withValues(alpha: 0.95),
                    const Color(0xFF2D2D2D).withValues(alpha: 0.95),
                  ],
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
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
                        color: Colors.grey[600],
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
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        ref
                            .read(hiddenSongsProvider.notifier)
                            .toggleHidden(song.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                isHidden ? 'Song unhidden' : 'Song hidden'),
                            backgroundColor: const Color(0xFF8B5CF6),
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