
import 'package:just_audio/just_audio.dart' as ja;
import 'package:audio_service/audio_service.dart';
import '../models/song_model.dart';

class AudioPlayerService {
  final ja.AudioPlayer _audioPlayer = ja.AudioPlayer();
  List<SongModel> _playlist = [];
  int _currentIndex = 0;

  ja.AudioPlayer get audioPlayer => _audioPlayer;
  List<SongModel> get playlist => _playlist;
  int get currentIndex => _currentIndex;

  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<ja.PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  Future<void> setPlaylist(List<SongModel> songs, int startIndex) async {
    _playlist = songs;
    _currentIndex = startIndex;
    
    final audioSource = ja.ConcatenatingAudioSource(
      children: songs.map((song) {
        return ja.AudioSource.uri(
          Uri.parse(song.uri),
          tag: MediaItem(
            id: song.id.toString(),
            title: song.title,
            artist: song.displayArtist,
            album: song.album,
            duration: Duration(milliseconds: song.duration),
            artUri: song.artUri != null ? Uri.parse(song.artUri!) : null,
          ),
        );
      }).toList(),
    );

    await _audioPlayer.setAudioSource(audioSource, initialIndex: startIndex);
  }

  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> skipToNext() async {
    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
      await _audioPlayer.seekToNext();
    }
  }

  Future<void> skipToPrevious() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      await _audioPlayer.seekToPrevious();
    }
  }

  Future<void> setLoopMode(LoopMode mode) async {
    switch (mode) {
      case LoopMode.off:
        await _audioPlayer.setLoopMode(ja.LoopMode.off);
        break;
      case LoopMode.one:
        await _audioPlayer.setLoopMode(ja.LoopMode.one);
        break;
      case LoopMode.all:
        await _audioPlayer.setLoopMode(ja.LoopMode.all);
        break;
    }
  }

  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}

enum LoopMode {
  off,
  one,
  all,
}