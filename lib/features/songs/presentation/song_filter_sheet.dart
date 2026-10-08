import 'package:flutter/material.dart';
import '../../../core/constants/musical_keys.dart';
import '../models/song_filter_criteria.dart';
import '../models/song_model.dart';

import '../../../core/theme/app_theme.dart';

class SongFilterSheet extends StatefulWidget {
  final SongFilterCriteria initialCriteria;

  const SongFilterSheet({
    super.key,
    required this.initialCriteria,
  });

  /// Método estático conveniente para abrir el bottom sheet
  static Future<SongFilterCriteria?> show(
    BuildContext context, {
    required SongFilterCriteria currentCriteria,
  }) {
    return showModalBottomSheet<SongFilterCriteria>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xF4140F26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: AppColors.glassBorder, width: 1.2),
      ),
      builder: (_) => SongFilterSheet(initialCriteria: currentCriteria),
    );
  }

  @override
  State<SongFilterSheet> createState() => _SongFilterSheetState();
}

class _SongFilterSheetState extends State<SongFilterSheet> {
  late Set<String> _selectedKeys;
  late bool _matchBandKeyOnly;
  SongCategory? _selectedCategory;
  late DateFilterPreset _selectedDatePreset;
  DateTimeRange? _customDateRange;
  late PlayedFilterOption _selectedPlayedFilter;

  // Modos de visualización de tonos
  bool _showMinorKeys = true;

  @override
  void initState() {
    super.initState();
    _selectedKeys = Set<String>.from(widget.initialCriteria.keys);
    _matchBandKeyOnly = widget.initialCriteria.matchBandKeyOnly;
    _selectedCategory = widget.initialCriteria.category;
    _selectedDatePreset = widget.initialCriteria.datePreset;
    _customDateRange = widget.initialCriteria.customDateRange;
    _selectedPlayedFilter = widget.initialCriteria.playedFilter;
  }

  void _resetFilters() {
    setState(() {
      _selectedKeys.clear();
      _matchBandKeyOnly = true;
      _selectedCategory = null;
      _selectedDatePreset = DateFilterPreset.all;
      _customDateRange = null;
      _selectedPlayedFilter = PlayedFilterOption.any;
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
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      helpText: 'Selecciona el rango de fechas de adición',
      confirmText: 'Aplicar',
      cancelText: 'Cancelar',
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedDatePreset = DateFilterPreset.customRange;
      });
    }
  }

  SongFilterCriteria _buildCriteria() {
    return SongFilterCriteria(
      keys: _selectedKeys,
      matchBandKeyOnly: _matchBandKeyOnly,
      category: _selectedCategory,
      datePreset: _selectedDatePreset,
      customDateRange: _customDateRange,
      playedFilter: _selectedPlayedFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final criteria = _buildCriteria();
    final activeCount = criteria.activeFiltersCount;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Asa superior de arrastre
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

            // Encabezado del filtro
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.tune,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Filtros de Repertorio',
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
                          fontSize: 11,
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

            // Contenido escroleable de filtros
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // --- 1. TIPO / CATEGORÍA ---
                  _buildSectionHeader(
                    context,
                    title: 'Tipo de Canción',
                    icon: Icons.category_outlined,
                    trailing: _selectedCategory != null
                        ? TextButton(
                            onPressed: () => setState(() => _selectedCategory = null),
                            child: const Text('Ver todas', style: TextStyle(fontSize: 11.5)),
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryCard(
                          context,
                          title: 'Todas',
                          icon: Icons.all_inclusive,
                          isSelected: _selectedCategory == null,
                          selectedColor: theme.colorScheme.primary,
                          onTap: () => setState(() => _selectedCategory = null),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCategoryCard(
                          context,
                          title: 'Alabanza',
                          icon: Icons.flash_on,
                          isSelected: _selectedCategory == SongCategory.praise,
                          selectedColor: Colors.deepOrange,
                          onTap: () => setState(() {
                            _selectedCategory = _selectedCategory == SongCategory.praise
                                ? null
                                : SongCategory.praise;
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCategoryCard(
                          context,
                          title: 'Adoración',
                          icon: Icons.favorite,
                          isSelected: _selectedCategory == SongCategory.worship,
                          selectedColor: Colors.indigoAccent,
                          onTap: () => setState(() {
                            _selectedCategory = _selectedCategory == SongCategory.worship
                                ? null
                                : SongCategory.worship;
                          }),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // --- 2. TONOS MUSICALES ---
                  _buildSectionHeader(
                    context,
                    title: 'Tonos Musicales (${_selectedKeys.length} seleccionados)',
                    icon: Icons.music_note,
                    trailing: _selectedKeys.isNotEmpty
                        ? TextButton(
                            onPressed: () => setState(() => _selectedKeys.clear()),
                            child: const Text('Desmarcar', style: TextStyle(fontSize: 11.5)),
                          )
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Puedes seleccionar varios tonos para combinarlos.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Atajos rápidos de tonos
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.select_all, size: 16),
                          label: const Text('Mayores Populares (C, D, G, E, A)'),
                          onPressed: () {
                            setState(() {
                              _selectedKeys.addAll(['C', 'D', 'G', 'E', 'A']);
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.music_note, size: 16),
                          label: const Text('Menores Populares (Em, Am, Bm)'),
                          onPressed: () {
                            setState(() {
                              _selectedKeys.addAll(['Em', 'Am', 'Bm']);
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(_showMinorKeys ? 'Ocultar menores' : 'Ver menores'),
                          selected: _showMinorKeys,
                          onSelected: (val) => setState(() => _showMinorKeys = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    'Tonos Mayores:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MusicalKeys.majorKeys.map((key) {
                      final isSelected = _selectedKeys.contains(key);
                      return FilterChip(
                        label: Text(
                          key,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedKeys.add(key);
                            } else {
                              _selectedKeys.remove(key);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  if (_showMinorKeys) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Tonos Menores:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: MusicalKeys.minorKeys.map((key) {
                        final isSelected = _selectedKeys.contains(key);
                        return FilterChip(
                          label: Text(
                            key,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedKeys.add(key);
                              } else {
                                _selectedKeys.remove(key);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 12),
                  // Toggle para coincidir tono de banda vs original
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: const Text('Solo Tono de Banda'),
                      subtitle: Text(
                        _matchBandKeyOnly
                            ? 'Filtra por el tono habitual que toca el ministerio'
                            : 'Filtra si coincide con el tono de banda O el tono original',
                        style: const TextStyle(fontSize: 10.5),
                      ),
                      value: _matchBandKeyOnly,
                      onChanged: (val) => setState(() => _matchBandKeyOnly = val),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // --- 3. FECHAS (DE ADICIÓN AL REPERTORIO) ---
                  _buildSectionHeader(
                    context,
                    title: 'Fecha de Adición al Repertorio',
                    icon: Icons.calendar_month_outlined,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DateFilterPreset.values.map((preset) {
                      final isSelected = _selectedDatePreset == preset;
                      String label = preset.label;

                      if (preset == DateFilterPreset.customRange &&
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
                            if (preset == DateFilterPreset.customRange) {
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

                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // --- 4. HISTORIAL DE CULTOS ---
                  _buildSectionHeader(
                    context,
                    title: 'Filtro por Historial en Cultos',
                    icon: Icons.history,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PlayedFilterOption.values.map((option) {
                      final isSelected = _selectedPlayedFilter == option;
                      return ChoiceChip(
                        label: Text(option.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedPlayedFilter = option);
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),

            // Barra inferior con botón de Aplicar
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

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? selectedColor : theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
