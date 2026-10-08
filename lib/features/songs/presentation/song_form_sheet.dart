import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/musical_keys.dart';
import '../../../core/theme/app_theme.dart';
import '../models/song_model.dart';

class SongFormSheet extends StatefulWidget {
  final SongModel? songToEdit;

  const SongFormSheet({super.key, this.songToEdit});

  @override
  State<SongFormSheet> createState() => _SongFormSheetState();
}

class _SongFormSheetState extends State<SongFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _authorController;
  late TextEditingController _bpmController;
  late TextEditingController _urlController;
  late TextEditingController _notesController;

  late String _originalKey;
  late String _defaultKey;
  late SongCategory _category;
  late SongStatus _status;

  @override
  void initState() {
    super.initState();
    final s = widget.songToEdit;
    _titleController = TextEditingController(text: s?.title ?? '');
    _artistController = TextEditingController(text: s?.artist ?? '');
    _authorController = TextEditingController(text: s?.author ?? '');
    _bpmController = TextEditingController(text: s?.bpm?.toString() ?? '');
    _urlController = TextEditingController(text: s?.referenceUrl ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');

    _originalKey = s?.originalKey ?? 'G';
    _defaultKey = s?.defaultKey ?? 'G';
    _category = s?.category ?? SongCategory.worship;
    _status = s?.status ?? SongStatus.suggested;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _authorController.dispose();
    _bpmController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final bpmVal = int.tryParse(_bpmController.text.trim());

    final song = SongModel(
      id: widget.songToEdit?.id,
      title: _titleController.text.trim(),
      artist: _artistController.text.trim(),
      author: _authorController.text.trim().isEmpty
          ? null
          : _authorController.text.trim(),
      originalKey: _originalKey,
      defaultKey: _defaultKey,
      bpm: bpmVal,
      category: _category,
      status: _status,
      referenceUrl: _urlController.text.trim().isEmpty
          ? null
          : _urlController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: widget.songToEdit?.createdAt,
    );

    Navigator.of(context).pop(song);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.songToEdit != null;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xF4140F26),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.glassBorder, width: 1.2),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Asa superior
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Text(
                    isEditing ? 'Editar Canción' : 'Nueva Canción / Sugerencia',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Título
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título de la canción *',
                      prefixIcon: Icon(Icons.music_note),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),

                  // Artista / Ministerio
                  TextFormField(
                    controller: _artistController,
                    decoration: const InputDecoration(
                      labelText: 'Artista / Ministerio *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),

                  // Selectores de Tonos (Original vs Banda)
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _originalKey,
                          decoration: const InputDecoration(
                            labelText: 'Tono Original',
                          ),
                          items: MusicalKeys.all
                              .map(
                                (k) => DropdownMenuItem(value: k, child: Text(k)),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _originalKey = val;
                                if (!isEditing && _defaultKey == 'G') {
                                  _defaultKey = val;
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _defaultKey,
                          decoration: const InputDecoration(
                            labelText: 'Tono Banda',
                          ),
                          items: MusicalKeys.all
                              .map(
                                (k) => DropdownMenuItem(value: k, child: Text(k)),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _defaultKey = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // BPM y Categoría
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _bpmController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'BPM',
                            prefixIcon: Icon(Icons.speed),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SegmentedButton<SongCategory>(
                          segments: const [
                            ButtonSegment(
                              value: SongCategory.praise,
                              label: Text('Alabanza'),
                            ),
                            ButtonSegment(
                              value: SongCategory.worship,
                              label: Text('Adoración'),
                            ),
                          ],
                          selected: {_category},
                          onSelectionChanged: (set) =>
                              setState(() => _category = set.first),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Estado de ciclo de vida
                  DropdownButtonFormField<SongStatus>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Estado en el Repertorio',
                    ),
                    items: SongStatus.values
                        .map(
                          (st) =>
                              DropdownMenuItem(value: st, child: Text(st.label)),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _status = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Enlace de Referencia
                  TextFormField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Enlace (YouTube / Spotify / Audio)',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Notas / Observaciones
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notas (Estructura, dinámica, Capo)',
                      prefixIcon: Icon(Icons.comment),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botón Guardar
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save),
                    label: Text(
                      isEditing ? 'Actualizar Canción' : 'Guardar en Repertorio',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
