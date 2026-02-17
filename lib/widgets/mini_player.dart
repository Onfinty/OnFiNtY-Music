import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart' show ArtworkType;
import '../models/song_model.dart';
import '../providers/music_provider.dart';
import '../services/audio_handler.dart';
import '../services/artwork_palette_service.dart';
import '../widgets/cached_artwork_widget.dart';

class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int? _lastSongId;
  int _paletteRequestToken = 0;
  SongPalette _activePalette = SongPalette.fallback;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateToPlayer() {
    context.push('/player');
  }

  Future<void> _syncPaletteForSong(int songId) async {
    final paletteService = ref.read(artworkPaletteServiceProvider);
    final requestToken = ++_paletteRequestToken;
    final cached = paletteService.getCachedPalette(songId);

    if (cached != null && cached != _activePalette && mounted) {
      setState(() {
        _activePalette = cached;
      });
    }

    try {
      final palette = await paletteService.getPalette(songId);
      if (!mounted || requestToken != _paletteRequestToken) {
        return;
      }

      if (palette == _activePalette) {
        return;
      }

      setState(() {
        _activePalette = palette;
      });
    } catch (_) {
      if (!mounted || requestToken != _paletteRequestToken) {
        return;
      }

      setState(() {
        _activePalette = SongPalette.fallback;
      });
    }
  }

  void _prefetchNearPalettes(int songId, List<SongModel> playlist) {
    final paletteService = ref.read(artworkPaletteServiceProvider);
    final currentIndex = playlist.indexWhere((song) => song.id == songId);

    if (currentIndex < 0) {
      return;
    }

    final candidates = <int>[
      currentIndex - 1,
      currentIndex + 1,
      currentIndex + 2,
    ];

    for (final index in candidates) {
      if (index >= 0 && index < playlist.length) {
        unawaited(paletteService.prefetchPalette(playlist[index].id));
      }
    }
  }

  List<Color> _buildMiniGradient(bool isDark) {
    if (isDark) {
      return <Color>[
        _activePalette.gradientPrimary.withValues(alpha: 0.48),
        Color.lerp(_activePalette.gradientSecondary, Colors.black, 0.35)!,
      ];
    }

    return <Color>[
      Color.lerp(_activePalette.gradientPrimary, Colors.white, 0.48)!,
      Color.lerp(_activePalette.gradientSecondary, Colors.white, 0.7)!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentSongAsync = ref.watch(currentSongProvider);
    final isPlayingAsync = ref.watch(isPlayingProvider);
    final currentPositionAsync = ref.watch(currentPositionProvider);
    final currentDurationAsync = ref.watch(currentDurationProvider);
    final audioHandler = ref.watch(audioHandlerProvider);
    final isDark = ref.watch(isDarkModeProvider);

    final currentSong = currentSongAsync.value;
    final isPlaying = isPlayingAsync.value ?? false;
    final currentPosition = currentPositionAsync.value ?? Duration.zero;
    final currentDuration = currentDurationAsync.value ?? Duration.zero;

    if (currentSong == null) return const SizedBox.shrink();

    final progress = currentDuration.inMilliseconds > 0
        ? currentPosition.inMilliseconds / currentDuration.inMilliseconds
        : 0.0;

    final songChanged = _lastSongId != currentSong.id;
    if (songChanged) {
      _lastSongId = currentSong.id;
      unawaited(_syncPaletteForSong(currentSong.id));
      _prefetchNearPalettes(currentSong.id, audioHandler.songPlaylist);
    }

    final glowColor = _activePalette.glowColor;
    final miniGradient = _buildMiniGradient(isDark);
    final contentBackground = Color.lerp(
      miniGradient[0],
      miniGradient[1],
      0.45,
    )!;
    final primaryTextColor = ArtworkPaletteService.readableText(
      contentBackground,
    );
    final secondaryTextColor = ArtworkPaletteService.readableMutedText(
      contentBackground,
    );
    final accentColor = ArtworkPaletteService.readableAccent(
      glowColor,
      contentBackground,
    );
    final actionSurface = ArtworkPaletteService.adaptiveSurfaceColor(
      contentBackground,
      isDark: isDark,
    );
    final actionBorder = ArtworkPaletteService.adaptiveBorderColor(
      contentBackground,
      isDark: isDark,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: isDark ? 0.45 : 0.26),
            blurRadius: isDark ? 26 : 18,
            offset: const Offset(0, 8),
          ),
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                // Background container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: miniGradient,
                    ),
                    border: Border.all(
                      color: isDark
                          ? glowColor.withValues(alpha: 0.28)
                          : glowColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                // Progress bar at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor: secondaryTextColor.withValues(
                        alpha: 0.24,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                ),

                // Main content — tapping the body (not buttons) navigates to player
                InkWell(
                  onTap: _navigateToPlayer,
                  borderRadius: BorderRadius.circular(20),
                  splashColor: glowColor.withValues(alpha: 0.14),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Album Art
                        RepaintBoundary(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isPlaying
                                  ? [
                                      BoxShadow(
                                        color: glowColor.withValues(alpha: 0.5),
                                        blurRadius: 14,
                                        spreadRadius: 3,
                                      ),
                                    ]
                                  : isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: CachedArtworkWidget(
                              id: currentSong.id,
                              type: ArtworkType.AUDIO,
                              width: 56,
                              height: 56,
                              quality: 50,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(12),
                              nullArtworkWidget: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: <Color>[
                                      _activePalette.gradientPrimary,
                                      _activePalette.gradientSecondary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.music_note_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Song Info
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentSong.title,
                                style: TextStyle(
                                  color: primaryTextColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (isPlaying)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: AnimatedBuilder(
                                        animation: _pulseAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _pulseAnimation.value,
                                            child: Icon(
                                              Icons.graphic_eq_rounded,
                                              color: accentColor,
                                              size: 14,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      currentSong.displayArtist,
                                      style: TextStyle(
                                        color: secondaryTextColor,
                                        fontSize: 13,
                                        letterSpacing: 0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Play/Pause Button — absorbs taps so they don't reach InkWell
                        _buildPlayPauseButton(
                          audioHandler,
                          isPlaying,
                          _activePalette,
                          accentColor,
                        ),

                        const SizedBox(width: 8),

                        // Skip Button — absorbs taps so they don't reach InkWell
                        _buildSkipButton(
                          audioHandler,
                          actionSurface,
                          actionBorder,
                          primaryTextColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton(
    OnFinityAudioHandler audioHandler,
    bool isPlaying,
    SongPalette palette,
    Color accentColor,
  ) {
    final secondaryColor = palette.gradientSecondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (isPlaying) {
          await audioHandler.pause();
        } else {
          await audioHandler.play();
        }
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withValues(alpha: 0.92),
              secondaryColor.withValues(alpha: 0.95),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.55),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              key: ValueKey(isPlaying),
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton(
    OnFinityAudioHandler audioHandler,
    Color backgroundColor,
    Color borderColor,
    Color iconColor,
  ) {
    final safeIconColor = ArtworkPaletteService.readableAccent(
      iconColor,
      backgroundColor,
      minContrast: 2.8,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await audioHandler.skipToNext();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Center(
          child: Icon(Icons.skip_next_rounded, color: safeIconColor, size: 24),
        ),
      ),
    );
  }
}
