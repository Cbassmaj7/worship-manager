import 'package:flutter/material.dart';
import '../data/analytics_dao.dart';
import '../models/analytics_dtos.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final _analyticsDao = AnalyticsDao();
  late TabController _tabController;
  RotationPlan? _rotationPlan;

  bool _isLoading = true;
  List<MostPlayedStat> _mostPlayed = [];
  List<RecentlyPlayedStat> _recentlyPlayed = [];
  List<ForgottenSongStat> _forgotten = [];

  int _forgottenThresholdDays = 45;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMetrics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _analyticsDao.getMostPlayedSongs(limit: 15),
        _analyticsDao.getRecentlyPlayedSongs(limit: 20),
        _analyticsDao.getForgottenSongs(thresholdDays: _forgottenThresholdDays),
        _analyticsDao.getRotationPlan(),
      ]);

      if (!mounted) return;

      setState(() {
        _mostPlayed = results[0] as List<MostPlayedStat>;
        _recentlyPlayed = results[1] as List<RecentlyPlayedStat>;
        _forgotten = results[2] as List<ForgottenSongStat>;
        _rotationPlan = results[3] as RotationPlan;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando analíticas: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Inteligencia de Rotación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recalcular métricas',
            onPressed: _loadMetrics,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.local_fire_department), text: 'Más Tocadas'),
            Tab(icon: Icon(Icons.history), text: 'Últimas'),
            Tab(icon: Icon(Icons.alarm_off), text: 'En el Olvido'),
            Tab(
              icon: Icon(Icons.auto_awesome),
              text: 'Por Rotar',
            ), // <-- Cuarto Tab
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMetrics,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMostPlayedTab(),
                  _buildRecentlyPlayedTab(),
                  _buildForgottenTab(),
                  _buildRotationTab(),
                ],
              ),
            ),
    );
  }

  // ==========================================
  // TAB 1: CANCIONES MÁS TOCADAS
  // ==========================================
  Widget _buildMostPlayedTab() {
    if (_mostPlayed.isEmpty) {
      return _buildEmptyState(
        icon: Icons.music_off,
        message:
            'Aún no hay suficientes cultos registrados para generar el ranking.',
      );
    }

    final maxPlays = _mostPlayed.first.totalPlayed;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _mostPlayed.length,
      itemBuilder: (context, index) {
        final item = _mostPlayed[index];
        final rank = index + 1;
        final isPraise = item.category == 'PRAISE';

        // Colores de medalla para el top 3
        Color badgeColor = Colors.grey.shade700;
        if (rank == 1) badgeColor = const Color(0xFFFFD700);
        if (rank == 2) badgeColor = const Color(0xFFC0C0C0);
        if (rank == 3) badgeColor = const Color(0xFFCD7F32);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: badgeColor,
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: rank <= 3 ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${item.artist} • Tono base: ${item.defaultKey}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(
                        '${item.totalPlayed} cultos',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: isPraise
                          ? Colors.deepOrange.shade900
                          : Colors.indigo.shade900,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Barra de saturación de repertorio relativa al líder del ranking
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maxPlays > 0 ? (item.totalPlayed / maxPlays) : 0,
                    minHeight: 4,
                    backgroundColor: Colors.grey.shade800,
                    color: isPraise ? Colors.deepOrange : Colors.indigoAccent,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 2: ÚLTIMAS TOCADAS (HISTORIAL RECIENTE)
  // ==========================================
  Widget _buildRecentlyPlayedTab() {
    if (_recentlyPlayed.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_toggle_off,
        message: 'No hay registros de cultos pasados.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _recentlyPlayed.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _recentlyPlayed[index];
        final isPraise = item.category == 'PRAISE';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 2,
          ),
          leading: CircleAvatar(
            backgroundColor: isPraise
                ? Colors.deepOrange.shade800
                : Colors.indigo.shade800,
            child: Text(
              item.lastPlayedKey,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          title: Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${item.artist} • 🎤 ${item.lastLeadVocal}'),
              Text(
                'Última vez: ${item.lastPlayedDate}',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.blueGrey.shade300,
                ),
              ),
            ],
          ),
          trailing: item.lastPlayedKey != item.defaultKey
              ? Tooltip(
                  message: 'Transpuesta (Base de la banda: ${item.defaultKey})',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber.shade700),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Base: ${item.defaultKey}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.amber.shade400,
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  // ==========================================
  // TAB 3: RADAR DE CANCIONES EN EL OLVIDO
  // ==========================================

  Widget _buildForgottenTab() {
    return Column(
      children: [
        // Selector de umbral de días inactivos
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Umbral de inactividad:',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              DropdownButton<int>(
                value: _forgottenThresholdDays,
                underline: const SizedBox(),
                isDense: true,
                items: const [
                  DropdownMenuItem(value: 30, child: Text('> 30 días')),
                  DropdownMenuItem(value: 45, child: Text('> 45 días')),
                  DropdownMenuItem(value: 60, child: Text('> 60 días')),
                  DropdownMenuItem(value: 90, child: Text('> 90 días')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _forgottenThresholdDays = val);
                    _loadMetrics();
                  }
                },
              ),
            ],
          ),
        ),

        Expanded(
          child: _forgotten.isEmpty
              ? _buildEmptyState(
                  icon: Icons.check_circle_outline,
                  message:
                      '¡Excelente rotación! No tienes temas activos abandonados por más de $_forgottenThresholdDays días.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount: _forgotten.length,
                  itemBuilder: (context, index) {
                    final item = _forgotten[index];
                    final neverPlayed = item.lastPlayedDate == null;

                    // Crítico: Alerta roja para más de 90 días o nunca tocadas; ámbar para intermedias
                    final isCritical = neverPlayed || item.daysDormant >= 90;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: isCritical
                              ? Colors.redAccent.withValues(alpha: 0.6)
                              : Colors.orangeAccent.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: Icon(
                          neverPlayed
                              ? Icons.fiber_new
                              : Icons.warning_amber_rounded,
                          color: isCritical
                              ? Colors.redAccent
                              : Colors.orangeAccent,
                          size: 28,
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item.artist} • Tono: ${item.defaultKey}'),
                            Text(
                              neverPlayed
                                  ? '⚠️ Montada pero nunca ha debutado en vivo'
                                  : 'Último culto: ${item.lastPlayedDate}',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: neverPlayed
                                    ? Colors.red.shade300
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCritical
                                ? Colors.red.shade900
                                : Colors.orange.shade900,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            neverPlayed
                                ? 'Debut pendiente'
                                : '${item.daysDormant} días',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 4:
  // ==========================================
  Widget _buildRotationTab() {
    if (_rotationPlan == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final plan = _rotationPlan!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Encabezado explicativo
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.tips_and_updates, color: Colors.amberAccent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sugerencia calculada para evitar la fatiga musical y balancear el próximo setlist.',
                  style: TextStyle(fontSize: 12, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 1. Alabanzas Recomendadas
        Text(
          'Alabanzas a Reactivar (Praise)',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...plan.suggestedPraises.map(
          (s) => _buildSongRecommendationCard(s, Colors.deepOrange),
        ),

        const SizedBox(height: 18),

        // 2. Adoraciones Recomendadas
        Text(
          'Adoraciones para Rotación Fresca (Worship)',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...plan.suggestedWorships.map(
          (s) => _buildSongRecommendationCard(s, Colors.indigoAccent),
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),

        // 3. Cola de Implementación
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'En Montaje / Ensayo',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Chip(
              label: Text('${plan.inRehearsal.length} temas'),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (plan.inRehearsal.isEmpty)
          Text(
            'No hay canciones marcadas en ensayo.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          )
        else
          ...plan.inRehearsal.map(
            (p) => ListTile(
              dense: true,
              leading: const Icon(Icons.music_note, color: Colors.amberAccent),
              title: Text(
                p.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${p.artist} • Tono: ${p.defaultKey}'),
            ),
          ),

        const SizedBox(height: 16),

        // 4. Banco de Sugerencias
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Banco de Sugerencias Pendientes',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Chip(
              label: Text('${plan.inSuggested.length} sugeridas'),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (plan.inSuggested.isEmpty)
          Text(
            'No hay temas propuestos en el banco.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          )
        else
          ...plan.inSuggested.map(
            (p) => ListTile(
              dense: true,
              leading: const Icon(
                Icons.lightbulb_outline,
                color: Colors.tealAccent,
              ),
              title: Text(
                p.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${p.artist} • Tono propuesto: ${p.defaultKey}'),
            ),
          ),
      ],
    );
  }

  Widget _buildSongRecommendationCard(
    RotationRecommendation song,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(
            song.defaultKey,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ),
        title: Text(
          song.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${song.artist} • Inactiva: ${song.daysDormant} días'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            song.lastPlayedDate ?? 'Sin debut',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
