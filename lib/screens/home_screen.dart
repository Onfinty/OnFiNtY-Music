import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:fitapp/screens/album_detail_screen.dart';
import 'package:fitapp/widgets/cached_artwork_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import 'package:skeletonizer/skeletonizer.dart';

import '../models/song_model.dart';
import '../providers/music_provider.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_tile.dart';

enum MusicTab { songs, albums, hidden }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  MusicTab _currentTab = MusicTab.songs;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSongs = ref.watch(filteredSongsProvider);
    final currentSong = ref.watch(currentSongProvider);
    final hiddenSongs = ref.watch(hiddenSongsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'OnFiNtY',
          style: TextStyle(
            fontFamily: 'Lobster',
            fontSize: 32,
            color: Color(0xFF8B5CF6),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF8B5CF6)),
            onPressed: () {
              showSearch(context: context, delegate: MusicSearchDelegate(ref));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF8B5CF6)),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTabButton('Songs', MusicTab.songs),
                _buildTabButton('Albums', MusicTab.albums),
                _buildTabButton('Hidden', MusicTab.hidden),
              ],
            ),
          ),
          Expanded(child: _buildTabContent(filteredSongs, hiddenSongs)),
          if (currentSong != null)
            GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! < -500) {
                  // Swipe up
                  context.push('/player', extra: currentSong);
                }
              },
              child: const MiniPlayer(),
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, MusicTab tab) {
    final isSelected = _currentTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = tab;
          // Reset scroll position when switching tabs
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF8B5CF6),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
  AsyncValue<List<SongModel>> filteredSongs,
  List<int> hiddenSongs,
) {
  if (_currentTab == MusicTab.albums) {
    return _buildAlbumsView(); // Call the new albums view
  }

    return filteredSongs.when(
      data: (songs) {
        List<SongModel> displaySongs;

        if (_currentTab == MusicTab.hidden) {
          // Show only hidden songs
          displaySongs = songs
              .where(
                (song) =>
                    hiddenSongs.contains(song.id) || song.duration < 60000,
              )
              .toList();
        } else {
          // Show only non-hidden songs (excluding songs under 1 minute)
          displaySongs = songs
              .where(
                (song) =>
                    !hiddenSongs.contains(song.id) && song.duration >= 60000,
              )
              .toList();
        }

        if (displaySongs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_off, size: 80, color: Colors.grey[700]),
                const SizedBox(height: 20),
                Text(
                  _currentTab == MusicTab.hidden
                      ? 'No hidden songs'
                      : 'No music found on your phone',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Professional scrollbar with smooth scrolling
        return DraggableScrollbar.semicircle(
          controller: _scrollController,
          backgroundColor: const Color(0xFF8B5CF6),
          scrollbarTimeToFade: const Duration(seconds: 2),
          heightScrollThumb: 60.0,
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            itemCount: displaySongs.length,
            padding: const EdgeInsets.only(bottom: 100, right: 4),
            itemBuilder: (context, index) {
              return SongTile(
                song: displaySongs[index],
                onTap: () async {
                  // Set current song with the full list for proper navigation
                  final allSongs = _currentTab == MusicTab.hidden
                      ? displaySongs
                      : songs
                            .where(
                              (song) =>
                                  !hiddenSongs.contains(song.id) &&
                                  song.duration >= 60000,
                            )
                            .toList();

                  ref.read(currentSongProvider.notifier).state =
                      displaySongs[index];

                  // Setup playlist and play
                  final audioService = ref.read(audioServiceProvider);
                  await audioService.setPlaylist(allSongs, index);
                  await audioService.play();

                  ref.read(isPlayingProvider.notifier).state = true;

                  // Navigate to player
                  if (context.mounted) {
                    context.push('/player', extra: displaySongs[index]);
                  }
                },
                onLongPress: () {
                  _showSongOptions(context, displaySongs[index]);
                },
              );
            },
          ),
        );
      },
      loading: () {
        return Skeletonizer(
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Container(width: 50, height: 50, color: Colors.grey),
                title: const Text('Loading song title'),
                subtitle: const Text('Artist name'),
              );
            },
          ),
        );
      },
      error: (error, stack) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 60, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                'Error loading songs',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),
              Text(
                error.toString(),
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }


