import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/analytics_dtos.dart';

class AnalyticsDao {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  /// 1. Canciones más tocadas de todos los tiempos o últimos meses
  Future<List<MostPlayedStat>> getMostPlayedSongs({int limit = 10}) async {
    final db = await _db;
    final results = await db.rawQuery(
      '''
      SELECT 
        s.id,
        s.title,
        s.artist,
        s.default_key,
        s.category,
        COUNT(ss.id) AS total_played
      FROM songs s
      INNER JOIN service_songs ss ON s.id = ss.song_id
      GROUP BY s.id
      ORDER BY total_played DESC, s.title ASC
      LIMIT ?;
    ''',
      [limit],
    );

    return results.map((row) => MostPlayedStat.fromMap(row)).toList();
  }

  /// 2. Últimas canciones tocadas en cultos recientes
  Future<List<RecentlyPlayedStat>> getRecentlyPlayedSongs({
    int limit = 15,
  }) async {
    final db = await _db;
    // Obtenemos la última ejecución de cada canción usando una subconsulta correlacionada
    final results = await db.rawQuery(
      '''
      SELECT 
        s.id,
        s.title,
        s.artist,
        s.default_key,
        s.category,
        srv.date AS last_played_date,
        ss.played_key,
        ss.lead_vocal
      FROM service_songs ss
      INNER JOIN services srv ON srv.id = ss.service_id
      INNER JOIN songs s ON s.id = ss.song_id
      WHERE ss.id IN (
        SELECT ss2.id 
        FROM service_songs ss2
        INNER JOIN services srv2 ON srv2.id = ss2.service_id
        WHERE ss2.song_id = s.id
        ORDER BY srv2.date DESC, ss2.id DESC
        LIMIT 1
      )
      ORDER BY srv.date DESC, ss.id DESC
      LIMIT ?;
    ''',
      [limit],
    );

    return results.map((row) => RecentlyPlayedStat.fromMap(row)).toList();
  }

  /// 3. Radar de olvido: Canciones activas con más de X días sin tocarse o que nunca debutaron
  Future<List<ForgottenSongStat>> getForgottenSongs({
    int thresholdDays = 45,
  }) async {
    final db = await _db;
    final results = await db.rawQuery(
      '''
      SELECT 
        s.id,
        s.title,
        s.artist,
        s.default_key,
        s.category,
        MAX(srv.date) AS last_played_date,
        CAST(
          ROUND(
            julianday('now', 'localtime') - julianday(COALESCE(MAX(srv.date), substr(s.created_at, 1, 10)))
          ) AS INTEGER
        ) AS days_dormant
      FROM songs s
      LEFT JOIN service_songs ss ON s.id = ss.song_id
      LEFT JOIN services srv ON srv.id = ss.service_id
      WHERE s.status = 'ACTIVE'
      GROUP BY s.id
      HAVING MAX(srv.date) IS NULL OR days_dormant >= ?
      ORDER BY days_dormant DESC;
    ''',
      [thresholdDays],
    );

    return results.map((row) => ForgottenSongStat.fromMap(row)).toList();
  }

  Future<RotationPlan> getRotationPlan() async {
    final db = await _db;

    // 1. Alabanzas recomendadas para rotar (activas, ordenadas por días sin tocarse)
    final praiseRows = await db.rawQuery('''
    SELECT 
      s.id, s.title, s.artist, s.default_key, s.category, s.bpm,
      MAX(srv.date) AS last_played_date,
      CAST(ROUND(julianday('now', 'localtime') - julianday(COALESCE(MAX(srv.date), substr(s.created_at, 1, 10)))) AS INTEGER) AS days_dormant
    FROM songs s
    LEFT JOIN service_songs ss ON s.id = ss.song_id
    LEFT JOIN services srv ON srv.id = ss.service_id
    WHERE s.status = 'ACTIVE' AND s.category = 'PRAISE'
    GROUP BY s.id
    ORDER BY days_dormant DESC
    LIMIT 3;
  ''');

    // 2. Adoraciones recomendadas para rotar
    final worshipRows = await db.rawQuery('''
    SELECT 
      s.id, s.title, s.artist, s.default_key, s.category, s.bpm,
      MAX(srv.date) AS last_played_date,
      CAST(ROUND(julianday('now', 'localtime') - julianday(COALESCE(MAX(srv.date), substr(s.created_at, 1, 10)))) AS INTEGER) AS days_dormant
    FROM songs s
    LEFT JOIN service_songs ss ON s.id = ss.song_id
    LEFT JOIN services srv ON srv.id = ss.service_id
    WHERE s.status = 'ACTIVE' AND s.category = 'WORSHIP'
    GROUP BY s.id
    ORDER BY days_dormant DESC
    LIMIT 3;
  ''');

    // 3. Canciones en ensayo o sugeridas para implementar
    final pipelineRows = await db.rawQuery('''
    SELECT id, title, artist, default_key, category, status, reference_url, notes
    FROM songs
    WHERE status IN ('REHEARSING', 'SUGGESTED')
    ORDER BY status ASC, id DESC;
  ''');

    final praises = praiseRows
        .map(
          (r) => RotationRecommendation(
            songId: r['id'] as int,
            title: r['title'] as String,
            artist: r['artist'] as String,
            defaultKey: r['default_key'] as String,
            category: r['category'] as String,
            bpm: r['bpm'] as int?,
            daysDormant: (r['days_dormant'] as num).toInt(),
            lastPlayedDate: r['last_played_date'] as String?,
          ),
        )
        .toList();

    final worships = worshipRows
        .map(
          (r) => RotationRecommendation(
            songId: r['id'] as int,
            title: r['title'] as String,
            artist: r['artist'] as String,
            defaultKey: r['default_key'] as String,
            category: r['category'] as String,
            bpm: r['bpm'] as int?,
            daysDormant: (r['days_dormant'] as num).toInt(),
            lastPlayedDate: r['last_played_date'] as String?,
          ),
        )
        .toList();

    final inRehearsal = <PipelineSong>[];
    final inSuggested = <PipelineSong>[];

    for (final row in pipelineRows) {
      final item = PipelineSong(
        id: row['id'] as int,
        title: row['title'] as String,
        artist: row['artist'] as String,
        defaultKey: row['default_key'] as String,
        category: row['category'] as String,
        status: row['status'] as String,
        referenceUrl: row['reference_url'] as String?,
        notes: row['notes'] as String?,
      );
      if (item.status == 'REHEARSING') {
        inRehearsal.add(item);
      } else {
        inSuggested.add(item);
      }
    }

    return RotationPlan(
      suggestedPraises: praises,
      suggestedWorships: worships,
      inRehearsal: inRehearsal,
      inSuggested: inSuggested,
    );
  }
}
