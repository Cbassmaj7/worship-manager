import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static const _dbName = 'worship_manager.db';
  static const _dbVersion = 2; // <-- SUBIMOS A VERSIÓN 2

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final String databasesPath;
    if (Platform.isAndroid || Platform.isIOS) {
      databasesPath = await getDatabasesPath();
    } else {
      final supportDir = await getApplicationSupportDirectory();
      databasesPath = supportDir.path;
    }

    final fullPath = join(databasesPath, _dbName);
    final directory = Directory(dirname(fullPath));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return await openDatabase(
      fullPath,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
        await db.rawQuery('PRAGMA journal_mode = WAL;');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // <-- MANEJADOR DE MIGRACIÓN
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        author TEXT,
        original_key TEXT NOT NULL,
        default_key TEXT NOT NULL,
        bpm INTEGER,
        category TEXT CHECK(category IN ('PRAISE', 'WORSHIP')) NOT NULL,
        status TEXT CHECK(status IN ('SUGGESTED', 'REHEARSING', 'ACTIVE', 'ARCHIVED')) NOT NULL DEFAULT 'SUGGESTED',
        reference_url TEXT,
        notes TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
      );
    ''');

    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        service_type TEXT NOT NULL,
        notes TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE service_songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        service_id INTEGER NOT NULL,
        song_id INTEGER NOT NULL,
        played_key TEXT NOT NULL,
        lead_vocal TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        feedback TEXT,
        FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE,
        FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE RESTRICT
      );
    ''');

    await db.execute(
      'CREATE INDEX idx_service_songs_song ON service_songs(song_id);',
    );
    await db.execute(
      'CREATE INDEX idx_service_songs_service ON service_songs(service_id);',
    );
    await db.execute('CREATE INDEX idx_songs_status ON songs(status);');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Si la base ya existía en v1, agregamos default_key rellenándolo con original_key
      await db.execute('''
        ALTER TABLE songs ADD COLUMN default_key TEXT NOT NULL DEFAULT 'C';
      ''');
      // Copiar el original_key al default_key existente para mantener coherencia
      await db.execute('''
        UPDATE songs SET default_key = original_key;
      ''');
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
