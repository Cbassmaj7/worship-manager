import 'package:flutter/material.dart';
import '../data/service_dao.dart';
import '../models/service_filter_criteria.dart';

import '../../../core/theme/app_theme.dart';

class ServiceFilterSheet extends StatefulWidget {
  final ServiceFilterCriteria initialCriteria;

  const ServiceFilterSheet({
    super.key,
    required this.initialCriteria,
  });

  static Future<ServiceFilterCriteria?> show(
    BuildContext context, {
    required ServiceFilterCriteria currentCriteria,
  }) {
    return showModalBottomSheet<ServiceFilterCriteria>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xF4140F26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: AppColors.glassBorder, width: 1.2),
      ),
      builder: (_) => ServiceFilterSheet(initialCriteria: currentCriteria),
    );
  }

  @override
  State<ServiceFilterSheet> createState() => _ServiceFilterSheetState();
}

class _ServiceFilterSheetState extends State<ServiceFilterSheet> {
  final _serviceDao = ServiceDao();

  String? _selectedServiceType;
  late ServiceDatePreset _selectedDatePreset;
  DateTimeRange? _customDateRange;
  final _searchController = TextEditingController();

  List<String> _availableTypes = [
    'Domingo Mañana',
    'Domingo Tarde',
    'Culto de Jóvenes',
    'Vigilia',
    'Culto Especial',
    'Servicio Especial',
  ];
  bool _isLoadingTypes = true;

  @override
  void initState() {
    super.initState();
    _selectedServiceType = widget.initialCriteria.serviceType;
    _selectedDatePreset = widget.initialCriteria.datePreset;
    _customDateRange = widget.initialCriteria.customDateRange;
    _searchController.text = widget.initialCriteria.searchQuery ?? '';

    _loadAvailableTypes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableTypes() async {
    try {
      final dbTypes = await _serviceDao.getDistinctServiceTypes();
      if (mounted) {
        setState(() {
          final set = <String>{
            'Domingo Mañana',
            'Domingo Tarde',
            'Culto de Jóvenes',
            'Vigilia',
            'Culto Especial',
            ...dbTypes,
          };
          _availableTypes = set.toList();
          _isLoadingTypes = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingTypes = false);
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedServiceType = null;
      _selectedDatePreset = ServiceDatePreset.all;
      _customDateRange = null;
      _searchController.clear();
    });
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange:
          _customDateRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month - 1, 1),
            end: now,
          ),
      helpText: 'Selecciona el rango de fechas de cultos',
      confirmText: 'Aplicar',
      cancelText: 'Cancelar',
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedDatePreset = ServiceDatePreset.customRange;
      });
    }
  }

  ServiceFilterCriteria _buildCriteria() {
    final query = _searchController.text.trim();
    return ServiceFilterCriteria(
      serviceType: _selectedServiceType,
      datePreset: _selectedDatePreset,
      customDateRange: _customDateRange,
      searchQuery: query.isEmpty ? null : query,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final criteria = _buildCriteria();
    final activeCount = criteria.activeFiltersCount;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Asa superior
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Encabezado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.tune, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Filtrar Historial de Cultos',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$activeCount',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (activeCount > 0)
                    TextButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Limpiar'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // --- 1. BUSCADOR POR CONTENIDO ---
                  Row(
                    children: [
                      Icon(Icons.search, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Buscar en el Culto',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Canción tocada, notas o tema...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _searchController.clear()),
                            )
                          : null,
                      isDense: true,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // --- 2. TIPO DE CULTO ---
                  Row(
                    children: [
                      Icon(Icons.church_outlined, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Tipo de Culto',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedServiceType != null)
                        TextButton(
                          onPressed: () => setState(() => _selectedServiceType = null),
                          child: const Text('Todos', style: TextStyle(fontSize: 11.5)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingTypes)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Todos los tipos'),
                          selected: _selectedServiceType == null,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedServiceType = null);
                            }
                          },
                        ),
                        ..._availableTypes.map((type) {
                          final isSelected = _selectedServiceType == type;
                          return ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedServiceType = selected ? type : null;
                              });
                            },
                          );
                        }),
                      ],
                    ),

                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // --- 3. RANGO DE FECHAS ---
                  Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Rango de Fechas',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ServiceDatePreset.values.map((preset) {
                      final isSelected = _selectedDatePreset == preset;
                      String label = preset.label;

                      if (preset == ServiceDatePreset.customRange &&
                          _customDateRange != null) {
                        final start =
                            _customDateRange!.start.toIso8601String().substring(0, 10);
                        final end =
                            _customDateRange!.end.toIso8601String().substring(0, 10);
                        label = '$start a $end';
                      }

                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (selected) async {
                          if (selected) {
                            if (preset == ServiceDatePreset.customRange) {
                              await _pickCustomDateRange();
                            } else {
                              setState(() {
                                _selectedDatePreset = preset;
                                _customDateRange = null;
                              });
                            }
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),

            // Barra de acción inferior
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: const Offset(0, -2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _resetFilters,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Restablecer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context, _buildCriteria());
                        },
                        icon: const Icon(Icons.check),
                        label: Text(
                          activeCount > 0
                              ? 'Aplicar ($activeCount filtros)'
                              : 'Aplicar Filtros',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
