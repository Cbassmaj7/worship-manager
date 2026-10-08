import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_widgets.dart';
import '../data/service_dao.dart';
import '../models/service_filter_criteria.dart';
import '../models/service_model.dart';
import 'create_service_screen.dart';
import 'service_filter_sheet.dart';

class ServiceStyle {
  final Color color;
  final IconData icon;
  final String label;
  const ServiceStyle(this.color, this.icon, this.label);
}

class ServicesListScreen extends StatefulWidget {
  const ServicesListScreen({super.key});

  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
  final _serviceDao = ServiceDao();
  List<ServiceModel> _services = [];
  bool _isLoading = true;

  ServiceFilterCriteria _filterCriteria = const ServiceFilterCriteria();

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    try {
      final data = await _serviceDao.getServicesByCriteria(_filterCriteria);
      if (mounted) {
        setState(() {
          _services = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  ServiceStyle _getServiceStyle(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('mañana') || lower.contains('am')) {
      return const ServiceStyle(
        Color(0xFFF59E0B),
        Icons.wb_sunny_rounded,
        'Mañana',
      );
    } else if (lower.contains('tarde') || lower.contains('pm')) {
      return const ServiceStyle(
        Color(0xFFF97316),
        Icons.wb_twilight_rounded,
        'Tarde',
      );
    } else if (lower.contains('joven') || lower.contains('jóvenes')) {
      return const ServiceStyle(
        Color(0xFFA855F7),
        Icons.local_fire_department_rounded,
        'Jóvenes',
      );
    } else if (lower.contains('vigilia')) {
      return const ServiceStyle(
        Color(0xFF6366F1),
        Icons.nights_stay_rounded,
        'Vigilia',
      );
    } else {
      return const ServiceStyle(
        Color(0xFF10B981),
        Icons.stars_rounded,
        'Especial',
      );
    }
  }

  String _getMonthAbbr(int month) {
    const months = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC',
    ];
    return months[month - 1];
  }

  Future<void> _openFilterSheet() async {
    final updatedCriteria = await ServiceFilterSheet.show(
      context,
      currentCriteria: _filterCriteria,
    );

    if (updatedCriteria != null) {
      setState(() => _filterCriteria = updatedCriteria);
      _loadServices();
    }
  }

  void _clearFilters() {
    setState(() => _filterCriteria = const ServiceFilterCriteria());
    _loadServices();
  }

  Future<void> _editService(ServiceModel service) async {
    // Si el servicio no tiene sus canciones cargadas, hidratarlo antes de editar
    ServiceModel fullService = service;
    if (service.songs.isEmpty) {
      final loaded = await _serviceDao.getServiceWithSongs(service.id!);
      if (loaded != null) fullService = loaded;
    }

    if (!mounted) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateServiceScreen(serviceToEdit: fullService),
      ),
    );

    if (updated == true) {
      _loadServices();
    }
  }

