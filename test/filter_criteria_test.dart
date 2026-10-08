import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worship_manager/features/services/models/service_filter_criteria.dart';
import 'package:worship_manager/features/songs/models/song_filter_criteria.dart';
import 'package:worship_manager/features/songs/models/song_model.dart';

void main() {
  group('SongFilterCriteria', () {
    test('Default criteria is inactive with 0 active count', () {
      const criteria = SongFilterCriteria();
      expect(criteria.isActive, isFalse);
      expect(criteria.activeFiltersCount, 0);
      expect(criteria.createdDateRange.start, isNull);
      expect(criteria.createdDateRange.end, isNull);
    });

    test('Criteria with keys, category, and date preset is stackable', () {
      const criteria = SongFilterCriteria(
        keys: {'G', 'D', 'Em'},
        category: SongCategory.praise,
        datePreset: DateFilterPreset.last30Days,
        playedFilter: PlayedFilterOption.neverPlayed,
      );

      expect(criteria.isActive, isTrue);
      expect(criteria.activeFiltersCount, 4);
      expect(criteria.createdDateRange.start, isNotNull);
      expect(criteria.createdDateRange.end, isNotNull);
    });

    test('copyWith updates individual stackable filters correctly', () {
      var criteria = const SongFilterCriteria();

      // Añadir tono
      criteria = criteria.copyWith(keys: {'C'});
      expect(criteria.keys, {'C'});
      expect(criteria.activeFiltersCount, 1);

      // Añadir categoría
      criteria = criteria.copyWith(category: SongCategory.worship);
      expect(criteria.category, SongCategory.worship);
      expect(criteria.activeFiltersCount, 2);

      // Limpiar solo categoría
      criteria = criteria.copyWith(clearCategory: true);
      expect(criteria.category, isNull);
      expect(criteria.keys, {'C'});
      expect(criteria.activeFiltersCount, 1);

      // Limpiar todo
      criteria = criteria.clear();
      expect(criteria.isActive, isFalse);
      expect(criteria.activeFiltersCount, 0);
    });

    test('Custom date range handles start and end correctly', () {
      final range = DateTimeRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 6, 30),
      );
      final criteria = SongFilterCriteria(
        datePreset: DateFilterPreset.customRange,
        customDateRange: range,
      );

      expect(criteria.createdDateRange.start, DateTime(2026, 1, 1));
      expect(criteria.createdDateRange.end, DateTime(2026, 6, 30));
    });
  });

  group('ServiceFilterCriteria', () {
    test('Default criteria is inactive with 0 active count', () {
      const criteria = ServiceFilterCriteria();
      expect(criteria.isActive, isFalse);
      expect(criteria.activeFiltersCount, 0);
      expect(criteria.dateRange.start, isNull);
    });

    test('Criteria with service type, search query and date preset stacks properly', () {
      const criteria = ServiceFilterCriteria(
        serviceType: 'Domingo Mañana',
        datePreset: ServiceDatePreset.thisMonth,
        searchQuery: 'Gracia',
      );

      expect(criteria.isActive, isTrue);
      expect(criteria.activeFiltersCount, 3);
      expect(criteria.dateRange.start, isNotNull);
      expect(criteria.dateRange.end, isNotNull);
    });

    test('copyWith and clear work as expected', () {
      var criteria = const ServiceFilterCriteria(
        serviceType: 'Culto de Jóvenes',
      );
      expect(criteria.activeFiltersCount, 1);

      criteria = criteria.copyWith(datePreset: ServiceDatePreset.last3Months);
      expect(criteria.activeFiltersCount, 2);

      criteria = criteria.copyWith(clearServiceType: true);
      expect(criteria.serviceType, isNull);
      expect(criteria.activeFiltersCount, 1);

      criteria = criteria.clear();
      expect(criteria.isActive, isFalse);
    });
  });
}
