import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:wejoy/screens/service/admin_api_service.dart';
import '../../widgets/stat_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _data = await context.read<AdminApiService>().getStats();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final croissance = (_data?['croissanceUtilisateurs'] as List?) ?? [];
    final categories = (_data?['activitesParCategorie'] as List?) ?? [];
    final repartition = (_data?['repartitionEngagement'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistiques et analytics',
            style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
          Text('Suivez l\'activité et l\'engagement des utilisateurs',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 28),
          Wrap(
            spacing: 16, runSpacing: 16,
            children: [
              StatCard(title: 'Utilisateurs actifs', value: '${_data?['utilisateursActifs']}', subtitle: '+12% vs mois dernier', icon: Icons.group_outlined),
              StatCard(title: 'Taux d\'engagement', value: '${_data?['tauxEngagement']}%', subtitle: '+5% vs mois dernier', icon: Icons.trending_up),
              StatCard(title: 'Activités créées', value: '${_data?['activitesCrees']}', subtitle: '+8 ce mois', icon: Icons.calendar_today_outlined),
              StatCard(title: 'Badges débloqués', value: '${_data?['badgesDebloques']}', subtitle: '+23 cette semaine', icon: Icons.emoji_events_outlined),
            ],
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final chartCroissance = _buildCroissanceChart(croissance);
              final chartRepartition = _buildPieChart(repartition);
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: chartCroissance),
                        const SizedBox(width: 16),
                        Expanded(child: chartRepartition),
                      ],
                    )
                  : Column(children: [chartCroissance, const SizedBox(height: 16), chartRepartition]);
            },
          ),
          const SizedBox(height: 16),
          _buildBarChart(categories),
          const SizedBox(height: 28),
          Wrap(
            spacing: 16, runSpacing: 16,
            children: [
              _kpiBox('Taux de rétention', '${_data?['tauxRetention']}%', 'Les utilisateurs reviennent régulièrement'),
              _kpiBox('Temps moyen/session', '${_data?['tempsMoyenSession']} min', 'Durée moyenne d\'utilisation'),
              _kpiBox('Satisfaction', '${_data?['satisfaction']}/5', 'Note moyenne des utilisateurs'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCroissanceChart(List data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Croissance des utilisateurs', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
          Text('Évolution du nombre d\'utilisateurs', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400])),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFFF3F4F6), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                        return Text(data[idx]['mois'], style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) =>
                        FlSpot(e.key.toDouble(), (e.value['valeur'] as num).toDouble())
                    ).toList(),
                    isCurved: true,
                    color: const Color(0xFFA855F7),
                    barWidth: 3,
                    dotData: FlDotData(
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFFA855F7),
                        strokeColor: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFA855F7).withOpacity(0.06),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Répartition de l\'engagement', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
          Text('Niveau d\'activité des utilisateurs', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400])),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: data.map((d) {
                  final colorHex = int.parse((d['couleur'] as String).replaceFirst('#', 'FF'), radix: 16);
                  return PieChartSectionData(
                    value: (d['valeur'] as num).toDouble(),
                    title: '${d['label']} ${d['valeur']}%',
                    titleStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white),
                    color: Color(colorHex),
                    radius: 80,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activités par catégorie', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
          Text('Répartition des services proposés', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400])),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFFF3F4F6), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                        return Text(data[idx]['categorie'], style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: (e.value['nombre'] as num).toDouble(),
                      color: const Color(0xFFEC4899),
                      width: 24,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiBox(String label, String value, String subtitle) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[600])),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400])),
        ],
      ),
    );
  }
}