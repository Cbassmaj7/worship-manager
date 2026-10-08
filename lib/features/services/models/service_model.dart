import 'service_song_model.dart';

class ServiceModel {
  final int? id;
  final DateTime date;
  final String serviceType;
  final String? notes;
  final int songCount; // <-- Agregado
  final List<ServiceSongModel> songs;

  const ServiceModel({
    this.id,
    required this.date,
    required this.serviceType,
    this.notes,
    this.songCount = 0,
    this.songs = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String().substring(0, 10), // Guardar 'YYYY-MM-DD'
      'service_type': serviceType.trim(),
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    };
  }

  factory ServiceModel.fromMap(
    Map<String, dynamic> map, {
    List<ServiceSongModel> songs = const [],
  }) {
    final rawCount = map['song_count'];
    final int parsedCount;
    if (rawCount is num) {
      parsedCount = rawCount.toInt();
    } else if (rawCount is String) {
      parsedCount = int.tryParse(rawCount) ?? songs.length;
    } else {
      parsedCount = songs.length;
    }

    return ServiceModel(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      serviceType: map['service_type'] as String,
      notes: map['notes'] as String?,
      songs: songs,
      songCount: parsedCount > 0 ? parsedCount : songs.length,
    );
  }

  ServiceModel copyWith({
    int? id,
    DateTime? date,
    String? serviceType,
    String? notes,
    int? songCount,
    List<ServiceSongModel>? songs,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      date: date ?? this.date,
      serviceType: serviceType ?? this.serviceType,
      notes: notes ?? this.notes,
      songCount: songCount ?? this.songCount,
      songs: songs ?? this.songs,
    );
  }
}
