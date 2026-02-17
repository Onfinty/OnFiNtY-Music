class SongModel {
  final int id;
  final String title;
  final String artist;
  final String? album;
  final int? albumId;
  final int duration;
  final String uri;
  final String? artUri;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.albumId,
    required this.duration,
    required this.uri,
    this.artUri,
  });

  // M-05: Removed dead fromAudioModel factory

  factory SongModel.fromOnAudioQuery(dynamic audioModel) {
    final int? aId = audioModel.albumId;
    return SongModel(
      id: audioModel.id,
      title: audioModel.title,
      artist: audioModel.artist ?? 'Unknown Artist',
      album: audioModel.album,
      albumId: aId,
      duration: audioModel.duration ?? 0,
      uri: audioModel.uri ?? '',
      artUri: aId != null
          ? 'content://media/external/audio/albumart/$aId'
          : null,
    );
  }

  String get displayArtist => artist == '<unknown>' ? 'Unknown Artist' : artist;

  String get formattedDuration {
    final totalSeconds = duration ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
