import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../providers/music_provider.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredSongs = ref.watch(filteredSongsProvider);
    final currentSong = ref.watch(currentSongProvider);

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
          Expanded(
            child: filteredSongs.when(
              data: (songs) {
                if (songs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_off,
                          size: 80,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No music found on your phone',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Add some music and refresh',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: songs.length,
                  padding: const EdgeInsets.only(bottom: 100),
                  itemBuilder: (context, index) {
                    return SongTile(
                      song: songs[index],
                      onTap: () async {
                        // Set current song
                        ref.read(currentSongProvider.notifier).state =
                            songs[index];

                        // Setup playlist and play
                        final audioService = ref.read(audioServiceProvider);
                        await audioService.setPlaylist(songs, index);
                        await audioService.play();

                        ref.read(isPlayingProvider.notifier).state = true;

                        // Navigate to player - check if mounted
                        if (context.mounted) {
                          context.push('/player', extra: songs[index]);
                        }
                      },
                    );
                  },
                );
              },
              loading: () {
                return Skeletonizer(
                  child: ListView.builder(
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey,
                        ),
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
            ),
          ),
          if (currentSong != null) const MiniPlayer(),
        ],
      ),
    );
  }
}

class MusicSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

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
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey),
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
          ref.read(searchQueryProvider.notifier).state = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    ref.read(searchQueryProvider.notifier).state = query;
    final filteredSongs = ref.watch(filteredSongsProvider);

    return filteredSongs.when(
      data: (songs) {
        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            return SongTile(
              song: songs[index],
              onTap: () async {
                ref.read(currentSongProvider.notifier).state = songs[index];
                final audioService = ref.read(audioServiceProvider);
                await audioService.setPlaylist(songs, index);
                await audioService.play();
                ref.read(isPlayingProvider.notifier).state = true;
                
                if (context.mounted) {
                  context.push('/player', extra: songs[index]);
                }
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error')),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    ref.read(searchQueryProvider.notifier).state = query;
    return buildResults(context);
  }
}