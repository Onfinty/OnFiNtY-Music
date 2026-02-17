import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../models/song_model.dart';
import 'audio_fx_bridge.dart';
import 'preferences_service.dart';

enum AudioQuickPreset { normal, slowedReverb, spedUp, custom }

enum AudioEqualizerPreset { flat, bassBoost, vocal, trebleBoost }

@immutable
class AudioEffectsState {
  AudioEffectsState({
    required this.quickPreset,
    required this.speed,
    required this.pitch,
    required this.equalizerEnabled,
    required this.reverbEnabled,
    required this.reverbPresetId,
    required List<double> bandLevelsDb,
    required this.nativeFxAvailable,
  }) : bandLevelsDb = List<double>.unmodifiable(bandLevelsDb);

  factory AudioEffectsState.initial({
    int bandCount = 5,
    required bool nativeFxAvailable,
  }) {
    return AudioEffectsState(
      quickPreset: AudioQuickPreset.normal,
      speed: 1.0,
      pitch: 1.0,
      equalizerEnabled: false,
      reverbEnabled: false,
      reverbPresetId: _mediumRoomPresetId,
      bandLevelsDb: List<double>.filled(bandCount, 0.0),
      nativeFxAvailable: nativeFxAvailable,
    );
  }

  final AudioQuickPreset quickPreset;
  final double speed;
  final double pitch;
  final bool equalizerEnabled;
  final bool reverbEnabled;
  final int reverbPresetId;
  final List<double> bandLevelsDb;
  final bool nativeFxAvailable;

  AudioEffectsState copyWith({
    AudioQuickPreset? quickPreset,
    double? speed,
    double? pitch,
    bool? equalizerEnabled,
    bool? reverbEnabled,
    int? reverbPresetId,
    List<double>? bandLevelsDb,
    bool? nativeFxAvailable,
  }) {
    return AudioEffectsState(
      quickPreset: quickPreset ?? this.quickPreset,
      speed: speed ?? this.speed,
      pitch: pitch ?? this.pitch,
      equalizerEnabled: equalizerEnabled ?? this.equalizerEnabled,
      reverbEnabled: reverbEnabled ?? this.reverbEnabled,
      reverbPresetId: reverbPresetId ?? this.reverbPresetId,
      bandLevelsDb: bandLevelsDb ?? this.bandLevelsDb,
      nativeFxAvailable: nativeFxAvailable ?? this.nativeFxAvailable,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'quickPreset': quickPreset.name,
      'speed': speed,
      'pitch': pitch,
      'equalizerEnabled': equalizerEnabled,
      'reverbEnabled': reverbEnabled,
      'reverbPresetId': reverbPresetId,
      'bandLevelsDb': bandLevelsDb,
    };
  }

  static AudioEffectsState fromJson(
    Map<String, dynamic> json, {
    required bool nativeFxAvailable,
    required int bandCount,
  }) {
    final parsedPreset = _audioQuickPresetFromString(
      json['quickPreset'] as String?,
    );
    final speed = _clampDouble(
      json['speed'],
      min: 0.5,
      max: 2.0,
      fallback: 1.0,
    );
    final pitch = _clampDouble(
      json['pitch'],
      min: 0.7,
      max: 1.4,
      fallback: 1.0,
    );
    final equalizerEnabled = json['equalizerEnabled'] == true;
    final reverbEnabled = json['reverbEnabled'] == true;
    final reverbPresetId =
        (json['reverbPresetId'] as num?)?.toInt() ?? _mediumRoomPresetId;
    final bandLevelsDb = _parseBandLevels(
      json['bandLevelsDb'],
      bandCount: bandCount,
    );

    return AudioEffectsState(
      quickPreset: parsedPreset,
      speed: speed,
      pitch: pitch,
      equalizerEnabled: equalizerEnabled,
      reverbEnabled: reverbEnabled,
      reverbPresetId: reverbPresetId,
      bandLevelsDb: bandLevelsDb,
      nativeFxAvailable: nativeFxAvailable,
    );
  }

  static double _clampDouble(
    Object? value, {
    required double min,
    required double max,
    required double fallback,
  }) {
    if (value is! num) {
      return fallback;
    }
    return value.toDouble().clamp(min, max).toDouble();
  }

