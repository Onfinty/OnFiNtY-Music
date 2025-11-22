import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart' show ArtworkType;
import '../models/song_model.dart';
import '../providers/music_provider.dart';
import '../services/audio_service.dart';
import '../widgets/cached_artwork_widget.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final SongModel? song;

  const PlayerScreen({super.key, this.song});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  bool _isDragging = false;
  late AnimationController _albumRotationController;
  int? _lastSongId;

  @override
  void initState() {
    super.initState();
    _setupAudioListeners();

    // Smooth continuous rotation for playing state
    _albumRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
  }

  void _setupAudioListeners() {
    final audioService = ref.read(audioServiceProvider);

    audioService.positionStream.listen((position) {
      if (mounted) {
        ref.read(currentPositionProvider.notifier).state = position;
      }
    });

    audioService.durationStream.listen((duration) {
      if (duration != null && mounted) {
        ref.read(currentDurationProvider.notifier).state = duration;
      }
    });

    audioService.playerStateStream.listen((state) {
      if (mounted) {
        ref.read(isPlayingProvider.notifier).state = state.playing;
        
        // Animate rotation based on play state
        if (state.playing) {
          _albumRotationController.repeat();
        } else {
          _albumRotationController.stop();
        }
      }
    });

    audioService.audioPlayer.currentIndexStream.listen((index) {
      if (index != null && mounted) {
        final playlist = audioService.playlist;
        if (index < playlist.length) {
          ref.read(currentSongProvider.notifier).state = playlist[index];
        }
      }
    });
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
      _isDragging = true;
    });
  }

  Future<void> _handleHorizontalDragEnd(DragEndDetails details) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final audioService = ref.read(audioServiceProvider);

    if (_dragOffset.abs() > screenWidth * 0.3) {
      if (_dragOffset > 0) {
        await audioService.skipToPrevious();
      } else {
        await audioService.skipToNext();
      }
    }

    setState(() {
      _dragOffset = 0.0;
      _isDragging = false;
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity! > 500) {
      context.pop();
    }
  }

  @override
  void dispose() {
    _albumRotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final currentPosition = ref.watch(currentPositionProvider);
    final currentDuration = ref.watch(currentDurationProvider);
    final loopMode = ref.watch(loopModeProvider);
    final favorites = ref.watch(favoritesProvider);
    final audioService = ref.watch(audioServiceProvider);
    final hiddenSongs = ref.watch(hiddenSongsProvider);

    if (currentSong == null) {
      return const Scaffold(
        body: Center(child: Text('No song selected')),
      );
    }

    final isFavorite = favorites.contains(currentSong.id);
    final songChanged = _lastSongId != currentSong.id;
    if (songChanged) {
      _lastSongId = currentSong.id;
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.3),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 28),
            onPressed: () => context.pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.3),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () =>
                  _showOptionsMenu(context, currentSong, hiddenSongs),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragUpdate: _handleHorizontalDragUpdate,
        onHorizontalDragEnd: _handleHorizontalDragEnd,
        onVerticalDragEnd: _handleVerticalDragEnd,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                Colors.black,
                Colors.black,
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;
                final albumArtSize = (screenWidth * 0.75).clamp(200.0, 350.0);
                
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: availableHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(height: isSmallScreen ? 10 : 20),

                          // Album Art with smooth rotation
                          Transform.translate(
                            offset: Offset(_dragOffset * 0.3, 0), // Reduced drag for smoothness
                            child: AnimatedScale(
                              scale: _isDragging ? 0.95 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: RotationTransition(
                                turns: _albumRotationController,
                                child: RepaintBoundary(
                                  key: ValueKey('album_${currentSong.id}'),
                                  child: Container(
                                    width: albumArtSize,
                                    height: albumArtSize,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(albumArtSize / 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF8B5CF6)
                                              .withValues(alpha: isPlaying ? 0.5 : 0.3),
                                          blurRadius: isPlaying ? 50 : 40,
                                          spreadRadius: isPlaying ? 8 : 5,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(albumArtSize / 2),
                                      child: CachedArtworkWidget(
                                        id: currentSong.id,
                                        type: ArtworkType.AUDIO,
                                        quality: 100,
                                        width: albumArtSize,
                                        height: albumArtSize,
                                        fit: BoxFit.cover,
                                        nullArtworkWidget: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                const Color(0xFF8B5CF6)
                                                    .withValues(alpha: 0.5),
                                                const Color(0xFF6D28D9)
                                                    .withValues(alpha: 0.5),
                                              ],
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.music_note,
                                              size: 120,
                                              color: Color(0xFF8B5CF6),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 20 : 40),

                          // Song Info Card
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.1),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  )),
                                  child: child,
                                ),
                              );
                            },
                            child: ClipRRect(
                              key: ValueKey('info_${currentSong.id}'),
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.1),
                                        Colors.white.withValues(alpha: 0.05),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        currentSong.title,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isSmallScreen ? 22 : 26,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        currentSong.displayArtist,
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: isSmallScreen ? 16 : 18,
                                          letterSpacing: 0.3,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 20 : 30),

                          // Progress Slider
                          Column(
                            children: [
                              SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 14,
                                  ),
                                  activeTrackColor: const Color(0xFF8B5CF6),
                                  inactiveTrackColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  thumbColor: Colors.white,
                                  overlayColor: const Color(0xFF8B5CF6)
                                      .withValues(alpha: 0.3),
                                ),
                                child: Slider(
                                  value:
                                      currentPosition.inMilliseconds.toDouble(),
                                  max: currentDuration.inMilliseconds.toDouble() >
                                          0
                                      ? currentDuration.inMilliseconds.toDouble()
                                      : 1.0,
                                  onChanged: (value) {
                                    audioService.seek(
                                        Duration(milliseconds: value.toInt()));
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(currentPosition),
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(currentDuration),
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: isSmallScreen ? 15 : 25),

                          // Control Buttons
                          _buildControlButtons(
                            loopMode,
                            audioService,
                            isPlaying,
                            isFavorite,
                            currentSong,
                            isSmallScreen,
                          ),

                          SizedBox(height: isSmallScreen ? 10 : 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons(
    LoopMode loopMode,
    AudioPlayerService audioService,
    bool isPlaying,
    bool isFavorite,
    SongModel currentSong,
    bool isSmallScreen,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 12 : 15,
            horizontal: 10,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGlassButton(
                icon: loopMode == LoopMode.off
                    ? Icons.repeat
                    : loopMode == LoopMode.one
                        ? Icons.repeat_one
                        : Icons.repeat,
                color: loopMode == LoopMode.off
                    ? Colors.grey[600]!
                    : const Color(0xFF8B5CF6),
                size: isSmallScreen ? 24 : 28,
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
              _buildGlassButton(
                icon: Icons.skip_previous,
                color: Colors.white,
                size: isSmallScreen ? 34 : 38,
                onPressed: () async {
                  await audioService.skipToPrevious();
                },
              ),
              Container(
                width: isSmallScreen ? 60 : 70,
                height: isSmallScreen ? 60 : 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(35),
                    onTap: () async {
                      if (isPlaying) {
                        await audioService.pause();
                      } else {
                        await audioService.play();
                      }
                    },
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          key: ValueKey(isPlaying),
                          size: isSmallScreen ? 36 : 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildGlassButton(
                icon: Icons.skip_next,
                color: Colors.white,
                size: isSmallScreen ? 34 : 38,
                onPressed: () async {
                  await audioService.skipToNext();
                },
              ),
              _buildGlassButton(
                icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey[600]!,
                size: isSmallScreen ? 24 : 28,
                onPressed: () {
                  ref
                      .read(favoritesProvider.notifier)
                      .toggleFavorite(currentSong.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: size),
        onPressed: onPressed,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showOptionsMenu(
      BuildContext context, SongModel song, List<int> hiddenSongs) {
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
                    _buildMenuItem(
                      icon: isHidden ? Icons.visibility : Icons.visibility_off,
                      title: isHidden ? 'Unhide Song' : 'Hide Song',
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
                    _buildMenuItem(
                      icon: Icons.share,
                      title: 'Share',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Share feature coming soon!'),
                            backgroundColor: Color(0xFF8B5CF6),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.speed,
                      title: 'Playback Speed',
                      onTap: () {
                        Navigator.pop(context);
                        _showSpeedDialog(context);
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.info_outline,
                      title: 'Song Info',
                      onTap: () {
                        Navigator.pop(context);
                        _showSongInfo(context, song);
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF8B5CF6)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  void _showSpeedDialog(BuildContext context) {
    final audioService = ref.read(audioServiceProvider);
    final currentSpeed = ref.read(playbackSpeedProvider);
    
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A).withValues(alpha: 0.95),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Playback Speed',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                final isSelected = currentSpeed == speed;
                return ListTile(
                  leading: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF8B5CF6))
                      : const SizedBox(width: 24),
                  title: Text(
                    '${speed}x',
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF8B5CF6) : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    audioService.setSpeed(speed);
                    ref.read(playbackSpeedProvider.notifier).state = speed;
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showSongInfo(BuildContext context, SongModel song) {
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A).withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Song Information',
              style: TextStyle(
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Title', song.title),
                const SizedBox(height: 12),
                _buildInfoRow('Artist', song.displayArtist),
                const SizedBox(height: 12),
                _buildInfoRow('Album', song.album ?? 'Unknown'),
                const SizedBox(height: 12),
                _buildInfoRow('Duration', song.formattedDuration),
                const SizedBox(height: 12),
                _buildInfoRow('ID', song.id.toString()),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Color(0xFF8B5CF6)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}