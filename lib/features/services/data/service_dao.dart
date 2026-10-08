import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/service_filter_criteria.dart';
import '../models/service_model.dart';
import '../models/service_song_model.dart';

class ServiceDao {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  /// Guarda el servicio y su setlist completo en una sola transacción atómica
  Future<int> createServiceWithSongs(
    ServiceModel service,
    List<ServiceSongModel> songs,
  ) async {
    final db = await _db;

    return await db.transaction<int>((txn) async {
      // 1. Insertar el encabezado del culto
      final serviceId = await txn.insert('services', service.toMap());

      // 2. Insertar cada tema del setlist con su orden y tono tocado
      for (int i = 0; i < songs.length; i++) {
        final song = songs[i];
        final songMap = song.toMap();
        songMap['service_id'] = serviceId;
        songMap['order_index'] =
            i + 1; // Asegurar indexación secuencial (1, 2, 3...)

        await txn.insert('service_songs', songMap);
      }

      return serviceId;
    });
  }

  /// Obtiene los cultos ordenados por fecha descendente
  Future<List<ServiceModel>> getRecentServices({int limit = 30}) async {
    return getFilteredServices(limit: limit);
  }

  /// Obtiene los cultos aplicando filtros opcionales de tipo, rango de fechas y búsqueda
  Future<List<ServiceModel>> getFilteredServices({
    String? serviceType,
    DateTime? startDate,
    DateTime? endDate,
    String? query,
    int? limit,
  }) async {
    final db = await _db;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (serviceType != null &&
        serviceType.trim().isNotEmpty &&
        serviceType != 'Todos') {
      whereClauses.add('s.service_type = ?');
      whereArgs.add(serviceType.trim());
    }

    if (startDate != null) {
      final startStr = startDate.toIso8601String().substring(0, 10);
      whereClauses.add('s.date >= ?');
      whereArgs.add(startStr);
    }

    if (endDate != null) {
      final endStr = endDate.toIso8601String().substring(0, 10);
      whereClauses.add('s.date <= ?');
      whereArgs.add(endStr);
    }

    if (query != null && query.trim().isNotEmpty) {
      final sanitized = '%${query.trim()}%';
      whereClauses.add('''
        (
          s.service_type LIKE ? OR 
          s.notes LIKE ? OR 
          s.id IN (
            SELECT ss2.service_id 
            FROM service_songs ss2 
            INNER JOIN songs s2 ON s2.id = ss2.song_id 
            WHERE s2.title LIKE ? OR s2.artist LIKE ?
          )
        )
      ''');
      whereArgs.addAll([sanitized, sanitized, sanitized, sanitized]);
    }

    final whereSql = whereClauses.isNotEmpty
        ? 'WHERE ${whereClauses.join(' AND ')}'
        : '';

    final limitSql = limit != null ? 'LIMIT ?' : '';
    if (limit != null) {
      whereArgs.add(limit);
    }

    final sql = '''
      SELECT 
        s.id, s.date, s.service_type, s.notes,
        COUNT(ss.id) AS song_count
      FROM services s
      LEFT JOIN service_songs ss ON s.id = ss.service_id
      $whereSql
      GROUP BY s.id
      ORDER BY s.date DESC, s.id DESC
      $limitSql;
    ''';

    final results = await db.rawQuery(
      sql,
      whereArgs.isNotEmpty ? whereArgs : null,
    );

    return results.map((map) => ServiceModel.fromMap(map)).toList();
  }

  /// Consulta cultos por objeto ServiceFilterCriteria
  Future<List<ServiceModel>> getServicesByCriteria(
    ServiceFilterCriteria criteria, {
    int? limit,
  }) {
    final range = criteria.dateRange;
    return getFilteredServices(
      serviceType: criteria.serviceType,
      startDate: range.start,
      endDate: range.end,
      query: criteria.searchQuery,
      limit: limit,
    );
  }

  /// Obtiene los tipos de culto registrados de forma única para poblar los filtros
  Future<List<String>> getDistinctServiceTypes() async {
    final db = await _db;
    final results = await db.rawQuery(
      'SELECT DISTINCT service_type FROM services WHERE service_type IS NOT NULL AND TRIM(service_type) != "" ORDER BY service_type ASC;',
    );
    return results.map((r) => r['service_type'] as String).toList();
  }

  /// Obtiene un culto junto con el setlist hidratado (títulos y artistas de canciones)
  Future<ServiceModel?> getServiceWithSongs(int serviceId) async {
    final db = await _db;

    // 1. Obtener el servicio con song_count
    final serviceRows = await db.rawQuery(
      '''
      SELECT 
        s.id, s.date, s.service_type, s.notes,
        COUNT(ss.id) AS song_count
      FROM services s
      LEFT JOIN service_songs ss ON s.id = ss.service_id
      WHERE s.id = ?
      GROUP BY s.id
      LIMIT 1;
      ''',
      [serviceId],
    );

    if (serviceRows.isEmpty) return null;

    // 2. Obtener el setlist haciendo JOIN con songs para traer títulos y géneros
    final songRows = await db.rawQuery(
      '''
      SELECT 
        ss.id,
        ss.service_id,
        ss.song_id,
        ss.played_key,
        ss.lead_vocal,
        ss.order_index,
        ss.feedback,
        s.title AS song_title,
        s.artist AS song_artist,
        s.category AS category
      FROM service_songs ss
      INNER JOIN songs s ON s.id = ss.song_id
      WHERE ss.service_id = ?
      ORDER BY ss.order_index ASC;
    ''',
      [serviceId],
    );

    final songs = songRows.map((row) => ServiceSongModel.fromMap(row)).toList();
    return ServiceModel.fromMap(serviceRows.first, songs: songs);
  }

  /// Eliminar un culto (ON DELETE CASCADE borra automáticamente su setlist)
  Future<int> deleteService(int serviceId) async {
    final db = await _db;
    return await db.delete('services', where: 'id = ?', whereArgs: [serviceId]);
  }

  Future updateServiceWithSongs(ServiceModel service, List songs) async {
    if (service.id == null) {
      throw ArgumentError('No se puede actualizar un culto sin ID.');
    }

    final db = await _db;

    await db.transaction((txn) async {
      // 1. Actualizar cabecera del culto
      await txn.update(
        'services',
        service.toMap(),
        where: 'id = ?',
        whereArgs: [service.id],
      );

      // 2. Limpiar las canciones anteriores del setlist
      await txn.delete(
        'service_songs',
        where: 'service_id = ?',
        whereArgs: [service.id],
      );

      // 3. Reinsertar el setlist actualizado con su nuevo orden
      for (int i = 0; i < songs.length; i++) {
        final song = songs[i];
        final songMap = song.toMap();
        songMap['service_id'] = service.id;
        songMap['order_index'] = i + 1;

        await txn.insert('service_songs', songMap);
      }
    });
  }
}
