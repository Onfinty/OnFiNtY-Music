import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../providers/music_provider.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final audioService = ref.watch(audioServiceProvider);

    if (currentSong == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        context.push('/player', extra: currentSong);
      },
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Album Art
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: QueryArtworkWidget(
                  id: currentSong.id,
                  type: ArtworkType.AUDIO,
                  nullArtworkWidget: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      color: Color(0xFF8B5CF6),
                      size: 28,
                    ),
                  ),
                  artworkWidth: 54,
                  artworkHeight: 54,
                  artworkFit: BoxFit.cover,
                ),
              ),
            ),
            
            // Song Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentSong.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentSong.displayArtist,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            
            // Play/Pause Button
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: const Color(0xFF8B5CF6),
                size: 32,
              ),
              onPressed: () async {
                if (isPlaying) {
                  await audioService.pause();
                } else {
                  await audioService.play();
                }
                ref.read(isPlayingProvider.notifier).state = !isPlaying;
              },
            ),
            
            // Next Button
            IconButton(
              icon: const Icon(
                Icons.skip_next,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () async {
                await audioService.skipToNext();
                // Update current song
                final index = audioService.currentIndex;
                if (index < audioService.playlist.length) {
                  ref.read(currentSongProvider.notifier).state = 
                      audioService.playlist[index];
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}