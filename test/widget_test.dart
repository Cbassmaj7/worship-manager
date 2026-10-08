import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:worship_manager/core/database/database_helper.dart';
import 'package:worship_manager/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
  });

  testWidgets('WorshipManagerApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WorshipManagerApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Repertorio'), findsWidgets);
  });
}