  static List<double> _parseBandLevels(Object? raw, {required int bandCount}) {
    final defaultBands = List<double>.filled(bandCount, 0.0);
    if (raw is! List) {
      return defaultBands;
    }

    final parsed = <double>[];
    for (final value in raw) {
      if (value is num) {
        parsed.add(value.toDouble().clamp(_minEqDb, _maxEqDb).toDouble());
      }
    }

    if (parsed.isEmpty) {
      return defaultBands;
    }

    if (parsed.length == bandCount) {
      return parsed;
    }

    return _remapBandLevels(parsed, bandCount);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AudioEffectsState &&
        other.quickPreset == quickPreset &&
        other.speed == speed &&
        other.pitch == pitch &&
        other.equalizerEnabled == equalizerEnabled &&
        other.reverbEnabled == reverbEnabled &&
        other.reverbPresetId == reverbPresetId &&
        other.nativeFxAvailable == nativeFxAvailable &&
        listEquals(other.bandLevelsDb, bandLevelsDb);
  }

  @override
  int get hashCode {
    return Object.hash(
      quickPreset,
      speed,
      pitch,
      equalizerEnabled,
      reverbEnabled,
      reverbPresetId,
      nativeFxAvailable,
      Object.hashAll(bandLevelsDb),
    );
  }
}

AudioQuickPreset _audioQuickPresetFromString(String? value) {
  for (final preset in AudioQuickPreset.values) {
    if (preset.name == value) {
      return preset;
    }
  }
  return AudioQuickPreset.normal;
}

List<double> _remapBandLevels(List<double> source, int targetBands) {
  if (targetBands <= 0) {
    return <double>[];
  }
  if (source.isEmpty) {
    return List<double>.filled(targetBands, 0.0);
  }
  if (source.length == targetBands) {
    return List<double>.from(source);
  }

  return List<double>.generate(targetBands, (index) {
    if (targetBands == 1) {
      return source.first;
    }
    final position = index / (targetBands - 1);
    final mapped = (position * (source.length - 1)).round();
    return source[mapped.clamp(0, source.length - 1).toInt()];
  });
}

const double _minEqDb = -12.0;
const double _maxEqDb = 12.0;
const int _largeHallPresetId = 5;
const int _mediumRoomPresetId = 2;

/// Production-grade AudioHandler implementing BaseAudioHandler.
/// Handles background playback, notification controls, media buttons,
/// audio focus, and all playback operations.
class OnFinityAudioHandler extends BaseAudioHandler with SeekHandler {
  static const int _defaultBandCount = 5;

  final ja.AudioPlayer _player = ja.AudioPlayer();
  final AudioFxBridge _audioFxBridge = AudioFxBridge();
  final StreamController<AudioEffectsState> _audioEffectsController =
      StreamController<AudioEffectsState>.broadcast();
  final List<SongModel> _songPlaylist = [];
  bool _isReplacingQueue = false;
  int? _pendingTargetIndex;
  int? _activeAudioSessionId;
  bool _pitchSupported = true;
  Future<void> _effectMutationQueue = Future<void>.value();
  AudioEffectsState _audioEffectsState = AudioEffectsState.initial(
    bandCount: _defaultBandCount,
    nativeFxAvailable: false,
  );

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
  Stream<AudioEffectsState> get audioEffectsStateStream async* {
    yield _audioEffectsState;
    yield* _audioEffectsController.stream;
  }

  AudioEffectsState get audioEffectsState => _audioEffectsState;

  OnFinityAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    final nativeFxAvailable = _audioFxBridge.isSupported;
    _audioEffectsState = _audioEffectsState.copyWith(
      nativeFxAvailable: nativeFxAvailable,
    );
    _emitAudioEffectsState();

    await _loadAudioEffectsState();

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

    // Attach Android-native effects whenever audio session changes.
    _subscriptions.add(
      _player.androidAudioSessionIdStream.listen((sessionId) {
        unawaited(
          _runEffectMutation(() => _attachEffectsToAudioSession(sessionId)),
        );
      }),
    );

