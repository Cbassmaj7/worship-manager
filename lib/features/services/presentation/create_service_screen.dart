import 'package:flutter/material.dart';
import '../../../core/constants/musical_keys.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_widgets.dart';
import '../../songs/data/song_dao.dart';
import '../../songs/models/song_model.dart';
import '../data/service_dao.dart';
import '../models/service_model.dart';
import '../models/service_song_model.dart';

class CreateServiceScreen extends StatefulWidget {
  final ServiceModel? serviceToEdit; // <-- Parámetro opcional para edición

  const CreateServiceScreen({super.key, this.serviceToEdit});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _serviceDao = ServiceDao();
  final _songDao = SongDao();

  late DateTime _selectedDate;
  late String _selectedServiceType;
  late TextEditingController _notesController;

  final List<String> _serviceTypes = [
    'Domingo Mañana',
    'Domingo Tarde',
    'Culto de Jóvenes',
    'Vigilia',
    'Servicio Especial',
  ];

  // Lista local en memoria del setlist que se va armando
  final List<ServiceSongModel> _setlist = [];
  bool _isSaving = false;
  bool get _isEditing => widget.serviceToEdit != null;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final s = widget.serviceToEdit;
    _selectedDate = s?.date ?? DateTime.now();
    _selectedServiceType = s?.serviceType ?? 'Domingo Mañana';
    _notesController = TextEditingController(text: s?.notes ?? '');

    // Si viene para edición, precargamos el setlist
    if (s != null && s.songs.isNotEmpty) {
      _setlist.addAll(s.songs);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  /// Modal para buscar y agregar canciones activas al culto
  Future<void> _openSongPicker() async {
    final activeSongs = await _songDao.getSongs(status: SongStatus.active);

    if (!mounted) return;

    if (activeSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No tienes canciones con estado "Activa" en el catálogo.',
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xF4140F26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: AppColors.glassBorder, width: 1.2),
      ),
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = activeSongs.where((s) {
              final q = searchQuery.toLowerCase();
              return s.title.toLowerCase().contains(q) ||
                  s.artist.toLowerCase().contains(q);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: 480,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Agregar Canción al Culto',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Filtrar canciones activas...',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (val) =>
                          setModalState(() => searchQuery = val),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No se encontraron temas coincidentes.',
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final song = filtered[index];
                                final isAlreadyAdded = _setlist.any(
                                  (item) => item.songId == song.id,
                                );
                                final isPraise =
                                    song.category == SongCategory.praise;

                                return ListTile(
                                  dense: true,
                                  leading: GlassBadge(
                                    size: 38,
                                    glowColor: isPraise
                                        ? AppColors.accentPraise
                                        : AppColors.primary,
                                    child: Text(
                                      song.defaultKey,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    song.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${song.artist} • ${song.bpm ?? '--'} BPM',
                                  ),
                                  trailing: isAlreadyAdded
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.greenAccent,
                                        )
                                      : const Icon(
                                          Icons.add_circle_outline,
                                          color: AppColors.primaryLight,
                                        ),
                                  onTap: () {
                                    if (isAlreadyAdded) return;
                                    setState(() {
                                      _setlist.add(
                                        ServiceSongModel(
                                          serviceId: 0,
                                          songId: song.id!,
                                          playedKey: song.defaultKey,
                                          leadVocal: 'Voz Principal',
                                          orderIndex: _setlist.length + 1,
                                          songTitle: song.title,
                                          songArtist: song.artist,
                                          category: song.category.dbValue,
                                        ),
                                      );
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Editar el tono de ejecución o el líder vocal de un item del setlist
  Future<void> _editSetlistItem(int index) async {
    final item = _setlist[index];
    String currentKey = item.playedKey;
    final vocalController = TextEditingController(text: item.leadVocal);

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item.songTitle ?? 'Ajustar Canción'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: currentKey,
                decoration: const InputDecoration(
                  labelText: 'Tono en vivo para este culto',
                  border: OutlineInputBorder(),
                ),
                items: MusicalKeys.all
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => currentKey = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: vocalController,
                decoration: const InputDecoration(
                  labelText: 'Líder Vocal',
                  prefixIcon: Icon(Icons.mic),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (updated == true) {
      setState(() {
        _setlist[index] = ServiceSongModel(
          id: item.id,
          serviceId: item.serviceId,
          songId: item.songId,
          playedKey: currentKey,
          leadVocal: vocalController.text.trim().isEmpty
              ? 'Voz Principal'
              : vocalController.text.trim(),
          orderIndex: item.orderIndex,
          feedback: item.feedback,
          songTitle: item.songTitle,
          songArtist: item.songArtist,
          category: item.category,
        );
      });
    }
  }

  Future<void> _saveService() async {
    if (_setlist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes agregar al menos una canción al setlist.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final service = ServiceModel(
        id: widget.serviceToEdit?.id,
        date: _selectedDate,
        serviceType: _selectedServiceType,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (_isEditing) {
        await _serviceDao.updateServiceWithSongs(service, _setlist);
      } else {
        await _serviceDao.createServiceWithSongs(service, _setlist);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Culto actualizado exitosamente.'
                  : 'Culto registrado con éxito.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Culto' : 'Armar Culto / Setlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Guardar Culto',
            onPressed: _isSaving ? null : _saveService,
          ),
        ],
      ),
      body: GlassBackground(
        child: Column(
          children: [
            // Metadatos del evento (Fecha y Tipo de Culto)
            Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedServiceType,
                            isDense: true,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            items: _serviceTypes
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedServiceType = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText:
                            'Notas opcionales (Predicador, temática, etc.)',
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Encabezado de la lista
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Setlist (${_setlist.length} temas)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openSongPicker,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar tema'),
                  ),
                ],
              ),
            ),

            // ReorderableListView interactivo
            Expanded(
              child: _setlist.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GlassBadge(
                            size: 72,
                            glowColor: AppColors.primary,
                            child: const Icon(
                              Icons.playlist_add,
                              size: 36,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'El setlist está vacío.\nToca "Agregar tema" para armar el culto.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFFA1A1AA)),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: _setlist.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) newIndex -= 1;
                          final item = _setlist.removeAt(oldIndex);
                          _setlist.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final item = _setlist[index];
                        final isPraise = item.category == 'PRAISE';

                        return GlassCard(
                          key: ValueKey('${item.songId}_$index'),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          accentColor: isPraise
                              ? AppColors.accentPraise
                              : AppColors.primary,
                          child: ListTile(
                            leading: GlassBadge(
                              size: 36,
                              glowColor: AppColors.primary,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            title: Text(
                              item.songTitle ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _editSetlistItem(index),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPraise
                                          ? AppColors.accentPraise.withValues(
                                              alpha: 0.3,
                                            )
                                          : AppColors.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isPraise
                                            ? AppColors.accentPraise
                                            : AppColors.primaryLight,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'Tono: ${item.playedKey}',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '🎤 ${item.leadVocal}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  tooltip: 'Cambiar tono o voz',
                                  onPressed: () => _editSetlistItem(index),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  tooltip: 'Quitar del setlist',
                                  onPressed: () =>
                                      setState(() => _setlist.removeAt(index)),
                                ),
                                const ReorderableDragStartListener(
                                  index: 0,
                                  child: Icon(
                                    Icons.drag_handle,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
