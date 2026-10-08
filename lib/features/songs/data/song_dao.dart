import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/song_filter_criteria.dart';
import '../models/song_model.dart';

class SongDao {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  /// Inserta una canción y retorna el ID autogenerado
  Future<int> insert(SongModel song) async {
    final db = await _db;
    return await db.insert(
      'songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Actualiza los datos maestros de una canción existente
  Future<int> update(SongModel song) async {
    if (song.id == null) {
      throw ArgumentError(
        'No se puede actualizar una canción sin ID asignado.',
      );
    }
    final db = await _db;
    return await db.update(
      'songs',
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }

  /// Cambio atómico de estado (ej: de SUGGESTED a REHEARSING o ACTIVE)
  Future<int> updateStatus(int songId, SongStatus newStatus) async {
    final db = await _db;
    return await db.update(
      'songs',
      {'status': newStatus.dbValue},
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

  /// Eliminación protegida: verifica que la canción no tenga ejecuciones en vivo asociadas
  Future<void> delete(int songId) async {
    final db = await _db;

    // Verificar si ya fue tocada en algún culto para no quebrar la trazabilidad histórica
    final historyCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM service_songs WHERE song_id = ?;',
            [songId],
          ),
        ) ??
        0;

    if (historyCount > 0) {
      throw Exception(
        'No puedes borrar esta canción porque ya fue tocada en $historyCount culto(s). '
        'En su lugar, cámbiale el estado a ARCHIVADA.',
      );
    }

    await db.delete('songs', where: 'id = ?', whereArgs: [songId]);
  }

  /// Consulta flexible con filtros múltiples y stackeables
  Future<List<SongModel>> getSongs({
    SongStatus? status,
    SongCategory? category,
    String? query,
    Set<String>? keys,
    bool matchBandKeyOnly = true,
    DateTime? createdAfter,
    DateTime? createdBefore,
    PlayedFilterOption? playedFilter,
    String orderBy = 'title ASC',
  }) async {
    final db = await _db;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (status != null) {
      whereClauses.add('status = ?');
      whereArgs.add(status.dbValue);
    }

    if (category != null) {
      whereClauses.add('category = ?');
      whereArgs.add(category.dbValue);
    }

    if (query != null && query.trim().isNotEmpty) {
      final sanitizedQuery = '%${query.trim()}%';
      whereClauses.add('(title LIKE ? OR artist LIKE ? OR author LIKE ?)');
      whereArgs.addAll([sanitizedQuery, sanitizedQuery, sanitizedQuery]);
    }

    if (keys != null && keys.isNotEmpty) {
      final placeholders = List.filled(keys.length, '?').join(', ');
      if (matchBandKeyOnly) {
        whereClauses.add('default_key IN ($placeholders)');
        whereArgs.addAll(keys);
      } else {
        whereClauses.add(
          '(default_key IN ($placeholders) OR original_key IN ($placeholders))',
        );
        whereArgs.addAll(keys);
        whereArgs.addAll(keys);
      }
    }

    if (createdAfter != null) {
      final afterStr = createdAfter.toIso8601String().substring(0, 10);
      whereClauses.add('substr(created_at, 1, 10) >= ?');
      whereArgs.add(afterStr);
    }

    if (createdBefore != null) {
      final beforeStr = createdBefore.toIso8601String().substring(0, 10);
      whereClauses.add('substr(created_at, 1, 10) <= ?');
      whereArgs.add(beforeStr);
    }

    if (playedFilter != null && playedFilter != PlayedFilterOption.any) {
      switch (playedFilter) {
        case PlayedFilterOption.recentlyPlayed:
          whereClauses.add('''
            id IN (
              SELECT ss.song_id 
              FROM service_songs ss 
              INNER JOIN services srv ON srv.id = ss.service_id 
              WHERE julianday('now', 'localtime') - julianday(srv.date) <= 30
            )
          ''');
          break;
        case PlayedFilterOption.dormant:
          whereClauses.add('''
            id NOT IN (
              SELECT ss.song_id 
              FROM service_songs ss 
              INNER JOIN services srv ON srv.id = ss.service_id 
              WHERE julianday('now', 'localtime') - julianday(srv.date) <= 45
            )
          ''');
          break;
        case PlayedFilterOption.neverPlayed:
          whereClauses.add(
            'id NOT IN (SELECT DISTINCT song_id FROM service_songs)',
          );
          break;
        case PlayedFilterOption.any:
          break;
      }
    }

    final whereString =
        whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final results = await db.query(
      'songs',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );

    return results.map((map) => SongModel.fromMap(map)).toList();
  }

  /// Consulta por objeto de criterios stackeables SongFilterCriteria
  Future<List<SongModel>> getSongsByCriteria({
    required SongFilterCriteria criteria,
    SongStatus? status,
    String? query,
    String orderBy = 'title ASC',
  }) {
    final range = criteria.createdDateRange;
    return getSongs(
      status: status,
      category: criteria.category,
      query: query,
      keys: criteria.keys,
      matchBandKeyOnly: criteria.matchBandKeyOnly,
      createdAfter: range.start,
      createdBefore: range.end,
      playedFilter: criteria.playedFilter,
      orderBy: orderBy,
    );
  }

  /// Obtiene una canción específica por ID
  Future<SongModel?> getById(int id) async {
    final db = await _db;
    final results = await db.query(
      'songs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return SongModel.fromMap(results.first);
  }
}
