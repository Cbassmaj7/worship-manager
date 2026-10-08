import 'package:flutter/material.dart';

enum ServiceDatePreset {
  all('Todas las fechas'),
  thisMonth('Este mes'),
  last3Months('Últimos 3 meses'),
  thisYear('Este año'),
  customRange('Rango personalizado');

  final String label;
  const ServiceDatePreset(this.label);
}

class ServiceFilterCriteria {
  final String? serviceType;
  final ServiceDatePreset datePreset;
  final DateTimeRange? customDateRange;
  final String? searchQuery;

  const ServiceFilterCriteria({
    this.serviceType,
    this.datePreset = ServiceDatePreset.all,
    this.customDateRange,
    this.searchQuery,
  });

  bool get isActive =>
      (serviceType != null &&
          serviceType!.trim().isNotEmpty &&
          serviceType != 'Todos') ||
      datePreset != ServiceDatePreset.all ||
      customDateRange != null ||
      (searchQuery != null && searchQuery!.trim().isNotEmpty);

  int get activeFiltersCount {
    int count = 0;
    if (serviceType != null &&
        serviceType!.trim().isNotEmpty &&
        serviceType != 'Todos') {
      count++;
    }
    if (datePreset != ServiceDatePreset.all) {
      count++;
    }
    if (searchQuery != null && searchQuery!.trim().isNotEmpty) {
      count++;
    }
    return count;
  }

  /// Calcula el rango de fechas según el preset
  ({DateTime? start, DateTime? end}) get dateRange {
    final now = DateTime.now();
    switch (datePreset) {
      case ServiceDatePreset.thisMonth:
        return (
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case ServiceDatePreset.last3Months:
        return (
          start: DateTime(now.year, now.month - 2, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case ServiceDatePreset.thisYear:
        return (
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
      case ServiceDatePreset.customRange:
        return (
          start: customDateRange?.start,
          end: customDateRange?.end,
        );
      case ServiceDatePreset.all:
        return (start: null, end: null);
    }
  }

  ServiceFilterCriteria copyWith({
    String? serviceType,
    bool clearServiceType = false,
    ServiceDatePreset? datePreset,
    DateTimeRange? customDateRange,
    bool clearCustomDateRange = false,
    String? searchQuery,
    bool clearSearchQuery = false,
  }) {
    return ServiceFilterCriteria(
      serviceType: clearServiceType ? null : (serviceType ?? this.serviceType),
      datePreset: datePreset ?? this.datePreset,
      customDateRange:
          clearCustomDateRange
              ? null
              : (customDateRange ?? this.customDateRange),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }

  ServiceFilterCriteria clear() => const ServiceFilterCriteria();
}
