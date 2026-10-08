import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SeedData {
  /// Ejecuta el sembrado solo si la tabla de canciones está completamente vacía
  static Future seedIfEmpty() async {
    final db = await DatabaseHelper.instance.database;
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM songs;'),
        ) ??
        0;

    if (count == 0) {
      await runSeed(clearExisting: false);
      return true;
    }
    return false;
  }

  /// Ejecuta el sembrado relacional completo dentro de una transacción atómica
  static Future runSeed({bool clearExisting = false}) async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      if (clearExisting) {
        await txn.delete('service_songs');
        await txn.delete('services');
        await txn.delete('songs');
      }

      // 1. Los 13 cultos detectados en el CSV
      final servicesList = [
        {'date': '2026-03-22', 'type': 'Domingo Mañana'},
        {'date': '2026-05-03', 'type': 'Domingo Mañana'},
        {'date': '2026-05-17', 'type': 'Domingo Mañana'},
        {'date': '2026-05-22', 'type': 'Culto Especial'},
        {'date': '2026-06-14', 'type': 'Domingo Mañana'},
        {'date': '2026-06-28', 'type': 'Domingo Mañana'},
        {'date': '2026-07-12', 'type': 'Domingo Mañana'},
        {'date': '2026-07-26', 'type': 'Domingo Mañana'},
        {'date': '2026-08-09', 'type': 'Domingo Mañana'},
        {'date': '2026-08-21', 'type': 'Culto Especial'},
        {'date': '2026-08-30', 'type': 'Domingo Mañana'},
        {'date': '2026-09-13', 'type': 'Domingo Mañana'},
        {'date': '2026-10-04', 'type': 'Domingo Mañana'},
      ];

      final Map dateToServiceId = {};

      for (final s in servicesList) {
        final id = await txn.insert('services', {
          'date': s['date'],
          'service_type': s['type'],
          'notes': 'Culto registrado en migración inicial',
        });
        dateToServiceId[s['date'] as String] = id;
      }

      // 2. Las 45 canciones estructuradas con enlaces, tonos y notas
      final rawSongs = [
        {
          'title': 'Rompe los cielos',
          'artist': 'Nancy Ramirez',
          'tone': 'G',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': null,
          'notes':
              'Ref: Rompe los cielos (Adriana Acosta y Veronica Rodriguez)',
          'date': '2026-10-04',
        },
        {
          'title': 'Somos el pueblo de Dios',
          'artist': 'Marcos Wit',
          'tone': 'C',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url':
              'https://www.youtube.com/watch?v=GCnyax1nCPc&list=RDGCnyax1nCPc&start_radio=1',
          'notes': 'Somos el pueblo de Dios - Marcos Wit',
          'date': '2026-10-04',
        },
        {
          'title': 'Perfume a tus pies',
          'artist': 'En espiritu y verdad',
          'tone': 'D',
          'bpm': null,
          'category': 'WORSHIP',
          'ref_url': null,
          'notes':
              'Ref: Perfume A Tus Pies  - Jaz Jacob & En Espíritu y En Verdad (En Vivo)',
          'date': '2026-10-04',
        },
        {
          'title': 'Eres todo poderoso',
          'artist': 'Danilo Montero',
          'tone': 'Em',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': null,
          'notes': 'Ref: ERES TODOPODEROSO - Danilo Montero',
          'date': '2026-10-04',
        },
        {
          'title': 'Grande y fuerte',
          'artist': 'Desconocido',
          'tone': 'Am',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': null,
          'notes': null,
          'date': '2026-09-13',
        },
        {
          'title': 'La casa de Dios',
          'artist': 'Danilo Montero',
          'tone': 'A',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': null,
          'notes': 'Ref: La Casa De Dios',
          'date': '2026-09-13',
        },
        {
          'title': 'Santo es el que vive',
          'artist': 'Monte Santo',
          'tone': 'Em',
          'bpm': 133,
          'category': 'WORSHIP',
          'ref_url':
              'https://www.youtube.com/watch?v=ToDXDSQUrms&list=RDToDXDSQUrms&start_radio=1',
          'notes': 'Santo es el que vive  - Monte Santo',
          'date': '2026-09-13',
        },
        {
          'title': 'Cantaré al señor por siempre',
          'artist': 'Juan Carlos Alvarado',
          'tone': 'Am',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': null,
          'notes': null,
          'date': '2026-08-30',
        },
        {
          'title': 'El Poderoso de Israel',
          'artist': 'Juan Carlos Alvarado',
          'tone': 'Gm',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': null,
          'notes': null,
          'date': '2026-08-30',
        },
        {
          'title': 'Estamos de Pie',
          'artist': 'IDEA Worship',
          'tone': 'D',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': 'https://www.youtube.com/watch?v=55oYB7LmZUY',
          'notes': 'Estamos de Pie - IDEA Worship',
          'date': '2026-08-30',
        },
        {
          'title': 'Jehová es mi guerrero',
          'artist': 'Juan Carlos Alvarado',
          'tone': 'Am',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': null,
          'notes': null,
          'date': '2026-08-30',
        },
        {
          'title': 'La bondad de Dios',
          'artist': 'Desconocido',
          'tone': 'G',
          'bpm': null,
          'category': 'WORSHIP',
          'ref_url': null,
          'notes': 'La bondad de Dios -',
          'date': '2026-08-30',
        },
        {
          'title': 'Me gozaré en Jehová',
          'artist': 'Juan Carlos Alvarado',
          'tone': 'Am',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': null,
          'notes': null,
          'date': '2026-08-30',
        },
        {
          'title': 'Aquí estás',
          'artist': 'Desconocido',
          'tone': 'Em',
          'bpm': null,
          'category': 'WORSHIP',
          'ref_url': null,
          'notes': null,
          'date': '2026-08-21',
        },
        {
          'title': 'Al que está sentado',
          'artist': 'Marcos Brunet',
          'tone': 'A',
          'bpm': null,
          'category': 'WORSHIP',
          'ref_url':
              'https://www.youtube.com/watch?v=PKd0WGCcxMs&list=RDPKd0WGCcxMs&start_radio=1',
          'notes': 'Al que está sentado   - Marcos Brunet',
          'date': '2026-08-09',
        },
        {
          'title': 'Alabaré a mi Señor',
          'artist': 'Israel Houghton',
          'tone': 'C',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': 'https://www.youtube.com/watch?v=WSHt0fuDICQ',
          'notes': 'Alabaré a mi Señor - Israel Houghton',
          'date': '2026-08-09',
        },
        {
          'title': 'Con mis manos Y mi vida',
          'artist': 'Israel Houghton',
          'tone': 'C',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': 'https://www.youtube.com/watch?v=WSHt0fuDICQ',
          'notes': 'Con mis manos Y mi vida - Israel Houghton',
          'date': '2026-08-09',
        },
        {
          'title': 'Hay poder',
          'artist': 'Israel Houghton',
          'tone': 'C',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': 'https://www.youtube.com/watch?v=WSHt0fuDICQ',
          'notes': 'Hay poder - Israel Houghton',
          'date': '2026-08-09',
        },
        {
          'title': 'Socorro',
          'artist': 'Un corazon',
          'tone': 'C',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url':
              'https://www.youtube.com/watch?v=By1D67IzxI4&list=RDBy1D67IzxI4&start_radio=1',
          'notes': 'Socorro - Un corazon',
          'date': '2026-08-09',
        },
        {
          'title': 'Te alabarán oh Jehová todos los reyes',
          'artist': 'Israel Houghton',
          'tone': 'C',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': 'https://www.youtube.com/watch?v=WSHt0fuDICQ',
          'notes': 'Te alabarán oh Jehová todos los reyes - Israel Houghton',
          'date': '2026-08-09',
        },
        {
          'title': 'Ven Espíritu divino',
          'artist': 'Israel Houghton',
          'tone': 'C',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': 'https://www.youtube.com/watch?v=WSHt0fuDICQ',
          'notes': 'Ven Espíritu divino - Israel Houghton',
          'date': '2026-08-09',
        },
        {
          'title': 'Danzando',
          'artist': 'Desconocido',
          'tone': 'Am',
          'bpm': 95,
          'category': 'PRAISE',
          'ref_url':
              'https://www.mukaplay.com/dynps/share/HRcLFwgUFQIqGAkAAhVBBhsBAh8AFCoHCA8bXAwVWU0VEEFBHAsgMAQaADA_UiUkE0EBBwElER4XFAUFDlAMTSMCBQQfUCEMGQgCUD8LHAgIABxQEVUoCRMZAxkcBQRBNFcuGQoTCB9cTSEZABcJUCcaDkFHUDcMAQ4WAAlQOhoZEgkZAE0wGBEAs8ECGUcVDBBBWkJcWFVIRFREX1RQ',
          'notes': 'Danzando -',
          'date': '2026-07-26',
        },
        {
          'title': 'Tu pueblo dice gracias',
          'artist': 'Desconocido',
          'tone': 'D',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': null,
          'notes': null,
          'date': '2026-07-26',
        },
        {
          'title': 'Yeshua + si te tengo a ti',
          'artist': 'G12 y Marcos Brunet',
          'tone': 'C',
          'bpm': null,
          'category': 'WORSHIP',
          'ref_url':
              'https://www.youtube.com/watch?v=V1QBIb7AEkA&list=RDV1QBIb7AEkA&start_radio=1',
          'notes': 'Yeshua + si te tengo a ti  - G12 y Marcos Brunet',
          'date': '2026-07-26',
        },
        {
          'title': 'Cuan grande es Dios',
          'artist': 'Desconocido',
          'tone': 'G',
          'bpm': null,
          'category': 'WORSHIP',
          'ref_url': null,
          'notes': 'Cuan grande es Dios  -',
          'date': '2026-07-12',
        },
        {
          'title': 'Rey',
          'artist': "Christine D'Clario",
          'tone': 'D',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': null,
          'notes': "Ref: Christine D'Clario | Rey | En Vivo",
          'date': '2026-07-12',
        },
        {
          'title': 'Con mi Dios',
          'artist': 'Jesus Adrian Romero',
          'tone': 'Am',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': null,
          'notes': 'Ref: Jesús Adrián Romero - Con Mi Dios (Lyric Video)',
          'date': '2026-06-28',
        },
        {
          'title': 'Fiesta en el desierto',
          'artist': 'Montesanto',
          'tone': 'Dm',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': null,
          'notes': 'Fiesta en el desierto  - Montesanto',
          'date': '2026-06-14',
        },
        {
          'title': 'Gloria en lo alto',
          'artist': "Christine D'Clario",
          'tone': 'D',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': null,
          'notes':
              'Ref: Christine D Clario   Gloria en lo alto  con letra  medium',
          'date': '2026-06-14',
        },
        {
          'title': 'Hay libertad',
          'artist': 'Art Aguilera',
          'tone': 'Em',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': null,
          'notes':
              'Ref: Hay Libertad - Art Aguilera (Canción Oficial ) Video Lyric #2',
          'date': '2026-06-14',
        },
        {
          'title': 'Santo por siempre',
          'artist': 'La IBI',
          'tone': 'F',
          'bpm': null,
          'category': 'WORSHIP',
          'ref_url': null,
          'notes': 'Santo por siempre  - La IBI',
          'date': '2026-06-14',
        },
        {
          'title': 'Gracia Sublime es',
          'artist': 'En espíritu y verdad',
          'tone': 'D',
          'bpm': 100,
          'category': 'PRAISE',
          'ref_url': null,
          'notes': 'Ref: EEYEV - Gracia Sublime Es (Video Lyric)',
          'date': '2026-05-22',
        },
        {
          'title': 'Hay libertad',
          'artist': 'La IBI',
          'tone': 'G',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': null,
          'notes': 'Ref: Hay Libertad - Gracia Soberana Música (Video Oficial)',
          'date': '2026-05-22',
        },
        {
          'title': 'Incomprensible Amor',
          'artist': 'New Wine',
          'tone': 'F#m',
          'bpm': null,
          'category': 'WORSHIP',
          'ref_url': 'https://youtu.be/70_2DcsIncY',
          'notes': 'Incomprensible Amor - New Wine',
          'date': '2026-05-22',
        },
        {
          'title': 'Hosanna',
          'artist': 'Marco Barrientos',
          'tone': 'Em',
          'bpm': 146,
          'category': 'PRAISE',
          'ref_url':
              'https://www.youtube.com/watch?v=RHZTk79wAL4&list=RDRHZTk79wAL4&start_radio=1',
          'notes': 'Hosanna - Marco Barrientos',
          'date': '2026-05-17',
        },
        {
          'title': 'Vamos a cantar',
          'artist': 'En espiritu y verdad',
          'tone': 'D',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url':
              'https://www.youtube.com/watch?v=YZOcxolb5z8&list=RDYZOcxolb5z8&start_radio=1',
          'notes': 'Vamos a cantar - En espiritu y verdad',
          'date': '2026-05-17',
        },
        {
          'title': 'Digno y santo',
          'artist': 'Danilo Montero',
          'tone': 'D',
          'bpm': null,
          'category': 'WORSHIP',
          'ref_url':
              'https://www.youtube.com/results?search_query=Digno+y+santo+',
          'notes': 'Digno y santo  - Danilo Montero',
          'date': '2026-05-03',
        },
        {
          'title': 'El Dios que adoramos',
          'artist': 'La IBI',
          'tone': 'E',
          'bpm': null,
          'category': 'WORSHIP',
          'ref_url': null,
          'notes':
              'Ref: El Dios que Adoramos - Gracia Soberana Música (Video Oficial)',
          'date': '2026-03-22',
        },
        // 7 Canciones sin fecha histórica (Quedan como 'Debut pendiente' en el Radar de Olvidadas)
        {
          'title': 'Amor sin condición',
          'artist': 'Marco Barrientos',
          'tone': 'C',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': null,
          'notes': 'Ref: Amor sin condición   Marco Barrientos letra',
          'date': null,
        },
        {
          'title': 'Derramo el perfume',
          'artist': 'Monte Santo',
          'tone': 'G',
          'bpm': null,
          'category': 'WORSHIP',
          'ref_url': null,
          'notes':
              'Ref: Derramo el Perfume - Montesanto ft Averly Morillo (Video Oficial)',
          'date': null,
        },
        {
          'title': 'Dios poderoso',
          'artist': 'La IBI',
          'tone': 'Bm',
          'bpm': null,
          'category': 'PRAISE',
          'ref_url': null,
          'notes': 'Ref: Dios poderoso - Adoración La IBI [Video OFICIAL]',
          'date': null,
        },
        {
          'title': 'Escucharte hablar',
          'artist': 'Desconocido',
          'tone': 'C',
          'bpm': null,
          'category': 'WORSHIP',
          'ref_url': null,
          'notes': 'Ref: JULISSA | Escucharte Hablar (Music Video)',
          'date': null,
        },
        {
          'title': 'La tierra canta',
          'artist': 'Barak',
          'tone': 'Bm',
          'bpm': null,
          'category': 'WORSHIP',
          'ref_url': null,
          'notes':
              'Ref: La Tierra Canta | Barak |  Video Oficial | Radical Live',
          'date': null,
        },
        {
          'title': 'Se manifestara',
          'artist': 'Oasis Ministry',
          'tone': 'Em',
          'bpm': 138,
          'category': 'WORSHIP',
          'ref_url':
              'https://www.youtube.com/watch?v=Qem0WSJXLCE&list=RDQem0WSJXLCE&start_radio=1',
          'notes': 'Se manifestara  - Oasis Ministry',
          'date': null,
        },
        {
          'title': 'Vine a adorarte',
          'artist': 'Marcela Gandara',
          'tone': 'D',
          'bpm': null,
          'category': 'WORSHIP',
          'ref_url':
              'https://www.youtube.com/watch?v=vZIpN5ppC-s&list=RDvZIpN5ppC-s&start_radio=1',
          'notes': 'Vine a adorarte  - Marcela Gandara',
          'date': null,
        },
      ];

      final Map serviceOrderTracker = {};

      for (final song in rawSongs) {
        final songId = await txn.insert('songs', {
          'title': song['title'] as String,
          'artist': song['artist'] as String,
          'original_key': song['tone'] as String,
          'default_key': song['tone'] as String,
          'bpm': song['bpm'] as int?,
          'category': song['category'] as String,
          'status': 'ACTIVE',
          'reference_url': song['ref_url'] as String?,
          'notes': song['notes'] as String?,
        });

        final date = song['date'] as String?;
        if (date != null && dateToServiceId.containsKey(date)) {
          final serviceId = dateToServiceId[date]!;
          final order = (serviceOrderTracker[serviceId] ?? 0) + 1;
          serviceOrderTracker[serviceId] = order;

          await txn.insert('service_songs', {
            'service_id': serviceId,
            'song_id': songId,
            'played_key': song['tone'] as String,
            'lead_vocal': 'Voz Principal',
            'order_index': order,
          });
        }
      }
    });

    debugPrint(
      'Seeder completado con éxito: 45 canciones y 13 cultos estructurados.',
    );
  }
}
