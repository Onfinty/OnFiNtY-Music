import 'dart:async';
import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart' show ArtworkType;
import '../models/song_model.dart';
import '../providers/music_provider.dart';
import '../services/audio_handler.dart';
import '../services/artwork_palette_service.dart';
import '../widgets/cached_artwork_widget.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final SongModel? song;

  const PlayerScreen({super.key, this.song});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with TickerProviderStateMixin {
  // ─── Drag state ───
  double _horizontalDrag = 0.0;
  double _verticalDrag = 0.0;
  bool _isHorizontalDragging = false;
  bool _isDragDirectionDecided = false;
  bool _isHorizontalDirection = false;

  // ─── Animation controllers ───
  late AnimationController _albumRotationController;
  late AnimationController _songTransitionController;
  late Animation<double> _transitionOpacity;
  late Animation<Offset> _transitionSlide;

  int? _lastSongId;
  bool _isTransitioning = false;
  int _paletteRequestToken = 0;
  SongPalette _activePalette = SongPalette.fallback;

  @override
  void initState() {
    super.initState();

    _albumRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    _songTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _transitionOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _songTransitionController,
        curve: Curves.easeOutCubic,
      ),
    );

    _transitionSlide =
        Tween<Offset>(begin: const Offset(0.03, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _songTransitionController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _albumRotationController.dispose();
    _songTransitionController.dispose();
    super.dispose();
  }

  Future<void> _ensurePaletteForSong(SongModel song) async {
    final paletteService = ref.read(artworkPaletteServiceProvider);
    final requestToken = ++_paletteRequestToken;
    final cachedPalette = paletteService.getCachedPalette(song.id);

    if (cachedPalette != null && cachedPalette != _activePalette && mounted) {
      setState(() {
        _activePalette = cachedPalette;
      });
    }

    try {
      final paletteData = await paletteService.getPalette(song.id);

      if (!mounted || requestToken != _paletteRequestToken) {
        return;
      }

      if (paletteData == _activePalette) {
        return;
      }

      setState(() {
        _activePalette = paletteData;
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

  void _prefetchNearPalettes(SongModel song, List<SongModel> playlist) {
    final paletteService = ref.read(artworkPaletteServiceProvider);
    final currentIndex = playlist.indexWhere((s) => s.id == song.id);

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

  List<Color> _buildBackgroundGradient(bool isDark) {
    if (isDark) {
      final topColor = Color.lerp(
        _activePalette.gradientPrimary,
        Colors.black,
        0.22,
      )!;
      final middleColor = Color.lerp(
        _activePalette.gradientSecondary,
        Colors.black,
        0.5,
      )!;
      final bottomColor = Color.lerp(
        _activePalette.gradientSecondary,
        Colors.black,
        0.82,
      )!;

      return <Color>[topColor, middleColor, bottomColor];
    }

    final topColor = Color.lerp(
      _activePalette.gradientPrimary,
      Colors.white,
      0.18,
    )!;
    final middleColor = Color.lerp(
      _activePalette.gradientSecondary,
      Colors.white,
      0.35,
    )!;
    final bottomColor = Color.lerp(
      _activePalette.gradientSecondary,
      Colors.white,
      0.58,
    )!;

    return <Color>[topColor, middleColor, bottomColor];
  }

  Color _sampleGradientColor(List<Color> colors, double t) {
    final clamped = t.clamp(0.0, 1.0);
    if (clamped <= 0.5) {
      return Color.lerp(colors[0], colors[1], clamped * 2)!;
    }
    return Color.lerp(colors[1], colors[2], (clamped - 0.5) * 2)!;
  }

  // ─── Gesture handlers ───
  void _onPanStart(DragStartDetails details) {
    _isDragDirectionDecided = false;
    _isHorizontalDirection = false;
    _horizontalDrag = 0;
    _verticalDrag = 0;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragDirectionDecided) {
      if (details.delta.dx.abs() > 2 || details.delta.dy.abs() > 2) {
        _isHorizontalDirection =
            details.delta.dx.abs() > details.delta.dy.abs();
        _isDragDirectionDecided = true;
      }
    }

    setState(() {
      if (_isHorizontalDirection) {
        _horizontalDrag += details.delta.dx;
        _isHorizontalDragging = true;
      } else {
        _verticalDrag += details.delta.dy;
      }
    });
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isHorizontalDirection) {
      // Horizontal: skip song
      if (_horizontalDrag.abs() > screenWidth * 0.25 ||
          details.velocity.pixelsPerSecond.dx.abs() > 500) {
        final audioHandler = ref.read(audioHandlerProvider);
        if (_horizontalDrag > 0) {
          await audioHandler.skipToPrevious();
        } else {
          await audioHandler.skipToNext();
        }
      }
    } else {
      // Vertical: dismiss player
      if (_verticalDrag > 80 || details.velocity.pixelsPerSecond.dy > 300) {
        if (context.mounted) context.pop();
        return;
      }
    }

    setState(() {
      _horizontalDrag = 0;
      _verticalDrag = 0;
      _isHorizontalDragging = false;
      _isDragDirectionDecided = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentSongAsync = ref.watch(currentSongProvider);
    final isPlayingAsync = ref.watch(isPlayingProvider);
    final currentPositionAsync = ref.watch(currentPositionProvider);
    final currentDurationAsync = ref.watch(currentDurationProvider);
    final loopMode = ref.watch(loopModeProvider);
    final favorites = ref.watch(favoritesProvider);
    final audioHandler = ref.watch(audioHandlerProvider);
    final hiddenSongs = ref.watch(hiddenSongsProvider);
    final isDark = ref.watch(isDarkModeProvider);

    final currentSong = currentSongAsync.value;
    final isPlaying = isPlayingAsync.value ?? false;
    final currentPosition = currentPositionAsync.value ?? Duration.zero;
    final currentDuration = currentDurationAsync.value ?? Duration.zero;

    // Rotation animation
    if (isPlaying) {
      if (!_albumRotationController.isAnimating) {
        _albumRotationController.repeat();
      }
    } else {
      _albumRotationController.stop();
    }

    if (currentSong == null) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF8F7FC),
        body: Center(
          child: Text(
            'No song playing',
            style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600]),
          ),
        ),
      );
    }

    // Song change animation
    if (_lastSongId != currentSong.id) {
      _lastSongId = currentSong.id;
      unawaited(_ensurePaletteForSong(currentSong));
      _prefetchNearPalettes(currentSong, audioHandler.songPlaylist);
      if (!_isTransitioning) {
        _isTransitioning = true;
        _songTransitionController.forward(from: 0).then((_) {
          _isTransitioning = false;
        });
      }
    }

    final isFavorite = favorites.contains(currentSong.id);

    // ─── Responsive sizing ───
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final screenW = mq.size.width;
    final safeTop = mq.padding.top;
    final safeBottom = mq.padding.bottom;
    final availH = screenH - safeTop - safeBottom;

    // Compute sizes proportionally
    final albumArtSize = (screenW * 0.72).clamp(180.0, 320.0);
    final isCompact = availH < 650;

    // Vertical drag transform
    final dragDismissProgress = (_verticalDrag / 300).clamp(0.0, 1.0);
    final dragScale = 1.0 - (dragDismissProgress * 0.15);
    final dragOpacity = 1.0 - (dragDismissProgress * 0.5);

    // ─── Theme Colors ───
    final bgGradient = _buildBackgroundGradient(isDark);
    final topBackground = _sampleGradientColor(bgGradient, 0.16);
    final middleBackground = _sampleGradientColor(bgGradient, 0.52);
    final bottomBackground = _sampleGradientColor(bgGradient, 0.84);

    final topPrimaryTextColor = ArtworkPaletteService.readableText(
      topBackground,
    );
    final topSecondaryTextColor = ArtworkPaletteService.readableMutedText(
      topBackground,
    );
    final middlePrimaryTextColor = ArtworkPaletteService.readableText(
      middleBackground,
    );
    final middleSecondaryTextColor = ArtworkPaletteService.readableMutedText(
      middleBackground,
    );
    final bottomPrimaryTextColor = ArtworkPaletteService.readableText(
      bottomBackground,
    );
    final bottomSecondaryTextColor = ArtworkPaletteService.readableMutedText(
      bottomBackground,
    );

    final accentColor = ArtworkPaletteService.readableAccent(
      _activePalette.glowColor,
      middleBackground,
    );
    final controlSurfaceColor = ArtworkPaletteService.adaptiveSurfaceColor(
      bottomBackground,
      isDark: isDark,
    );
    final controlBorderColor = ArtworkPaletteService.adaptiveBorderColor(
      bottomBackground,
      isDark: isDark,
    );

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFFFFFFF),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Transform.scale(
          scale: dragScale,
          child: Opacity(
            opacity: dragOpacity.clamp(0.0, 1.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: screenW,
              height: screenH,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.46, 1.0],
                  colors: bgGradient,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const <double>[0.0, 0.55, 1.0],
                            colors: <Color>[
                              (isDark ? Colors.black : Colors.white).withValues(
                                alpha: isDark ? 0.14 : 0.05,
                              ),
                              Colors.transparent,
                              (isDark ? Colors.black : Colors.black).withValues(
                                alpha: isDark ? 0.22 : 0.08,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        // ─── Top Bar ───
                        _buildTopBar(
                          currentSong,
                          hiddenSongs,
                          isDark,
                          topPrimaryTextColor,
                          topSecondaryTextColor,
                          controlSurfaceColor,
                          controlBorderColor,
                        ),

                        // ─── Album Art ───
                        Expanded(
                          flex: isCompact ? 4 : 5,
                          child: Center(
                            child: _buildAlbumArt(
                              currentSong,
                              isPlaying,
                              albumArtSize,
                              isDark,
                              _activePalette.glowColor,
                            ),
                          ),
                        ),

                        // ─── Song Info ───
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: isCompact ? 8 : 16,
                          ),
                          child: _buildSongInfo(
                            currentSong,
                            isCompact,
                            middlePrimaryTextColor,
                            middleSecondaryTextColor,
                          ),
                        ),

                        // ─── Progress Slider ───
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: _buildProgressSlider(
                            currentPosition,
                            currentDuration,
                            audioHandler,
                            accentColor,
                            middleSecondaryTextColor,
                          ),
                        ),

                        SizedBox(height: isCompact ? 8 : 16),

                        // ─── Controls ───
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildControls(
                            loopMode,
                            audioHandler,
                            isPlaying,
                            isFavorite,
                            currentSong,
                            isCompact,
                            isDark,
                            bottomPrimaryTextColor,
                            bottomSecondaryTextColor,
                            accentColor,
                            controlSurfaceColor,
                            controlBorderColor,
                          ),
                        ),

                        SizedBox(height: isCompact ? 12 : 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTopBar(
    SongModel currentSong,
    List<int> hiddenSongs,
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color surfaceColor,
    Color borderColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(
            icon: Icons.keyboard_arrow_down_rounded,
            onTap: () => context.pop(),
            iconColor: primaryTextColor,
            backgroundColor: surfaceColor,
            borderColor: borderColor,
          ),
          // "Now Playing" label
          Column(
            children: [
              Text(
                'NOW PLAYING',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          _buildCircleButton(
            icon: Icons.more_horiz_rounded,
            onTap: () =>
                _showOptionsMenu(context, currentSong, hiddenSongs, isDark),
            iconColor: primaryTextColor,
            backgroundColor: surfaceColor,
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Icon(icon, color: iconColor, size: 26),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ALBUM ART
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAlbumArt(
    SongModel song,
    bool isPlaying,
    double size,
    bool isDark,
    Color glowColor,
  ) {
    return AnimatedBuilder(
      animation: _songTransitionController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _transitionOpacity,
          child: SlideTransition(position: _transitionSlide, child: child),
        );
      },
      child: Transform.translate(
        offset: Offset(_horizontalDrag * 0.4, 0),
        child: AnimatedScale(
          scale: _isHorizontalDragging ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: RotationTransition(
            turns: _albumRotationController,
            child: RepaintBoundary(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(
                        alpha: isPlaying ? 0.74 : 0.42,
                      ),
                      blurRadius: isPlaying ? 58 : 34,
                      spreadRadius: isPlaying ? 10 : 4,
                    ),
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Stack(
                    children: [
                      CachedArtworkWidget(
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        quality: 100,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        nullArtworkWidget: Container(
                          width: size,
                          height: size,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF8B5CF6), Color(0xFF4C1D95)],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.music_note_rounded,
                              size: size * 0.35,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                      // Vinyl center hole effect
                      Center(
                        child: Container(
                          width: size * 0.12,
                          height: size * 0.12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.7)
                                : Colors.white.withValues(alpha: 0.85),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.grey.withValues(alpha: 0.2),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.5)
                                    : Colors.grey.withValues(alpha: 0.3),
                                blurRadius: 8,
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
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SONG INFO
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSongInfo(
    SongModel song,
    bool isCompact,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    final tertiaryTextColor = secondaryTextColor.withValues(alpha: 0.86);

    return AnimatedBuilder(
      animation: _songTransitionController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _transitionOpacity,
          child: SlideTransition(position: _transitionSlide, child: child),
        );
      },
      child: Column(
        children: [
          Text(
            song.title,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: isCompact ? 18 : 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isCompact ? 4 : 6),
          Text(
            song.displayArtist,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: isCompact ? 14 : 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (song.album != null) ...[
            const SizedBox(height: 4),
            Text(
              song.album!,
              style: TextStyle(
                color: tertiaryTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROGRESS SLIDER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildProgressSlider(
    Duration position,
    Duration duration,
    OnFinityAudioHandler audioHandler,
    Color accentColor,
    Color secondaryTextColor,
  ) {
    final maxMs = duration.inMilliseconds.toDouble();
    final posMs = position.inMilliseconds.toDouble().clamp(
      0.0,
      maxMs > 0 ? maxMs : 1.0,
    );

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: accentColor,
            inactiveTrackColor: secondaryTextColor.withValues(alpha: 0.28),
            thumbColor: accentColor,
            overlayColor: accentColor.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: posMs,
            max: maxMs > 0 ? maxMs : 1.0,
            onChanged: (value) {
              audioHandler.seek(Duration(milliseconds: value.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                _formatDuration(duration),
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTROLS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildControls(
    AudioServiceRepeatMode loopMode,
    OnFinityAudioHandler audioHandler,
    bool isPlaying,
    bool isFavorite,
    SongModel currentSong,
    bool isCompact,
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color accentColor,
    Color controlSurfaceColor,
    Color controlBorderColor,
  ) {
    final btnSize = isCompact ? 48.0 : 52.0;
    final playBtnSize = isCompact ? 64.0 : 72.0;
    final iconColor = primaryTextColor;
    final disabledColor = secondaryTextColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Repeat
        _buildControlButton(
          icon: loopMode == AudioServiceRepeatMode.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          color: loopMode == AudioServiceRepeatMode.none
              ? disabledColor
              : accentColor,
          size: btnSize,
          iconSize: isCompact ? 22 : 24,
          onTap: () {
            final newMode = loopMode == AudioServiceRepeatMode.none
                ? AudioServiceRepeatMode.one
                : loopMode == AudioServiceRepeatMode.one
                ? AudioServiceRepeatMode.all
                : AudioServiceRepeatMode.none;
            ref.read(loopModeProvider.notifier).state = newMode;
            audioHandler.setRepeatMode(newMode);
          },
          backgroundColor: controlSurfaceColor,
          borderColor: controlBorderColor,
        ),

        // Previous
        _buildControlButton(
          icon: Icons.skip_previous_rounded,
          color: iconColor,
          size: btnSize,
          iconSize: isCompact ? 32 : 36,
          onTap: () async => await audioHandler.skipToPrevious(),
          backgroundColor: controlSurfaceColor,
          borderColor: controlBorderColor,
        ),

        // Play/Pause — the big button
        GestureDetector(
          onTap: () async {
            if (isPlaying) {
              await audioHandler.pause();
            } else {
              await audioHandler.play();
            }
          },
          child: Container(
            width: playBtnSize,
            height: playBtnSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                        blurRadius: 24,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(isPlaying),
                  size: isCompact ? 36 : 42,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        // Next
        _buildControlButton(
          icon: Icons.skip_next_rounded,
          color: iconColor,
          size: btnSize,
          iconSize: isCompact ? 32 : 36,
          onTap: () async => await audioHandler.skipToNext(),
          backgroundColor: controlSurfaceColor,
          borderColor: controlBorderColor,
        ),

        // Favorite
        _buildControlButton(
          icon: isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          color: isFavorite ? Colors.red : disabledColor,
          size: btnSize,
          iconSize: isCompact ? 22 : 24,
          onTap: () {
            ref.read(favoritesProvider.notifier).toggleFavorite(currentSong.id);
          },
          backgroundColor: controlSurfaceColor,
          borderColor: controlBorderColor,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required double size,
    required double iconSize,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Center(
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORMAT DURATION (with hour support)
  // ═══════════════════════════════════════════════════════════════════════════
  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final m = minutes.toString().padLeft(2, '0');
    final s = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$m:$s';
    }
    return '$m:$s';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OPTIONS MENU
  // ═══════════════════════════════════════════════════════════════════════════
  void _showOptionsMenu(
    BuildContext context,
    SongModel song,
    List<int> hiddenSongs,
    bool isDark,
  ) {
    final isHidden = hiddenSongs.contains(song.id);
    final bgColor = isDark
        ? const Color(0xFF1A1A1A).withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.98);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.05);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(top: BorderSide(color: dividerColor, width: 1)),
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
                    const SizedBox(height: 16),
                    _buildMenuItem(
                      icon: isHidden
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      title: isHidden ? 'Unhide Song' : 'Hide Song',
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
                      isDark: isDark,
                    ),
                    _buildMenuItem(
                      icon: Icons.speed_rounded,
                      title: 'Playback Speed',
                      onTap: () {
                        Navigator.pop(context);
                        _showSpeedDialog(context, isDark);
                      },
                      isDark: isDark,
                    ),
                    _buildMenuItem(
                      icon: Icons.info_outline_rounded,
                      title: 'Song Info',
                      onTap: () {
                        Navigator.pop(context);
                        _showSongInfo(context, song, isDark);
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
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
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF8B5CF6), size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1C1B1F),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showSpeedDialog(BuildContext context, bool isDark) {
    final audioHandler = ref.read(audioHandlerProvider);
    final currentSpeed = ref.read(playbackSpeedProvider);
    final bgColor = isDark
        ? const Color(0xFF1A1A1A).withValues(alpha: 0.95)
        : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1B1F);

    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              'Playback Speed',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                final isSelected = currentSpeed == speed;
                return ListTile(
                  leading: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF8B5CF6),
                        )
                      : const SizedBox(width: 24),
                  title: Text(
                    '${speed}x',
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF8B5CF6) : textColor,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    audioHandler.setSpeed(speed);
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

  void _showSongInfo(BuildContext context, SongModel song, bool isDark) {
    final bgColor = isDark
        ? const Color(0xFF1A1A1A).withValues(alpha: 0.95)
        : Colors.white;
    final valueColor = isDark ? Colors.white : const Color(0xFF1C1B1F);
    final labelColor = isDark ? Colors.grey[600] : Colors.grey[600];

    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
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
                _buildInfoRow('Title', song.title, labelColor, valueColor),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Artist',
                  song.displayArtist,
                  labelColor,
                  valueColor,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Album',
                  song.album ?? 'Unknown',
                  labelColor,
                  valueColor,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Duration',
                  song.formattedDuration,
                  labelColor,
                  valueColor,
                ),
                const SizedBox(height: 12),
                _buildInfoRow('ID', song.id.toString(), labelColor, valueColor),
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

  Widget _buildInfoRow(
    String label,
    String value,
    Color? labelColor,
    Color valueColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
