import 'package:flutter/material.dart';
import 'package:worship_manager/core/database/seed_data.dart';
import 'core/database/database_helper.dart';
import 'core/presentation/main_shell_screen.dart';

import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 1. Inicializar la base de datos SQLite
  await DatabaseHelper.instance.database;

  // 2. Sembrar si la base está vacía
  await SeedData.seedIfEmpty();
  runApp(const WorshipManagerApp());
}

class WorshipManagerApp extends StatelessWidget {
  const WorshipManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Worship Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShellScreen(),
    );
  }
}
