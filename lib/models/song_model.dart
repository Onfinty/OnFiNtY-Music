class SongModel {
  final int id;
  final String title;
  final String artist;
  final String? album;
  final int duration;
  final String uri;
  final String? artUri;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.duration,
    required this.uri,
    this.artUri,
  });

  factory SongModel.fromAudioModel(SongModel song) {
    return SongModel(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: song.duration,
      uri: song.uri,
      artUri: song.artUri,
    );
  }

  factory SongModel.fromOnAudioQuery(dynamic audioModel) {
    return SongModel(
      id: audioModel.id,
      title: audioModel.title,
      artist: audioModel.artist ?? 'Unknown Artist',
      album: audioModel.album,
      duration: audioModel.duration ?? 0,
      uri: audioModel.uri ?? '',
      artUri: audioModel.uri,
    );
  }

  String get displayArtist => artist == '<unknown>' ? 'Unknown Artist' : artist;

  String get formattedDuration {
    final minutes = duration ~/ 60000;
    final seconds = (duration % 60000) ~/ 1000;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
