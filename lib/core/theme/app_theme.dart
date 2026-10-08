import 'package:flutter/material.dart';

/// Paleta de colores para estilo Glassmorfismo con acento primario en Lila
class AppColors {
  // Lila / Lavanda primario
  static const Color primary = Color(0xFFA855F7); // Lila vibrante
  static const Color primaryLight = Color(0xFFC084FC); // Lila claro
  static const Color primaryDark = Color(0xFF7E22CE); // Lila profundo
  static const Color primaryContainer = Color(0xFF3B1D6D); // Fondo lila noche

  // Acentos complementarios
  static const Color secondary = Color(0xFFD8B4FE); // Lavanda suave
  static const Color tertiary = Color(0xFFE9D5FF); // Lila pastel
  static const Color accentPraise = Color(0xFFFB923C); // Alabanza: naranja cálido
  static const Color accentWorship = Color(0xFF818CF8); // Adoración: índigo lavanda

  // Fondos y superficies oscuras para glassmorfismo
  static const Color background = Color(0xFF090714); // Fondo cósmico ultra oscuro
  static const Color surface = Color(0xFF140F24); // Superficie noche violeta
  static const Color surfaceContainer = Color(0xFF1C1533);

  // Tokens de glassmorfismo
  static const Color glassWhite = Color(0x18FFFFFF); // 9% blanco translúcido
  static const Color glassWhiteHover = Color(0x28FFFFFF);
  static const Color glassBorder = Color(0x38C084FC); // Borde con brillo lila
  static const Color glassHighlight = Color(0x2EFFFFFF); // Reflejo superior
  static const Color glassGlow = Color(0x26A855F7); // Resplandor ambiental lila
}

/// Sistema de diseño y temas con Glassmorfismo y tipografía refinada (2-3 niveles más compacta)
class AppTheme {
  /// Tipografía general reducida 2-3 niveles para una estética elegante y compacta
  static TextTheme get textTheme {
    return const TextTheme(
      // displayLarge: 64 -> 46
      displayLarge: TextStyle(
        fontSize: 46,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: Colors.white,
      ),
      // displayMedium: 52 -> 38
      displayMedium: TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: Colors.white,
      ),
      // displaySmall: 44 -> 30
      displaySmall: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      // headlineLarge: 36 -> 24
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      // headlineMedium: 32 -> 21
      headlineMedium: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      // headlineSmall: 28 -> 18
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      // titleLarge: 25 -> 18
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0,
        color: Colors.white,
      ),
      // titleMedium: 19 -> 14.5
      titleMedium: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: Colors.white,
      ),
      // titleSmall: 17 -> 12.5
      titleSmall: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: Color(0xFFE9D5FF),
      ),
      // bodyLarge: 18 -> 13.5
      bodyLarge: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: Colors.white,
      ),
      // bodyMedium: 16 -> 12
      bodyMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: Color(0xFFD4D4D8),
      ),
      // bodySmall: 14 -> 10.5
      bodySmall: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: Color(0xFFA1A1AA),
      ),
      // labelLarge: 16 -> 12.5
      labelLarge: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Colors.white,
      ),
      // labelMedium: 14 -> 11
      labelMedium: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: Color(0xFFD8B4FE),
      ),
      // labelSmall: 13 -> 10
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: Color(0xFFA1A1AA),
      ),
    );
  }

  /// Tema oscuro con acento lila y estética de cristal esmerilado
  static ThemeData get darkTheme {
    final baseTextTheme = textTheme;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.tertiary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.background,
      secondaryContainer: const Color(0xFF2E1256),
      onSecondaryContainer: AppColors.tertiary,
      surface: AppColors.surface,
      onSurface: Colors.white,
      surfaceContainerHighest: AppColors.surfaceContainer,
      onSurfaceVariant: const Color(0xFFD8B4FE),
      outline: AppColors.glassBorder,
      outlineVariant: const Color(0x24C084FC),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: baseTextTheme,

      // AppBar con fondo translúcido y desenfoque
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppColors.secondary),
      ),

      // NavigationBar móvil con estilo de cristal
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xCC0E0A1E),
        elevation: 0,
        indicatorColor: AppColors.primary.withValues(alpha: 0.3),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryLight, size: 26);
          }
          return const IconThemeData(color: Color(0xFFA1A1AA), size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return baseTextTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryLight,
            );
          }
          return baseTextTheme.labelSmall?.copyWith(
            color: const Color(0xFFA1A1AA),
          );
        }),
      ),

      // NavigationRail de escritorio con estilo de cristal
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xCC0E0A1E),
        elevation: 0,
        indicatorColor: AppColors.primary.withValues(alpha: 0.3),
        selectedIconTheme: const IconThemeData(
          color: AppColors.primaryLight,
          size: 26,
        ),
        unselectedIconTheme: const IconThemeData(
          color: Color(0xFFA1A1AA),
          size: 24,
        ),
        selectedLabelTextStyle: baseTextTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primaryLight,
        ),
        unselectedLabelTextStyle: baseTextTheme.labelSmall?.copyWith(
          color: const Color(0xFFA1A1AA),
        ),
      ),

      // Tarjetas de cristal redondeadas
      cardTheme: CardThemeData(
        color: AppColors.glassWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder, width: 1.2),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // BottomSheets de cristal oscuro con bordes suaves
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xF2151028),
        modalBackgroundColor: Color(0xF2151028),
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          side: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),

      // Diálogos modales
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xF2181230),
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.glassBorder, width: 1.2),
        ),
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: baseTextTheme.bodyMedium,
      ),

      // Campos de texto tipo Input con bordes y relleno translúcido
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(
          color: const Color(0xFF71717A),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),

      // Chips y etiquetas
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.glassWhite,
        selectedColor: AppColors.primary.withValues(alpha: 0.35),
        disabledColor: const Color(0x10FFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        labelStyle: baseTextTheme.labelMedium?.copyWith(color: Colors.white),
        secondaryLabelStyle: baseTextTheme.labelMedium?.copyWith(
          color: AppColors.tertiary,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Botones flotantes (FAB)
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      // Botones rellenados
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      // Botones con contorno
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.glassBorder, width: 1.2),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      // Pestañas (Tabs)
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.primaryLight,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.primaryLight,
        unselectedLabelColor: const Color(0xFFA1A1AA),
        labelStyle: baseTextTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: baseTextTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.normal,
        ),
      ),

      // Divisores
      dividerTheme: DividerThemeData(
        color: AppColors.primary.withValues(alpha: 0.15),
        thickness: 1,
      ),

      // ListTiles
      listTileTheme: ListTileThemeData(
        titleTextStyle: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        subtitleTextStyle: baseTextTheme.bodyMedium?.copyWith(
          color: const Color(0xFFD4D4D8),
        ),
        iconColor: AppColors.primaryLight,
      ),
    );
  }
}
