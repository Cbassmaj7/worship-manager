import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:worship_manager/core/database/database_helper.dart';
import 'package:worship_manager/features/services/presentation/services_list_screen.dart';
import 'package:worship_manager/features/songs/presentation/songs_screen.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
  });

  testWidgets(
    'SongsScreen renders search bar, tabs, refresh button and filter action',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SongsScreen(),
        ),
      );

      // Pump para iniciar la carga
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Repertorio de Worship'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.textContaining('Activa'), findsOneWidget);
    },
  );

  testWidgets('ServicesListScreen renders refresh, filter and fab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ServicesListScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Historial de Cultos'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.byIcon(Icons.tune), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.text('Nuevo Culto'), findsOneWidget);
  });
}
