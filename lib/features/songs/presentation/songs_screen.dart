import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_widgets.dart';
import '../data/song_dao.dart';
import '../models/song_filter_criteria.dart';
import '../models/song_model.dart';
import 'song_filter_sheet.dart';
import 'song_form_sheet.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen>
    with SingleTickerProviderStateMixin {
  final _songDao = SongDao();
  late TabController _tabController;
  final _searchController = TextEditingController();

  List<SongModel> _songs = [];
  bool _isLoading = true;

  SongFilterCriteria _filterCriteria = const SongFilterCriteria();

  final List<SongStatus> _tabs = [
    SongStatus.active,
    SongStatus.rehearsing,
    SongStatus.suggested,
    SongStatus.archived,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadSongs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    try {
      final data = await _songDao.getSongsByCriteria(
        criteria: _filterCriteria,
        query: _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _songs = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openFilterSheet() async {
    final updated = await SongFilterSheet.show(
      context,
      currentCriteria: _filterCriteria,
    );
    if (updated != null) {
      setState(() => _filterCriteria = updated);
      _loadSongs();
    }
  }

  void _clearFilters() {
    setState(() => _filterCriteria = const SongFilterCriteria());
    _loadSongs();
  }

  Future<void> _openSongForm([SongModel? songToEdit]) async {
    final result = await showModalBottomSheet<SongModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SongFormSheet(songToEdit: songToEdit),
    );

    if (result != null) {
      if (songToEdit == null) {
        await _songDao.insert(result);
      } else {
        await _songDao.update(result);
      }
      _loadSongs();
    }
  }

  Future<void> _changeStatus(SongModel song, SongStatus newStatus) async {
    await _songDao.updateStatus(song.id!, newStatus);
    _loadSongs();
  }

  Future<void> _deleteSong(SongModel song) async {
    try {
      await _songDao.delete(song.id!);
      _loadSongs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${song.title}" eliminada con éxito.'),
            backgroundColor: AppColors.primaryContainer,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildActiveFilterChips() {
    if (!_filterCriteria.isActive) return const SizedBox.shrink();

    final chips = <Widget>[];

    // Chip de tonos
    if (_filterCriteria.keys.isNotEmpty) {
      final keysList = _filterCriteria.keys.toList()..sort();
      final preview = keysList.length <= 3
          ? keysList.join(', ')
          : '${keysList.take(3).join(', ')} +${keysList.length - 3}';

      chips.add(
        InputChip(
          avatar: const Icon(Icons.music_note, size: 16),
          label: Text('Tono: $preview'),
          onPressed: _openFilterSheet,
          onDeleted: () {
            setState(() {
              _filterCriteria = _filterCriteria.copyWith(keys: {});
            });
            _loadSongs();
          },
        ),
      );
    }

    // Chip de tipo / categoría
    if (_filterCriteria.category != null) {
      final isPraise = _filterCriteria.category == SongCategory.praise;
      chips.add(
        InputChip(
          avatar: Icon(
            isPraise ? Icons.flash_on : Icons.favorite,
            size: 16,
            color: isPraise ? AppColors.accentPraise : AppColors.primaryLight,
          ),
          label: Text('Tipo: ${_filterCriteria.category!.label}'),
          onPressed: _openFilterSheet,
          onDeleted: () {
            setState(() {
              _filterCriteria = _filterCriteria.copyWith(clearCategory: true);
            });
            _loadSongs();
          },
        ),
      );
    }

    // Chip de fechas
    if (_filterCriteria.datePreset != DateFilterPreset.all) {
      String dateLabel = _filterCriteria.datePreset.label;
      if (_filterCriteria.datePreset == DateFilterPreset.customRange &&
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
          onPressed: _openFilterSheet,
          onDeleted: () {
            setState(() {
              _filterCriteria = _filterCriteria.copyWith(
                datePreset: DateFilterPreset.all,
                clearCustomDateRange: true,
              );
            });
            _loadSongs();
          },
        ),
      );
    }

    // Chip de historial de culto
    if (_filterCriteria.playedFilter != PlayedFilterOption.any) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.history, size: 16),
          label: Text(_filterCriteria.playedFilter.label),
          onPressed: _openFilterSheet,
          onDeleted: () {
            setState(() {
              _filterCriteria = _filterCriteria.copyWith(
                playedFilter: PlayedFilterOption.any,
              );
            });
            _loadSongs();
          },
        ),
      );
    }

    // Botón de limpiar todos
    chips.add(
      ActionChip(
        avatar: const Icon(Icons.close, size: 16, color: Colors.redAccent),
        label: const Text(
          'Limpiar filtros',
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
                (c) =>
                    Padding(padding: const EdgeInsets.only(right: 8), child: c),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDetailBadge(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.secondary),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 9.5, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = _tabs[_tabController.index];
    final filteredSongs = _songs
        .where((s) => s.status == currentStatus)
        .toList();
    final activeFiltersCount = _filterCriteria.activeFiltersCount;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Repertorio de Worship'),
        actions: [
          // Botón para refrescar
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar canciones',
            onPressed: _loadSongs,
          ),
          // Botón de filtros con badge
          IconButton(
            tooltip: 'Filtros avanzados',
            onPressed: _openFilterSheet,
            icon: Badge(
              isLabelVisible: activeFiltersCount > 0,
              label: Text('$activeFiltersCount'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.tune),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Buscador integrado + Botón de filtro rápido
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => _loadSongs(),
                        decoration: InputDecoration(
                          hintText: 'Buscar por título o artista...',
                          prefixIcon: const Icon(Icons.search, size: 22),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadSongs();
                                  },
                                )
                              : null,
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.glassWhite,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Filtros avanzados',
                      onPressed: _openFilterSheet,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer.withValues(
                          alpha: 0.6,
                        ),
                        foregroundColor: AppColors.primaryLight,
                      ),
                      icon: Badge(
                        isLabelVisible: activeFiltersCount > 0,
                        label: Text('$activeFiltersCount'),
                        backgroundColor: AppColors.primary,
                        child: const Icon(Icons.filter_list),
                      ),
                    ),
                  ],
                ),
              ),
              // Pestañas por estado
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _tabs.map((status) {
                  final count = _songs.where((s) => s.status == status).length;
                  return Tab(text: '${status.label} ($count)');
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Barra de filtros activos stackeables
          _buildActiveFilterChips(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryLight,
              backgroundColor: AppColors.surface,
              onRefresh: _loadSongs,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryLight,
                      ),
                    )
                  : filteredSongs.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
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
                                          : Icons.music_off,
                                      size: 36,
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _filterCriteria.isActive
                                        ? 'No hay canciones en "${currentStatus.label}" con los filtros seleccionados.'
                                        : 'No hay canciones en "${currentStatus.label}".',
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
                      itemCount: filteredSongs.length,
                      itemBuilder: (context, index) {
                        final song = filteredSongs[index];
                        final isPraise = song.category == SongCategory.praise;
                        final accentColor = isPraise
                            ? AppColors.accentPraise
                            : AppColors.primary;

                        return GlassCard(
                          accentColor: accentColor,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          padding: EdgeInsets.zero,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              key: PageStorageKey('song_tile_${song.id}'),
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              leading: GlassBadge(
                                size: 46,
                                glowColor: accentColor,
                                child: Text(
                                  song.defaultKey,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              title: Text(
                                song.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    '${song.artist} • ${song.bpm != null ? "${song.bpm} BPM" : "Tempo s/d"}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(0xFFD4D4D8),
                                        ),
                                  ),
                                  if (song.originalKey != song.defaultKey) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Orig: ${song.originalKey} -> Banda: ${song.defaultKey}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: Colors.amber.shade300,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text(
                                      song.category.label,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: isPraise
                                            ? AppColors.accentPraise
                                            : AppColors.primaryLight,
                                      ),
                                    ),
                                    backgroundColor: accentColor.withValues(
                                      alpha: 0.15,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    side: BorderSide(
                                      color: accentColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    color: const Color(0xF218132F),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(
                                        color: AppColors.glassBorder,
                                      ),
                                    ),
                                    onSelected: (action) {
                                      if (action == 'edit') {
                                        _openSongForm(song);
                                      } else if (action == 'delete') {
                                        _deleteSong(song);
                                      } else if (action.startsWith('status_')) {
                                        final statusKey = action.replaceFirst(
                                          'status_',
                                          '',
                                        );
                                        final targetStatus = SongStatus.values
                                            .firstWhere(
                                              (e) => e.dbValue == statusKey,
                                            );
                                        _changeStatus(song, targetStatus);
                                      }
                                    },
                                    itemBuilder: (context) => [
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
                                            Text('Editar'),
                                          ],
                                        ),
                                      ),
                                      if (song.status != SongStatus.active)
                                        const PopupMenuItem(
                                          value: 'status_ACTIVE',
                                          child: Text('Pasar a Activa'),
                                        ),
                                      if (song.status != SongStatus.rehearsing)
                                        const PopupMenuItem(
                                          value: 'status_REHEARSING',
                                          child: Text('Pasar a Ensayo'),
                                        ),
                                      if (song.status != SongStatus.archived)
                                        const PopupMenuItem(
                                          value: 'status_ARCHIVED',
                                          child: Text('Archivar'),
                                        ),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: Colors.redAccent,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Eliminar',
                                              style: TextStyle(
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // CONTENIDO EXPANDIBLE DE DETALLES
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(
                                    left: 12,
                                    right: 12,
                                    bottom: 12,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.glassBorder.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildDetailBadge(
                                            'Tono Grabación',
                                            song.originalKey,
                                            Icons.album,
                                          ),
                                          _buildDetailBadge(
                                            'Tono Banda',
                                            song.defaultKey,
                                            Icons.queue_music,
                                          ),
                                          _buildDetailBadge(
                                            'Tempo',
                                            song.bpm != null
                                                ? '${song.bpm} BPM'
                                                : '--',
                                            Icons.speed,
                                          ),
                                        ],
                                      ),
                                      if (song.author != null &&
                                          song.author!.isNotEmpty) ...[
                                        const Divider(
                                          height: 18,
                                          color: AppColors.glassBorder,
                                        ),
                                        Text(
                                          'Compositor: ${song.author}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                      if (song.referenceUrl != null &&
                                          song.referenceUrl!.isNotEmpty) ...[
                                        const Divider(
                                          height: 18,
                                          color: AppColors.glassBorder,
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.link,
                                              size: 15,
                                              color: AppColors.tertiary,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                song.referenceUrl ?? 'No URL',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: AppColors.primaryLight,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (song.notes != null &&
                                          song.notes!.isNotEmpty) ...[
                                        const Divider(
                                          height: 18,
                                          color: AppColors.glassBorder,
                                        ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.comment_outlined,
                                              size: 15,
                                              color: Colors.amberAccent,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                song.notes!,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: Colors.grey.shade300,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSongForm(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }
}
