class MostPlayedStat {
  final int songId;
  final String title;
  final String artist;
  final String defaultKey;
  final String category;
  final int totalPlayed;

  const MostPlayedStat({
    required this.songId,
    required this.title,
    required this.artist,
    required this.defaultKey,
    required this.category,
    required this.totalPlayed,
  });

  factory MostPlayedStat.fromMap(Map<String, dynamic> map) {
    return MostPlayedStat(
      songId: map['id'] as int,
      title: map['title'] as String,
      artist: map['artist'] as String,
      defaultKey: map['default_key'] as String,
      category: map['category'] as String,
      totalPlayed: map['total_played'] as int,
    );
  }
}

class RecentlyPlayedStat {
  final int songId;
  final String title;
  final String artist;
  final String defaultKey;
  final String category;
  final String lastPlayedDate;
  final String lastPlayedKey;
  final String lastLeadVocal;

  const RecentlyPlayedStat({
    required this.songId,
    required this.title,
    required this.artist,
    required this.defaultKey,
    required this.category,
    required this.lastPlayedDate,
    required this.lastPlayedKey,
    required this.lastLeadVocal,
  });

  factory RecentlyPlayedStat.fromMap(Map<String, dynamic> map) {
    return RecentlyPlayedStat(
      songId: map['id'] as int,
      title: map['title'] as String,
      artist: map['artist'] as String,
      defaultKey: map['default_key'] as String,
      category: map['category'] as String,
      lastPlayedDate: map['last_played_date'] as String,
      lastPlayedKey: map['played_key'] as String,
      lastLeadVocal: map['lead_vocal'] as String,
    );
  }
}

class ForgottenSongStat {
  final int songId;
  final String title;
  final String artist;
  final String defaultKey;
  final String category;
  final String? lastPlayedDate;
  final int daysDormant;

  const ForgottenSongStat({
    required this.songId,
    required this.title,
    required this.artist,
    required this.defaultKey,
    required this.category,
    this.lastPlayedDate,
    required this.daysDormant,
  });

  factory ForgottenSongStat.fromMap(Map<String, dynamic> map) {
    return ForgottenSongStat(
      songId: map['id'] as int,
      title: map['title'] as String,
      artist: map['artist'] as String,
      defaultKey: map['default_key'] as String,
      category: map['category'] as String,
      lastPlayedDate: map['last_played_date'] as String?,
      daysDormant: (map['days_dormant'] as num).toInt(),
    );
  }
}

class RotationRecommendation {
  final int songId;
  final String title;
  final String artist;
  final String defaultKey;
  final String category;
  final int? bpm;
  final int daysDormant;
  final String? lastPlayedDate;

  const RotationRecommendation({
    required this.songId,
    required this.title,
    required this.artist,
    required this.defaultKey,
    required this.category,
    this.bpm,
    required this.daysDormant,
    this.lastPlayedDate,
  });
}

class PipelineSong {
  final int id;
  final String title;
  final String artist;
  final String defaultKey;
  final String category;
  final String status;
  final String? referenceUrl;
  final String? notes;

  const PipelineSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.defaultKey,
    required this.category,
    required this.status,
    this.referenceUrl,
    this.notes,
  });
}

class RotationPlan {
  final List<RotationRecommendation> suggestedPraises;
  final List<RotationRecommendation> suggestedWorships;
  final List<PipelineSong> inRehearsal;
  final List<PipelineSong> inSuggested;

  const RotationPlan({
    required this.suggestedPraises,
    required this.suggestedWorships,
    required this.inRehearsal,
    required this.inSuggested,
  });
}
