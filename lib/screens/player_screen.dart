import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import '../models/song_model.dart';
import '../providers/music_provider.dart';
import '../services/audio_service.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final SongModel? song;

  const PlayerScreen({super.key, this.song});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    final audioService = ref.read(audioServiceProvider);
    
    // Listen to position changes
    audioService.positionStream.listen((position) {
      ref.read(currentPositionProvider.notifier).state = position;
    });
    
    // Listen to duration changes
    audioService.durationStream.listen((duration) {
      if (duration != null) {
        ref.read(currentDurationProvider.notifier).state = duration;
      }
    });
    
    // Listen to player state changes
    audioService.playerStateStream.listen((state) {
      ref.read(isPlayingProvider.notifier).state = state.playing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider) ?? widget.song;
    final isPlaying = ref.watch(isPlayingProvider);
    final currentPosition = ref.watch(currentPositionProvider);
    final currentDuration = ref.watch(currentDurationProvider);
    final loopMode = ref.watch(loopModeProvider);
    final favorites = ref.watch(favoritesProvider);
    final audioService = ref.watch(audioServiceProvider);

    if (currentSong == null) {
      return const Scaffold(
        body: Center(child: Text('No song selected')),
      );
    }

    final isFavorite = favorites.contains(currentSong.id);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context, currentSong),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Album Art
              Hero(
                tag: 'album_art_${currentSong.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: QueryArtworkWidget(
                    id: currentSong.id,
                    type: ArtworkType.AUDIO,
                    nullArtworkWidget: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                            const Color(0xFF6D28D9).withValues(alpha: 0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        size: 100,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    artworkWidth: MediaQuery.of(context).size.width * 0.8,
                    artworkHeight: MediaQuery.of(context).size.width * 0.8,
                    artworkFit: BoxFit.cover,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Song Title
              Text(
                currentSong.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Artist Name
              Text(
                currentSong.displayArtist,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Progress Slider
              Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                      activeTrackColor: const Color(0xFF8B5CF6),
                      inactiveTrackColor: Colors.grey[800],
                      thumbColor: const Color(0xFF8B5CF6),
                      overlayColor: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    ),
                    child: Slider(
                      value: currentPosition.inMilliseconds.toDouble(),
                      max: currentDuration.inMilliseconds.toDouble() > 0
                          ? currentDuration.inMilliseconds.toDouble()
                          : 1.0,
                      onChanged: (value) {
                        audioService.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(currentPosition),
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        Text(
                          _formatDuration(currentDuration),
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Loop Button
                  IconButton(
                    icon: Icon(
                      loopMode == LoopMode.off
                          ? Icons.repeat
                          : loopMode == LoopMode.one
                              ? Icons.repeat_one
                              : Icons.repeat,
                      color: loopMode == LoopMode.off
                          ? Colors.grey[600]
                          : const Color(0xFF8B5CF6),
                    ),
                    iconSize: 28,
                    onPressed: () {
                      final newMode = loopMode == LoopMode.off
                          ? LoopMode.one
                          : loopMode == LoopMode.one
                              ? LoopMode.all
                              : LoopMode.off;
                      ref.read(loopModeProvider.notifier).state = newMode;
                      audioService.setLoopMode(newMode);
                    },
                  ),
                  
                  // Previous Button
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    iconSize: 40,
                    color: Colors.white,
                    onPressed: () async {
                      await audioService.skipToPrevious();
                      final index = audioService.currentIndex;
                      if (index >= 0 && index < audioService.playlist.length) {
                        ref.read(currentSongProvider.notifier).state =
                            audioService.playlist[index];
                      }
                    },
                  ),
                  
                  // Play/Pause Button
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      iconSize: 48,
                      color: Colors.white,
                      onPressed: () async {
                        if (isPlaying) {
                          await audioService.pause();
                        } else {
                          await audioService.play();
                        }
                      },
                    ),
                  ),
                  
                  // Next Button
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    iconSize: 40,
                    color: Colors.white,
                    onPressed: () async {
                      await audioService.skipToNext();
                      final index = audioService.currentIndex;
                      if (index < audioService.playlist.length) {
                        ref.read(currentSongProvider.notifier).state =
                            audioService.playlist[index];
                      }
                    },
                  ),
                  
                  // Favorite Button
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey[600],
                    ),
                    iconSize: 28,
                    onPressed: () {
                      final newFavorites = [...favorites];
                      if (isFavorite) {
                        newFavorites.remove(currentSong.id);
                      } else {
                        newFavorites.add(currentSong.id);
                      }
                      ref.read(favoritesProvider.notifier).state = newFavorites;
                    },
                  ),
                ],
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showOptionsMenu(BuildContext context, SongModel song) {
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
                leading: const Icon(Icons.share, color: Color(0xFF8B5CF6)),
                title: const Text('Share', style: TextStyle(color: Colors.white)),
                onTap: () {
                  
                },
              ),
              ListTile(
                leading: const Icon(Icons.speed, color: Color(0xFF8B5CF6)),
                title: const Text('Playback Speed', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showSpeedDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.ring_volume, color: Color(0xFF8B5CF6)),
                title: const Text('Set as Ringtone', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ringtone feature coming soon!'),
                      backgroundColor: Color(0xFF8B5CF6),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context, song);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSpeedDialog(BuildContext context) {
    final audioService = ref.read(audioServiceProvider);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Playback Speed', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
              return ListTile(
                title: Text(
                  '${speed}x',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  audioService.setSpeed(speed);
                  ref.read(playbackSpeedProvider.notifier).state = speed;
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, SongModel song) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Delete Song', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to delete "${song.title}"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Delete feature coming soon!'),
                    backgroundColor: Color(0xFF8B5CF6),
                  ),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}