Widget _buildAlbumsView() {
  final albumsAsync = ref.watch(filteredAlbumsProvider);
  final favoriteAlbums = ref.watch(favoriteAlbumsProvider);
  
  return albumsAsync.when(
    data: (albums) {
      // Filter to show only favorite albums
      final displayAlbums = albums
          .where((album) => favoriteAlbums.contains(album.id.toString()))
          .toList();
      
      if (displayAlbums.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.album, size: 80, color: Colors.grey[700]),
              const SizedBox(height: 20),
              const Text(
                'No favorite albums yet',
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Go to all albums and favorite some!',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showAllAlbumsBottomSheet(),
                icon: const Icon(Icons.library_music),
                label: const Text('Browse All Albums'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      
      return GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: displayAlbums.length,
        itemBuilder: (context, index) {
          final album = displayAlbums[index];
          return _buildAlbumCard(album);
        },
      );
    },
    loading: () => const Center(
      child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
    ),
    error: (_, __) => const Center(
      child: Text('Error loading albums', style: TextStyle(color: Colors.grey)),
    ),
  );
}

Widget _buildAlbumCard(AlbumModel album) {
  final favoriteAlbums = ref.watch(favoriteAlbumsProvider);
  final isFavorite = favoriteAlbums.contains(album.id.toString());
  
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AlbumDetailScreen(album: album),
        ),
      );
    },
    onLongPress: () {
      ref
          .read(favoriteAlbumsProvider.notifier)
          .toggleFavoriteAlbum(album.id.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite ? 'Removed from favorites' : 'Added to favorites',
          ),
          backgroundColor: const Color(0xFF8B5CF6),
          duration: const Duration(seconds: 1),
        ),
      );
    },
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFavorite
              ? const Color(0xFF8B5CF6)
              : Colors.white.withValues(alpha: 0.1),
          width: isFavorite ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: CachedArtworkWidget(
                    id: album.id,
                    type: ArtworkType.ALBUM,
                    width: double.infinity,
                    height: double.infinity,
                    quality: 100,
                    fit: BoxFit.cover,
                    nullArtworkWidget: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                            const Color(0xFF6D28D9).withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.album,
                          size: 60,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                  ),
                ),
                if (isFavorite)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  album.album,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  album.artist ?? 'Unknown',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 12,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${album.numOfSongs} songs',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void _showAllAlbumsBottomSheet() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
            child: Container(
              color: Colors.black,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'All Albums',
                          style: TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lobster',
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final albumsAsync = ref.watch(albumsProvider);
                        return albumsAsync.when(
                          data: (albums) {
                            return GridView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: albums.length,
                              itemBuilder: (context, index) {
                                return _buildAlbumCard(albums[index]);
                              },
                            );
                          },
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                          error: (_, __) => const Center(
                            child: Text(
                              'Error loading albums',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}


  void _showSongOptions(BuildContext context, SongModel song) {
    final hiddenSongs = ref.read(hiddenSongsProvider);
    final isHidden = hiddenSongs.contains(song.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  ref.read(hiddenSongsProvider.notifier).toggleHidden(song.id);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isHidden ? 'Song unhidden' : 'Song hidden'),
                      backgroundColor: const Color(0xFF8B5CF6),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class MusicSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;
  final ScrollController _searchScrollController = ScrollController();

  MusicSearchDelegate(this.ref);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      scaffoldBackgroundColor: Colors.black,
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontFamily: 'Roboto',
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey, fontFamily: 'Roboto'),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: Colors.white),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        _searchScrollController.dispose();
        ref.read(searchQueryProvider.notifier).state = '';
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).state = query;
    });

    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).state = query;
    });

    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return Consumer(
      builder: (context, ref, child) {
        final filteredSongs = ref.watch(filteredSongsProvider);
        final hiddenSongs = ref.watch(hiddenSongsProvider);

        return filteredSongs.when(
          data: (songs) {
            final visibleSongs = songs
                .where(
                  (song) =>
                      !hiddenSongs.contains(song.id) && song.duration >= 60000,
                )
                .toList();

            if (visibleSongs.isEmpty) {
              return const Center(
                child: Text(
                  'No songs found',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return DraggableScrollbar.semicircle(
              controller: _searchScrollController,
              backgroundColor: const Color(0xFF8B5CF6),
              scrollbarTimeToFade: const Duration(seconds: 2),
              heightScrollThumb: 60.0,
              child: ListView.builder(
                controller: _searchScrollController,
                physics: const BouncingScrollPhysics(),
                itemCount: visibleSongs.length,
                padding: const EdgeInsets.only(right: 4),
                itemBuilder: (context, index) {
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
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
            child: Text('Error', style: TextStyle(color: Colors.grey)),
          ),
        );
      },
    );
  }
}
