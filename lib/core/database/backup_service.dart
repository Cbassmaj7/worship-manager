import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class DatabaseInfo {
  final String path;
  final int sizeBytes;
  final int totalSongs;
  final int totalServices;

  const DatabaseInfo({
    required this.path,
    required this.sizeBytes,
    required this.totalSongs,
    required this.totalServices,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024)
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class BackupService {
  /// Obtiene la ruta física real de la base de datos según el sistema operativo
  static Future<String> getDatabasePath() async {
    final String databasesPath;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      databasesPath = await getDatabasesPath();
    } else {
      final supportDir = await getApplicationSupportDirectory();
      databasesPath = supportDir.path;
    }
    return join(databasesPath, 'worship_manager.db');
  }

  /// Consulta el peso del archivo y el conteo de registros actuales
  static Future<DatabaseInfo> getInfo() async {
    final path = await getDatabasePath();
    final file = File(path);
    final size = await file.exists() ? await file.length() : 0;

    final db = await DatabaseHelper.instance.database;
    final songCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM songs;'),
        ) ??
        0;
    final serviceCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM services;'),
        ) ??
        0;

    return DatabaseInfo(
      path: path,
      sizeBytes: size,
      totalSongs: songCount,
      totalServices: serviceCount,
    );
  }

  /// Exporta la base de datos actual asegurando un checkpoint completo
  static Future<void> exportDatabase() async {
    final db = await DatabaseHelper.instance.database;

    // 1. Vaciar transacciones pendientes del WAL al archivo .db principal
    await db.rawQuery('PRAGMA wal_checkpoint(FULL);');

    final dbPath = await getDatabasePath();
    final originalFile = File(dbPath);

    if (!await originalFile.exists()) {
      throw Exception('El archivo de base de datos no existe físicamente aún.');
    }

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .substring(0, 19);
    final exportFileName = 'worship_backup_$timestamp.db';

    // 2. Exportación según plataforma
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      // En Desktop: Abrir diálogo para guardar archivo
      final destinationPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar respaldo de Worship Manager',
        fileName: exportFileName,
        type: FileType.custom,
        allowedExtensions: ['db', 'sqlite'],
      );

      if (destinationPath != null) {
        await originalFile.copy(destinationPath);
      }
    } else {
      // En Móvil: Abrir hoja de compartir nativa (WhatsApp, Drive, Telegram, etc.)
      await Share.shareXFiles(
        [
          XFile(
            originalFile.path,
            name: exportFileName,
            mimeType: 'application/octet-stream',
          ),
        ],
        subject: 'Copia de seguridad Worship Manager',
        text: 'Respaldo del repertorio y cultos generado el $timestamp.',
      );
    }
  }

  /// Importa un archivo .db, valida integridad y sustituye la base de datos local
  static Future<bool> importDatabase() async {
    // 1. Seleccionar archivo del dispositivo
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) {
      return false; // Operación cancelada por el usuario
    }

    final selectedFile = File(result.files.single.path!);

    // 2. Prueba rápida de integridad en modo solo lectura
    try {
      final tempDb = await openDatabase(selectedFile.path, readOnly: true);
      final check = await tempDb.rawQuery('PRAGMA quick_check;');
      final schemaTest = await tempDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='songs';",
      );
      await tempDb.close();

      if (check.isEmpty ||
          check.first['quick_check'] != 'ok' ||
          schemaTest.isEmpty) {
        throw Exception(
          'El archivo no corresponde a una base de datos válida de Worship Manager.',
        );
      }
    } catch (e) {
      throw Exception('Archivo corrupto o incompatible: $e');
    }

    // 3. Cerrar conexión activa para liberar bloqueos en disco
    await DatabaseHelper.instance.close();

    final targetPath = await getDatabasePath();

    // 4. CRÍTICO: Eliminar archivos de diario residuales (-wal y -shm)
    final walFile = File('$targetPath-wal');
    final shmFile = File('$targetPath-shm');
    if (await walFile.exists()) await walFile.delete();
    if (await shmFile.exists()) await shmFile.delete();

    // 5. Sobreescribir el archivo de base de datos
    await selectedFile.copy(targetPath);

    // 6. Reconectar el motor de la app
    await DatabaseHelper.instance.database;
    return true;
  }
}