  Future<void> _openServiceDetails(int serviceId) async {
    final service = await _serviceDao.getServiceWithSongs(serviceId);
    if (!mounted || service == null) return;

    final style = _getServiceStyle(service.serviceType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xF2151028),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: AppColors.glassBorder),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  GlassBadge(
                    size: 42,
                    glowColor: style.color,
                    child: Icon(style.icon, color: style.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.serviceType,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          service.date.toIso8601String().substring(0, 10),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botón Editar Culto
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.secondary),
                    tooltip: 'Editar culto',
                    onPressed: () {
                      Navigator.pop(context);
                      _editService(service);
                    },
                  ),
                  // Botón Eliminar Culto
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    tooltip: 'Eliminar culto',
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('¿Eliminar culto?'),
                          content: const Text(
                            'Esta acción borrará el registro de este culto y su setlist. '
                            'Las canciones del repertorio no se verán afectadas.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        navigator.pop();
                        await _serviceDao.deleteService(serviceId);
                        _loadServices();
                      }
                    },
                  ),
                ],
              ),
              if (service.notes != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.glassBorder.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    service.notes!,
                    style: TextStyle(
                      color: AppColors.secondary.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const Divider(height: 28),
              Text(
                'Orden del Servicio (${service.songs.length} canciones):',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: 12),
              if (service.songs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No se registraron canciones para este culto.',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                )
              else
                ...service.songs.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: GlassBadge(
                          size: 32,
                          glowColor: AppColors.primary,
                          child: Text(
                            '${s.orderIndex}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        title: Text(
                          s.songTitle ?? 'Canción #${s.songId}',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '🎤 ${s.leadVocal}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFFD4D4D8)),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Text(
                            s.playedKey,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.tertiary,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    if (!_filterCriteria.isActive) return const SizedBox.shrink();

    final chips = <Widget>[];

    if (_filterCriteria.serviceType != null &&
        _filterCriteria.serviceType != 'Todos') {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.church, size: 16),
          label: Text('Tipo: ${_filterCriteria.serviceType}'),
          onDeleted: () {
            setState(
              () => _filterCriteria = _filterCriteria.copyWith(
                clearServiceType: true,
              ),
            );
            _loadServices();
          },
        ),
      );
    }

    if (_filterCriteria.datePreset != ServiceDatePreset.all) {
      String dateLabel = _filterCriteria.datePreset.label;
      if (_filterCriteria.datePreset == ServiceDatePreset.customRange &&
          _filterCriteria.customDateRange != null) {
        final start = _filterCriteria.customDateRange!.start
            .toIso8601String()
            .substring(0, 10);
        final end = _filterCriteria.customDateRange!.end
            .toIso8601String()
            .substring(0, 10);
        dateLabel = '$start a $end';
      }
      chips.add(
        InputChip(
          avatar: const Icon(Icons.calendar_month, size: 16),
          label: Text(dateLabel),
          onDeleted: () {
            setState(
              () => _filterCriteria = _filterCriteria.copyWith(
                datePreset: ServiceDatePreset.all,
                clearCustomDateRange: true,
              ),
            );
            _loadServices();
          },
        ),
      );
    }

    if (_filterCriteria.searchQuery != null &&
        _filterCriteria.searchQuery!.isNotEmpty) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.search, size: 16),
          label: Text('"${_filterCriteria.searchQuery}"'),
          onDeleted: () {
            setState(
              () => _filterCriteria = _filterCriteria.copyWith(
                clearSearchQuery: true,
              ),
            );
            _loadServices();
          },
        ),
      );
    }

    chips.add(
      ActionChip(
        avatar: const Icon(Icons.close, size: 16, color: Colors.redAccent),
        label: const Text(
          'Limpiar todo',
          style: TextStyle(color: Colors.redAccent),
        ),
        onPressed: _clearFilters,
      ),
    );

    return GlassContainer(
      blur: 12,
      opacity: 0.05,
      borderRadius: BorderRadius.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderColor: AppColors.glassBorder,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips
              .map(
                (chip) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: chip,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _filterCriteria.activeFiltersCount;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Historial de Cultos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar historial',
            onPressed: _loadServices,
          ),
          IconButton(
            tooltip: 'Filtrar cultos',
            onPressed: _openFilterSheet,
            icon: Badge(
              isLabelVisible: activeCount > 0,
              label: Text('$activeCount'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildActiveFilterChips(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryLight,
              backgroundColor: AppColors.surface,
              onRefresh: _loadServices,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryLight,
                      ),
                    )
                  : _services.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GlassBadge(
                                    size: 72,
                                    glowColor: AppColors.primary,
                                    child: Icon(
                                      _filterCriteria.isActive
                                          ? Icons.filter_alt_off
                                          : Icons.event_busy,
                                      size: 36,
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _filterCriteria.isActive
                                        ? 'No se encontraron cultos con los filtros seleccionados.'
                                        : 'Aún no has registrado ningún culto.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(0xFFA1A1AA),
                                        ),
                                  ),
                                  if (_filterCriteria.isActive) ...[
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      onPressed: _clearFilters,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Restablecer filtros'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _services.length,
                      itemBuilder: (context, index) {
                        final item = _services[index];
                        final style = _getServiceStyle(item.serviceType);
                        final day = item.date.day.toString().padLeft(2, '0');
                        final month = _getMonthAbbr(item.date.month);

                        return GlassCard(
                          accentColor: style.color,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 48,
                              height: 52,
                              decoration: BoxDecoration(
                                color: style.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: style.color.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    month,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: style.color,
                                    ),
                                  ),
                                  Text(
                                    day,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            title: Row(
                              children: [
                                Icon(style.icon, size: 16, color: style.color),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.serviceType,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                if (item.notes != null &&
                                    item.notes!.isNotEmpty)
                                  Text(
                                    item.notes!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade400,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                else
                                  Text(
                                    item.date.toIso8601String().substring(
                                      0,
                                      10,
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Píldora de canciones
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.glassBorder,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.music_note,
                                        size: 13,
                                        color: AppColors.tertiary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${item.songCount}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Botón de menú rápido para editar directamente
                                PopupMenuButton<String>(
                                  color: const Color(0xF218132F),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(
                                      color: AppColors.glassBorder,
                                    ),
                                  ),
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      _editService(item);
                                    } else if (val == 'details') {
                                      _openServiceDetails(item.id!);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'details',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.visibility_outlined,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Ver detalles'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            size: 18,
                                            color: AppColors.secondary,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Editar setlist'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () => _openServiceDetails(item.id!),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateServiceScreen()),
          );
          if (created == true) _loadServices();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Culto'),
      ),
    );
  }
}
