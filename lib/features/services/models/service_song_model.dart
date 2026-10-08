class ServiceSongModel {
  final int? id;
  final int serviceId;
  final int songId;
  final String playedKey; // Tono en el que se tocó en este culto
  final String leadVocal; // Quién dirigió la canción
  final int orderIndex; // Posición en el orden de alabanza (1, 2, 3...)
  final String? feedback; // Notas acústicas o de dinámica

  // Datos denormalizados para presentación rápida (JOIN con songs)
  final String? songTitle;
  final String? songArtist;
  final String? category;

  const ServiceSongModel({
    this.id,
    required this.serviceId,
    required this.songId,
    required this.playedKey,
    required this.leadVocal,
    required this.orderIndex,
    this.feedback,
    this.songTitle,
    this.songArtist,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'service_id': serviceId,
      'song_id': songId,
      'played_key': playedKey,
      'lead_vocal': leadVocal.trim(),
      'order_index': orderIndex,
      'feedback': feedback?.trim().isEmpty == true ? null : feedback?.trim(),
    };
  }

  factory ServiceSongModel.fromMap(Map<String, dynamic> map) {
    return ServiceSongModel(
      id: map['id'] as int?,
      serviceId: map['service_id'] as int,
      songId: map['song_id'] as int,
      playedKey: map['played_key'] as String,
      leadVocal: map['lead_vocal'] as String,
      orderIndex: map['order_index'] as int,
      feedback: map['feedback'] as String?,
      songTitle: map['song_title'] as String?,
      songArtist: map['song_artist'] as String?,
      category: map['category'] as String?,
    );
  }
}
