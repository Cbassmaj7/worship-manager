import 'package:flutter/material.dart';
import 'package:worship_manager/core/database/csv_migration_service.dart';
import 'package:worship_manager/core/database/seed_data.dart';
import '../../../core/database/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DatabaseInfo? _info;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final data = await BackupService.getInfo();
      if (mounted) {
        setState(() {
          _info = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleExport() async {
    setState(() => _isProcessing = true);
    try {
      await BackupService.exportDatabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Respaldo generado con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleImport() async {
    // Diálogo de confirmación con advertencia de sobreescritura
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          size: 48,
          color: Colors.amber,
        ),
        title: const Text('¿Restaurar copia de seguridad?'),
        content: const Text(
          'Esta acción sobreescribirá todos los datos locales actuales (canciones, tonos y cultos) '
          'con la información del archivo seleccionado.\n\nEsta operación no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sobreescribir y Restaurar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final success = await BackupService.importDatabase();
      if (!mounted) return;

      if (success) {
        await _loadStats();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Base de datos restaurada exitosamente. Se recargaron los registros.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al restaurar: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Ajustes y Respaldo')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Tarjeta informativa del estado de la base de datos
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storage, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Text(
                              'Estado de la Base de Datos Local',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildInfoRow(
                          'Tamaño del archivo:',
                          _info?.formattedSize ?? '--',
                        ),
                        const SizedBox(height: 6),
                        _buildInfoRow(
                          'Canciones registradas:',
                          '${_info?.totalSongs ?? 0} temas',
                        ),
                        const SizedBox(height: 6),
                        _buildInfoRow(
                          'Cultos en historial:',
                          '${_info?.totalServices ?? 0} eventos',
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ruta: ${_info?.path ?? ''}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade800,
                      child: const Icon(Icons.table_chart, color: Colors.white),
                    ),
                    title: const Text(
                      'Migrar Catálogo desde CSV',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Carga el archivo con canciones, tonos y fechas para reconstruir el histórico.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      try {
                        final result =
                            await CsvMigrationService.pickAndImportCsv();
                        if (result != null && mounted) {
                          await _loadStats();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.green,
                              content: Text(
                                'Migración exitosa: ${result.totalSongs} canciones, '
                                '${result.totalServices} cultos y ${result.totalHistories} ejecuciones en vivo.',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error migrando CSV: $e'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Dentro de children: [ ... ] del ListView:
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.shade800,
                      child: const Icon(
                        Icons.dataset_linked,
                        color: Colors.white,
                      ),
                    ),
                    title: const Text(
                      'Cargar Repertorio Inicial (Seeder)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Inserta las 45 canciones del CSV y sus 13 cultos históricos.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final confirm = await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('¿Cargar datos del CSV?'),
                          content: const Text(
                            'Esto reiniciará y reescribirá la base con las 45 canciones y los 13 cultos del CSV original.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Cargar Seeder'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        setState(() => _isProcessing = true);
                        await SeedData.runSeed(clearExisting: true);
                        await _loadStats();
                        setState(() => _isProcessing = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Seeder ejecutado: 45 canciones y 13 cultos sembrados.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Portabilidad entre Dispositivos',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Botón Exportar
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueGrey,
                      child: Icon(Icons.upload_file, color: Colors.white),
                    ),
                    title: const Text(
                      'Exportar Base de Datos',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Genera un archivo .db para compartir por WhatsApp, Drive o guardar en PC.',
                    ),
                    trailing: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _isProcessing ? null : _handleExport,
                  ),
                ),
                const SizedBox(height: 8),

                // Botón Importar
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.shade900,
                      child: const Icon(
                        Icons.download_for_offline,
                        color: Colors.white,
                      ),
                    ),
                    title: const Text(
                      'Restaurar desde Respaldo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Carga un archivo .db previamente exportado para sincronizar otro celular.',
                    ),
                    trailing: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _isProcessing ? null : _handleImport,
                  ),
                ),
                const SizedBox(height: 24),

                // Instrucciones rápidas de uso
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '¿Cómo sincronizar con otro celular?\n'
                          '1. Pulsa "Exportar" y envíate el archivo por WhatsApp o guárdalo en Google Drive.\n'
                          '2. Instala la app en el otro teléfono y pulsa "Restaurar desde Respaldo".\n'
                          '3. Selecciona el archivo .db descargado y la app quedará clonada al instante.',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.4,
                            color: Colors.blue.shade100,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade400)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
