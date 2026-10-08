import 'package:flutter/material.dart';
import 'song_model.dart';

enum DateFilterPreset {
  all('Cualquier fecha'),
  last30Days('Últimos 30 días'),
  last90Days('Últimos 90 días'),
  thisYear('Este año'),
  customRange('Rango personalizado');

  final String label;
  const DateFilterPreset(this.label);
}

enum PlayedFilterOption {
  any('Cualquier historial'),
  recentlyPlayed('Cantadas recientemente (≤ 30 días)'),
  dormant('Sin cantar (> 45 días)'),
  neverPlayed('Nunca cantadas');

  final String label;
  const PlayedFilterOption(this.label);
}

class SongFilterCriteria {
  final Set<String> keys;
  final bool matchBandKeyOnly;
  final SongCategory? category;
  final DateFilterPreset datePreset;
  final DateTimeRange? customDateRange;
  final PlayedFilterOption playedFilter;

  const SongFilterCriteria({
    this.keys = const {},
    this.matchBandKeyOnly = true,
    this.category,
    this.datePreset = DateFilterPreset.all,
    this.customDateRange,
    this.playedFilter = PlayedFilterOption.any,
  });

  bool get isActive =>
      keys.isNotEmpty ||
      category != null ||
      datePreset != DateFilterPreset.all ||
      playedFilter != PlayedFilterOption.any;

  int get activeFiltersCount {
    int count = 0;
    if (keys.isNotEmpty) count++;
    if (category != null) count++;
    if (datePreset != DateFilterPreset.all) count++;
    if (playedFilter != PlayedFilterOption.any) count++;
    return count;
  }

  /// Calcula el rango de fechas de creación según el preset
  ({DateTime? start, DateTime? end}) get createdDateRange {
    final now = DateTime.now();
    switch (datePreset) {
      case DateFilterPreset.last30Days:
        return (
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
      case DateFilterPreset.last90Days:
        return (
          start: now.subtract(const Duration(days: 90)),
          end: now,
        );
      case DateFilterPreset.thisYear:
        return (
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
      case DateFilterPreset.customRange:
        return (
          start: customDateRange?.start,
          end: customDateRange?.end,
        );
      case DateFilterPreset.all:
        return (start: null, end: null);
    }
  }

  SongFilterCriteria copyWith({
    Set<String>? keys,
    bool? matchBandKeyOnly,
    SongCategory? category,
    bool clearCategory = false,
    DateFilterPreset? datePreset,
    DateTimeRange? customDateRange,
    bool clearCustomDateRange = false,
    PlayedFilterOption? playedFilter,
  }) {
    return SongFilterCriteria(
      keys: keys ?? this.keys,
      matchBandKeyOnly: matchBandKeyOnly ?? this.matchBandKeyOnly,
      category: clearCategory ? null : (category ?? this.category),
      datePreset: datePreset ?? this.datePreset,
      customDateRange:
          clearCustomDateRange
              ? null
              : (customDateRange ?? this.customDateRange),
      playedFilter: playedFilter ?? this.playedFilter,
    );
  }

  SongFilterCriteria clear() => const SongFilterCriteria();
}