    await _runEffectMutation(() async {
      final appliedPitch = await _applySpeedAndPitchSmooth(
        speed: _audioEffectsState.speed,
        pitch: _audioEffectsState.pitch,
      );
      _audioEffectsState = _audioEffectsState.copyWith(pitch: appliedPitch);
      _emitAudioEffectsState();
    });
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
    await _runEffectMutation(() async {
      final clampedSpeed = speed.clamp(0.5, 2.0);
      final appliedPitch = await _applySpeedAndPitchSmooth(
        speed: clampedSpeed.toDouble(),
        pitch: _audioEffectsState.pitch,
      );
      _audioEffectsState = _audioEffectsState.copyWith(
        speed: clampedSpeed.toDouble(),
        pitch: appliedPitch,
        quickPreset: AudioQuickPreset.custom,
      );
      _emitAudioEffectsState();
      await _saveAudioEffectsState();
    });
  }

  Future<void> applyQuickPreset(AudioQuickPreset preset) async {
    await _runEffectMutation(() async {
      final current = _audioEffectsState;
      double targetSpeed = current.speed;
      double targetPitch = current.pitch;
      var targetReverb = current.reverbEnabled;
      var targetReverbPresetId = current.reverbPresetId;

      switch (preset) {
        case AudioQuickPreset.normal:
          targetSpeed = 1.0;
          targetPitch = 1.0;
          targetReverb = false;
          targetReverbPresetId = _mediumRoomPresetId;
          break;
        case AudioQuickPreset.slowedReverb:
          targetSpeed = 0.86;
          targetPitch = 0.92;
          targetReverb = true;
          targetReverbPresetId = _largeHallPresetId;
          break;
        case AudioQuickPreset.spedUp:
          targetSpeed = 1.18;
          targetPitch = 1.08;
          targetReverb = false;
          targetReverbPresetId = _mediumRoomPresetId;
          break;
        case AudioQuickPreset.custom:
          break;
      }

      final appliedPitch = await _applySpeedAndPitchSmooth(
        speed: targetSpeed,
        pitch: targetPitch,
      );

      _audioEffectsState = _audioEffectsState.copyWith(
        quickPreset: preset,
        speed: targetSpeed,
        pitch: appliedPitch,
        reverbEnabled: targetReverb,
        reverbPresetId: targetReverbPresetId,
      );

      await _applyNativeEffectsState();
      _emitAudioEffectsState();
      await _saveAudioEffectsState();
    });
  }

  Future<void> setEqualizerEnabled(bool enabled) async {
    await _runEffectMutation(() async {
      _audioEffectsState = _audioEffectsState.copyWith(
        equalizerEnabled: enabled,
      );
      await _applyNativeEffectsState();
      _emitAudioEffectsState();
      await _saveAudioEffectsState();
    });
  }

  Future<void> setReverbEnabled(bool enabled) async {
    await _runEffectMutation(() async {
      _audioEffectsState = _audioEffectsState.copyWith(
        reverbEnabled: enabled,
        quickPreset: AudioQuickPreset.custom,
      );
      await _applyNativeEffectsState();
      _emitAudioEffectsState();
      await _saveAudioEffectsState();
    });
  }

  Future<void> setEqualizerBandLevel(int bandIndex, double levelDb) async {
    await _runEffectMutation(() async {
      final clampedBandLevel = levelDb.clamp(_minEqDb, _maxEqDb);
      final currentBands = _audioEffectsState.bandLevelsDb;
      if (bandIndex < 0 || bandIndex >= currentBands.length) {
        return;
      }

      final updatedBands = List<double>.from(currentBands);
      updatedBands[bandIndex] = clampedBandLevel.toDouble();

      _audioEffectsState = _audioEffectsState.copyWith(
        bandLevelsDb: updatedBands,
        quickPreset: AudioQuickPreset.custom,
      );
      await _applyNativeEffectsState();
      _emitAudioEffectsState();
      await _saveAudioEffectsState();
    });
  }

  Future<void> applyEqualizerPreset(AudioEqualizerPreset preset) async {
    await _runEffectMutation(() async {
      final targetBands = _buildEqualizerPresetBands(
        preset,
        _audioEffectsState.bandLevelsDb.length,
      );
      _audioEffectsState = _audioEffectsState.copyWith(
        equalizerEnabled: true,
        bandLevelsDb: targetBands,
        quickPreset: AudioQuickPreset.custom,
      );
      await _applyNativeEffectsState();
      _emitAudioEffectsState();
      await _saveAudioEffectsState();
    });
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    await _player.setShuffleModeEnabled(enabled);
  }

  Future<void> _loadAudioEffectsState() async {
    final rawState = await PreferencesService.getAudioEffectsState();
    if (rawState.isEmpty) {
      return;
    }

    _audioEffectsState = AudioEffectsState.fromJson(
      rawState,
      nativeFxAvailable: _audioFxBridge.isSupported,
      bandCount: _defaultBandCount,
    );
    _emitAudioEffectsState();
  }

  Future<void> _saveAudioEffectsState() async {
    await PreferencesService.saveAudioEffectsState(_audioEffectsState.toJson());
  }

  Future<void> _attachEffectsToAudioSession(int? sessionId) async {
    if (!_audioFxBridge.isSupported || sessionId == null || sessionId <= 0) {
      return;
    }
    if (_activeAudioSessionId == sessionId) {
      return;
    }

    _activeAudioSessionId = sessionId;
    await _audioFxBridge.attachToSession(sessionId);
    await _applyNativeEffectsState();
  }

  Future<void> _applyNativeEffectsState() async {
    if (!_audioFxBridge.isSupported) {
      return;
    }

    final state = _audioEffectsState;
    await _audioFxBridge.setEqualizerEnabled(state.equalizerEnabled);
    for (var i = 0; i < state.bandLevelsDb.length; i++) {
      await _audioFxBridge.setBandLevel(i, state.bandLevelsDb[i]);
    }
    await _audioFxBridge.setReverbPreset(state.reverbPresetId);
    await _audioFxBridge.setReverbEnabled(state.reverbEnabled);
  }

  Future<double> _applySpeedAndPitchSmooth({
    required double speed,
    required double pitch,
  }) async {
    final targetSpeed = speed.clamp(0.5, 2.0);
    final targetPitch = pitch.clamp(0.7, 1.4);
    final originalVolume = _player.volume.clamp(0.0, 1.0).toDouble();
    final isPlaying = _player.playing;

    if (isPlaying) {
      await _player.setVolume(
        (originalVolume * 0.78).clamp(0.0, 1.0).toDouble(),
      );
    }

    final appliedPitch = await _safeSetPitch(targetPitch.toDouble());
    await _player.setSpeed(targetSpeed.toDouble());

    if (isPlaying) {
      for (final step in <double>[0.86, 0.94, 1.0]) {
        await Future<void>.delayed(const Duration(milliseconds: 26));
        await _player.setVolume(
          (originalVolume * step).clamp(0.0, 1.0).toDouble(),
        );
      }
      await _player.setVolume(originalVolume);
    }

    return appliedPitch;
  }

  Future<double> _safeSetPitch(double pitch) async {
    if (!_pitchSupported) {
      return 1.0;
    }

    try {
      await _player.setPitch(pitch);
      return pitch;
    } catch (e) {
      _pitchSupported = false;
      debugPrintError('Pitch controls are not supported on this platform: $e');
      return 1.0;
    }
  }

  Future<void> _runEffectMutation(Future<void> Function() mutation) {
    final next = _effectMutationQueue.then((_) => mutation());
    _effectMutationQueue = next.catchError((Object e, StackTrace st) {
      debugPrintError('Audio effects mutation failed: $e');
    });
    return next;
  }

  List<double> _buildEqualizerPresetBands(
    AudioEqualizerPreset preset,
    int bandCount,
  ) {
    final base = switch (preset) {
      AudioEqualizerPreset.flat => const <double>[0.0, 0.0, 0.0, 0.0, 0.0],
      AudioEqualizerPreset.bassBoost => const <double>[
        6.0,
        4.0,
        1.5,
        -1.0,
        -2.0,
      ],
      AudioEqualizerPreset.vocal => const <double>[-1.5, 1.0, 4.5, 4.0, 1.5],
      AudioEqualizerPreset.trebleBoost => const <double>[
        -2.0,
        -0.5,
        1.0,
        4.0,
        6.5,
      ],
    };
    return _remapBandLevels(
      base,
      bandCount,
    ).map((level) => level.clamp(_minEqDb, _maxEqDb).toDouble()).toList();
  }

  void _emitAudioEffectsState() {
    if (_audioEffectsController.isClosed) {
      return;
    }
    _audioEffectsController.add(_audioEffectsState);
  }

  /// Dispose all resources
  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    await _audioEffectsController.close();
    await _audioFxBridge.release();
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
