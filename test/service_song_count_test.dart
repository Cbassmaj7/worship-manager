import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:worship_manager/core/database/database_helper.dart';
import 'package:worship_manager/features/services/data/service_dao.dart';
import 'package:worship_manager/features/services/models/service_filter_criteria.dart';
import 'package:worship_manager/features/services/models/service_model.dart';
import 'package:worship_manager/features/services/models/service_song_model.dart';
import 'package:worship_manager/features/songs/data/song_dao.dart';
import 'package:worship_manager/features/songs/models/song_model.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
  });

  group('Service song_count tests', () {
    test('ServiceModel.fromMap correctly parses song_count in multiple formats', () {
      // 1. From int
      final model1 = ServiceModel.fromMap({
        'id': 1,
        'date': '2026-10-06',
        'service_type': 'Domingo Mañana',
        'song_count': 5,
      });
      expect(model1.songCount, equals(5));

      // 2. From String
      final model2 = ServiceModel.fromMap({
        'id': 2,
        'date': '2026-10-06',
        'service_type': 'Domingo Tarde',
        'song_count': '3',
      });
      expect(model2.songCount, equals(3));

      // 3. Fallback to songs list length when song_count is missing
      final model3 = ServiceModel.fromMap(
        {
          'id': 3,
          'date': '2026-10-06',
          'service_type': 'Jóvenes',
        },
        songs: const [
          ServiceSongModel(
            serviceId: 3,
            songId: 1,
            playedKey: 'G',
            leadVocal: 'Carlos',
            orderIndex: 1,
          ),
          ServiceSongModel(
            serviceId: 3,
            songId: 2,
            playedKey: 'D',
            leadVocal: 'Ana',
            orderIndex: 2,
          ),
        ],
      );
      expect(model3.songCount, equals(2));
    });

    test('getFilteredServices and getServicesByCriteria return correct song_count from database', () async {
      final songDao = SongDao();
      final serviceDao = ServiceDao();

      // Create two songs
      final song1Id = await songDao.insert(
        const SongModel(
          title: 'Grande y Fuerte',
          artist: 'Miel San Marcos',
          originalKey: 'G',
          defaultKey: 'G',
          category: SongCategory.praise,
        ),
      );

      final song2Id = await songDao.insert(
        const SongModel(
          title: 'Way Maker',
          artist: 'Sinach',
          originalKey: 'E',
          defaultKey: 'E',
          category: SongCategory.worship,
        ),
      );

      // Create a service with 2 songs
      final serviceId = await serviceDao.createServiceWithSongs(
        ServiceModel(
          date: DateTime(2026, 10, 6),
          serviceType: 'Culto de Prueba Conteo',
        ),
        [
          ServiceSongModel(
            serviceId: 0,
            songId: song1Id,
            playedKey: 'G',
            leadVocal: 'Voz 1',
            orderIndex: 1,
          ),
          ServiceSongModel(
            serviceId: 0,
            songId: song2Id,
            playedKey: 'E',
            leadVocal: 'Voz 2',
            orderIndex: 2,
          ),
        ],
      );

      // 1. Verify getFilteredServices returns song_count == 2
      final filtered = await serviceDao.getFilteredServices(
        query: 'Culto de Prueba Conteo',
      );
      expect(filtered.isNotEmpty, isTrue);
      final found = filtered.firstWhere((s) => s.id == serviceId);
      expect(found.songCount, equals(2));

      // 2. Verify getServicesByCriteria returns song_count == 2
      final byCriteria = await serviceDao.getServicesByCriteria(
        const ServiceFilterCriteria(searchQuery: 'Culto de Prueba Conteo'),
      );
      expect(byCriteria.isNotEmpty, isTrue);
      final foundByCriteria = byCriteria.firstWhere((s) => s.id == serviceId);
      expect(foundByCriteria.songCount, equals(2));

      // 3. Verify getRecentServices returns song_count == 2
      final recent = await serviceDao.getRecentServices(limit: 50);
      final foundRecent = recent.firstWhere((s) => s.id == serviceId);
      expect(foundRecent.songCount, equals(2));

      // 4. Verify getServiceWithSongs returns songCount == 2 and hydrated songs list
      final withSongs = await serviceDao.getServiceWithSongs(serviceId);
      expect(withSongs, isNotNull);
      expect(withSongs!.songCount, equals(2));
      expect(withSongs.songs.length, equals(2));
    });
  });
}
