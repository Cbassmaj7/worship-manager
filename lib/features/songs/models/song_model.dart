import '../../../core/constants/musical_keys.dart';

enum SongCategory {
  praise('PRAISE', 'Alabanza'),
  worship('WORSHIP', 'Adoración');

  final String dbValue;
  final String label;
  const SongCategory(this.dbValue, this.label);

  static SongCategory fromDb(String value) {
    return SongCategory.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => SongCategory.worship,
    );
  }
}

enum SongStatus {
  suggested('SUGGESTED', 'Sugerida'),
  rehearsing('REHEARSING', 'En Ensayo'),
  active('ACTIVE', 'Activa'),
  archived('ARCHIVED', 'Archivada');

  final String dbValue;
  final String label;
  const SongStatus(this.dbValue, this.label);

  static SongStatus fromDb(String value) {
    return SongStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => SongStatus.suggested,
    );
  }
}

class SongModel {
  final int? id;
  final String title;
  final String artist;
  final String? author;
  final String originalKey;
  final String defaultKey; // <-- TONO HABITUAL DE LA BANDA
  final int? bpm;
  final SongCategory category;
  final SongStatus status;
  final String? referenceUrl;
  final String? notes;
  final DateTime? createdAt;

  const SongModel({
    this.id,
    required this.title,
    required this.artist,
    this.author,
    required this.originalKey,
    required this.defaultKey,
    this.bpm,
    required this.category,
    this.status = SongStatus.suggested,
    this.referenceUrl,
    this.notes,
    this.createdAt,
  });

  SongModel copyWith({
    int? id,
    String? title,
    String? artist,
    String? author,
    String? originalKey,
    String? defaultKey,
    int? bpm,
    SongCategory? category,
    SongStatus? status,
    String? referenceUrl,
    String? notes,
    DateTime? createdAt,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      author: author ?? this.author,
      originalKey: originalKey ?? this.originalKey,
      defaultKey: defaultKey ?? this.defaultKey,
      bpm: bpm ?? this.bpm,
      category: category ?? this.category,
      status: status ?? this.status,
      referenceUrl: referenceUrl ?? this.referenceUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title.trim(),
      'artist': artist.trim(),
      'author': author?.trim().isEmpty == true ? null : author?.trim(),
      'original_key': MusicalKeys.normalize(originalKey),
      'default_key': MusicalKeys.normalize(defaultKey),
      'bpm': bpm,
      'category': category.dbValue,
      'status': status.dbValue,
      'reference_url': referenceUrl?.trim().isEmpty == true
          ? null
          : referenceUrl?.trim(),
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    };
  }

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      artist: map['artist'] as String,
      author: map['author'] as String?,
      originalKey: map['original_key'] as String,
      defaultKey:
          map['default_key'] as String? ?? map['original_key'] as String,
      bpm: map['bpm'] as int?,
      category: SongCategory.fromDb(map['category'] as String),
      status: SongStatus.fromDb(map['status'] as String),
      referenceUrl: map['reference_url'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }
}
