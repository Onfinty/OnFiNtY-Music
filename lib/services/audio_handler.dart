import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import '../models/song_model.dart';

/// Production-grade AudioHandler implementing BaseAudioHandler.
/// Handles background playback, notification controls, media buttons,
/// audio focus, and all playback operations.
class OnFinityAudioHandler extends BaseAudioHandler with SeekHandler {
  final ja.AudioPlayer _player = ja.AudioPlayer();
  final List<SongModel> _songPlaylist = [];
  bool _isReplacingQueue = false;
  int? _pendingTargetIndex;

  // Stream subscriptions for cleanup
  final List<StreamSubscription> _subscriptions = [];

  ja.AudioPlayer get player => _player;
  List<SongModel> get songPlaylist => List.unmodifiable(_songPlaylist);
  int? get currentIndex => _player.currentIndex;

  // Expose player streams for providers
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<ja.PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  OnFinityAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // Configure audio session for music playback (C-08)
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Handle audio interruptions (phone calls, other apps)
    _subscriptions.add(
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(0.3);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              _player.pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(1.0);
              break;
            case AudioInterruptionType.pause:
              _player.play();
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      }),
    );

    // Handle headphone disconnect — auto-pause
    _subscriptions.add(
      session.becomingNoisyEventStream.listen((_) {
        _player.pause();
      }),
    );

    // Broadcast playback state changes
    _subscriptions.add(
      _player.playbackEventStream.listen(
        _broadcastPlaybackState,
        onError: (Object e, StackTrace st) {
          debugPrintError('Playback event error: $e');
          _broadcastPlaybackState(_player.playbackEvent);
        },
      ),
    );

    // Update mediaItem when current index changes
    _subscriptions.add(
      _player.currentIndexStream.listen((index) {
        if (_isReplacingQueue) {
          if (index != null &&
              index == _pendingTargetIndex &&
              index < queue.value.length) {
            mediaItem.add(queue.value[index]);
          }
          return;
        }
        if (index != null && index < queue.value.length) {
          mediaItem.add(queue.value[index]);
        }
      }),
    );

    // Handle playback completion
    _subscriptions.add(
      _player.processingStateStream.listen((state) {
        if (state == ja.ProcessingState.completed) {
          _player.seek(Duration.zero);
          _player.pause();
        }
      }),
    );
  }

  void _broadcastPlaybackState(ja.PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _mapProcessingState(_player.processingState),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
      ),
    );
  }

  AudioProcessingState _mapProcessingState(ja.ProcessingState state) {
    switch (state) {
      case ja.ProcessingState.idle:
        return AudioProcessingState.idle;
      case ja.ProcessingState.loading:
        return AudioProcessingState.loading;
      case ja.ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ja.ProcessingState.ready:
        return AudioProcessingState.ready;
      case ja.ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  /// Set playlist from app SongModels and start at specified index.
  Future<void> setPlaylist(List<SongModel> songs, int startIndex) async {
    if (songs.isEmpty) {
      _isReplacingQueue = true;
      try {
        _songPlaylist.clear();
        queue.add(const <MediaItem>[]);
        mediaItem.add(null);
        await _player.stop();
      } finally {
        _isReplacingQueue = false;
      }
      return;
    }

    final safeStartIndex = startIndex.clamp(0, songs.length - 1);
    debugPrintError(
      'setPlaylist requested=$startIndex safe=$safeStartIndex '
      'songId=${songs[safeStartIndex].id} total=${songs.length}',
    );

    _isReplacingQueue = true;
    _pendingTargetIndex = safeStartIndex;
    _songPlaylist.clear();
    _songPlaylist.addAll(songs);

    // Convert to MediaItems for queue
    final mediaItems = songs
        .map(
          (song) => MediaItem(
            id: song.uri,
            title: song.title,
            artist: song.displayArtist,
            album: song.album,
            duration: Duration(milliseconds: song.duration),
            artUri: song.artUri != null ? Uri.parse(song.artUri!) : null,
            extras: {'songId': song.id},
          ),
        )
        .toList();

    // Update queue
    queue.add(mediaItems);

    // Build audio source with error handling (M-10)
    try {
      // Set current media item FIRST so UI shows correct song immediately
      mediaItem.add(mediaItems[safeStartIndex]);

      final audioSource = ja.ConcatenatingAudioSource(
        children: songs.asMap().entries.map((entry) {
          final song = entry.value;
          return ja.AudioSource.uri(
            Uri.parse(song.uri),
            tag: mediaItems[entry.key],
          );
        }).toList(),
      );

      await _player.setAudioSource(
        audioSource,
        initialIndex: safeStartIndex,
        initialPosition: Duration.zero,
        preload: true,
      );
      debugPrintError(
        'after setAudioSource currentIndex=${_player.currentIndex}',
      );

      await _forceTargetIndex(safeStartIndex);
      debugPrintError(
        'after forceTargetIndex currentIndex=${_player.currentIndex}',
      );

      mediaItem.add(mediaItems[safeStartIndex]);
    } catch (e) {
      debugPrintError('Error setting playlist: $e');
      rethrow;
    } finally {
      _pendingTargetIndex = null;
      _isReplacingQueue = false;
    }
  }

  Future<void> _forceTargetIndex(int targetIndex) async {
    for (var attempt = 0; attempt < 4; attempt++) {
      if (_player.currentIndex == targetIndex) {
        return;
      }

      await _player.seek(Duration.zero, index: targetIndex);
      await Future<void>.delayed(const Duration(milliseconds: 35));
    }
  }

  @override
  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      debugPrintError('Error playing: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrintError('Error pausing: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrintError('Error seeking: $e');
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      if (_player.hasNext) {
        await _player.seekToNext();
      }
    } catch (e) {
      debugPrintError('Error skipping to next: $e');
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      if (_player.hasPrevious) {
        await _player.seekToPrevious();
      }
    } catch (e) {
      debugPrintError('Error skipping to previous: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
      await super.stop();
    } catch (e) {
      debugPrintError('Error stopping: $e');
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(ja.LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(ja.LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(ja.LoopMode.all);
        break;
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    await _player.setShuffleModeEnabled(enabled);
  }

  /// Dispose all resources
  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    await _player.dispose();
  }

  void debugPrintError(String message) {
    // Use debugPrint to avoid print() in production (N-11)
    assert(() {
      // ignore: avoid_print
      debugPrint('[OnFinityAudio] $message');
      return true;
    }());
  }
}
