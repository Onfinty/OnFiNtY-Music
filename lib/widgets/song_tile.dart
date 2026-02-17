import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import '../models/song_model.dart';
import '../providers/music_provider.dart';
import 'cached_artwork_widget.dart';

class SongTile extends ConsumerWidget {
  final SongModel song;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const SongTile({
    super.key,
    required this.song,
    this.index = 0,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final currentSongAsync = ref.watch(currentSongProvider);
    final isPlayingAsync = ref.watch(isPlayingProvider);
    final currentSong = currentSongAsync.value;
    final isPlaying = isPlayingAsync.value ?? false;
    final isCurrentSong = currentSong?.id == song.id;

    final primaryColor = isDark
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF7C3AED);

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(16),
            splashColor: primaryColor.withValues(alpha: 0.1),
            highlightColor: primaryColor.withValues(alpha: 0.05),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrentSong
                    ? (isDark
                          ? primaryColor.withValues(alpha: 0.12)
                          : primaryColor.withValues(alpha: 0.06))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isCurrentSong
                    ? Border.all(
                        color: primaryColor.withValues(
                          alpha: isDark ? 0.3 : 0.15,
                        ),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // ─── Track Number or Playing Indicator ───
                  SizedBox(
                    width: 28,
                    child: isCurrentSong && isPlaying
                        ? _buildEqualizerBars(primaryColor)
                        : Text(
                            '${index + 1}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isCurrentSong
                                  ? primaryColor
                                  : (isDark
                                        ? Colors.grey[600]
                                        : Colors.grey[400]),
                              fontSize: 13,
                              fontWeight: isCurrentSong
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                  ),

                  const SizedBox(width: 12),

                  // ─── Album Art ───
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        if (isCurrentSong)
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: CachedArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      width: 52,
                      height: 52,
                      quality: 80,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(12),
                      nullArtworkWidget: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    primaryColor.withValues(alpha: 0.25),
                                    const Color(
                                      0xFF6D28D9,
                                    ).withValues(alpha: 0.15),
                                  ]
                                : [
                                    const Color(0xFFE8DEF8),
                                    const Color(0xFFF3EEFB),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.music_note_rounded,
                          color: isDark
                              ? primaryColor.withValues(alpha: 0.7)
                              : primaryColor.withValues(alpha: 0.5),
                          size: 26,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // ─── Song Info ───
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: TextStyle(
                            color: isCurrentSong
                                ? primaryColor
                                : (isDark
                                      ? Colors.white
                                      : const Color(0xFF1C1B1F)),
                            fontSize: 15,
                            fontWeight: isCurrentSong
                                ? FontWeight.w600
                                : FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          song.displayArtist,
                          style: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ─── Duration ───
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF3EEFB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      song.formattedDuration,
                      style: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
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

  // ─── Animated Equalizer Bars ───
  Widget _buildEqualizerBars(Color color) {
    return SizedBox(
      width: 20,
      height: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          return _EqualizerBar(
            color: color,
            delay: Duration(milliseconds: i * 150),
          );
        }),
      ),
    );
  }
}

class _EqualizerBar extends StatefulWidget {
  final Color color;
  final Duration delay;

  const _EqualizerBar({required this.color, required this.delay});

  @override
  State<_EqualizerBar> createState() => _EqualizerBarState();
}

class _EqualizerBarState extends State<_EqualizerBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(
      begin: 4.0,
      end: 16.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 3.5,
          height: _animation.value,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
