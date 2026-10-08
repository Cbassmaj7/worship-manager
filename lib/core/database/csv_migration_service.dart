import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/musical_keys.dart';
import 'database_helper.dart';

class MigrationResult {
  final int totalSongs;
  final int totalServices;
  final int totalHistories;

  const MigrationResult({
    required this.totalSongs,
    required this.totalServices,
    required this.totalHistories,
  });
}

class CsvMigrationService {
  /// Selecciona el archivo .csv y ejecuta la migración relacional
  static Future<MigrationResult?> pickAndImportCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    final file = File(result.files.single.path!);
    final rawText = await file.readAsString(encoding: utf8);
    return await importCsvString(rawText);
  }

  /// Parsea el texto del CSV y crea registros de canciones y cultos
  static Future<MigrationResult> importCsvString(String csvContent) async {
    final db = await DatabaseHelper.instance.database;

    final List<List<dynamic>> rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(csvContent);

    if (rows.length <= 1) {
      throw Exception('El archivo CSV no contiene registros suficientes.');
    }

    int songsCount = 0;
    int servicesCount = 0;
    int historyCount = 0;

    // Cache para reutilizar cultos por fecha (YYYY-MM-DD -> service_id)
    final Map<String, int> dateToServiceId = {};
    final Map<int, int> serviceSongCounter = {};

    await db.transaction((txn) async {
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row[0].toString().trim().isEmpty) continue;

        // Lectura de columnas del CSV
        final title = row[1].toString().trim();
        if (title.isEmpty) continue;

        final rawTone = row[2].toString().trim();
        final rawTempo = row[3].toString().trim();
        final artist = row[4].toString().trim().isEmpty
            ? 'Desconocido'
            : row[4].toString().trim();
        final hipervinculo = row[5].toString().trim();
        final urlCol = row[6].toString().trim();
        final catRaw = row[7].toString().trim().toLowerCase();
        final dateRaw = row.length > 8 ? row[8].toString().trim() : '';

        // Normalizaciones
        final tone = MusicalKeys.normalize(rawTone.isEmpty ? 'G' : rawTone);

        int? bpm;
        final bpmMatch = RegExp(r'\d+').firstMatch(rawTempo);
        if (bpmMatch != null) {
          bpm = int.tryParse(bpmMatch.group(0)!);
        }

        final category = catRaw.contains('alabanza') ? 'PRAISE' : 'WORSHIP';

        // Determinar URL de referencia y notas
        String? refUrl;
        String? notes;

        if (urlCol.startsWith('http')) {
          refUrl = urlCol;
          if (hipervinculo.isNotEmpty && !hipervinculo.startsWith('http')) {
            notes = hipervinculo;
          }
        } else {
          if (urlCol.isNotEmpty) notes = 'Ref: $urlCol';
          if (hipervinculo.isNotEmpty && notes == null) notes = hipervinculo;
        }

        // 1. Insertar Canción
        final songId = await txn.insert('songs', {
          'title': title,
          'artist': artist,
          'original_key': tone,
          'default_key': tone,
          'bpm': bpm,
          'category': category,
          'status': 'ACTIVE',
          'reference_url': refUrl,
          'notes': notes,
        });
        songsCount++;

        // 2. Si tiene fecha, vincular al culto correspondiente
        if (dateRaw.isNotEmpty &&
            RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateRaw)) {
          int serviceId;

          if (dateToServiceId.containsKey(dateRaw)) {
            serviceId = dateToServiceId[dateRaw]!;
          } else {
            // Verificar si el culto ya existía en la base
            final existing = await txn.query(
              'services',
              where: 'date = ?',
              whereArgs: [dateRaw],
              limit: 1,
            );

            if (existing.isNotEmpty) {
              serviceId = existing.first['id'] as int;
            } else {
              final parsedDate = DateTime.parse(dateRaw);
              final isSunday = parsedDate.weekday == DateTime.sunday;
              final serviceType = isSunday
                  ? 'Domingo Mañana'
                  : 'Culto Especial';

              serviceId = await txn.insert('services', {
                'date': dateRaw,
                'service_type': serviceType,
                'notes': 'Generado por migración de repertorio',
              });
              servicesCount++;
            }
            dateToServiceId[dateRaw] = serviceId;
            serviceSongCounter[serviceId] = 0;
          }

          // Incrementar orden dentro del setlist de esa fecha
          final currentOrder = (serviceSongCounter[serviceId] ?? 0) + 1;
          serviceSongCounter[serviceId] = currentOrder;

          await txn.insert('service_songs', {
            'service_id': serviceId,
            'song_id': songId,
            'played_key': tone,
            'lead_vocal': 'Voz Principal',
            'order_index': currentOrder,
            'feedback': null,
          });
          historyCount++;
        }
      }
    });

    return MigrationResult(
      totalSongs: songsCount,
      totalServices: servicesCount,
      totalHistories: historyCount,
    );
  }
}
