class MusicalKeys {
  static const List<String> majorKeys = [
    'C',
    'C#',
    'Db',
    'D',
    'Eb',
    'E',
    'F',
    'F#',
    'Gb',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];

  static const List<String> minorKeys = [
    'Am',
    'A#m',
    'Bbm',
    'Bm',
    'Cm',
    'C#m',
    'Dm',
    'D#m',
    'Ebm',
    'Em',
    'Fm',
    'F#m',
    'Gm',
    'G#m',
    'Abm',
  ];

  static List<String> get all => [...majorKeys, ...minorKeys];

  /// Valida y normaliza el tono (ej: 'g' -> 'G', 'am' -> 'Am')
  static String normalize(String key) {
    final clean = key.trim();
    if (clean.isEmpty) return 'C';

    // Si termina en 'm' minúscula de menor
    if (clean.length > 1 && clean.endsWith('m')) {
      final root = clean.substring(0, clean.length - 1).toUpperCase();
      return '${root}m';
    }
    return clean.toUpperCase();
  }
}
