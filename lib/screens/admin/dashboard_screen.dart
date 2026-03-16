import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wejoy/screens/service/admin_api_service.dart';
import 'package:wejoy/screens/admin/stats_screen.dart';
import 'package:wejoy/widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<AdminApiService>().getDashboard();
      setState(() { _data = data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tableau de bord',
            style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)),
          ),
          Text('Vue d\'ensemble de l\'activité de la plateforme',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 28),

          // Stats cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              StatCard(
                title: 'Utilisateurs totaux',
                value: '${_data?['utilisateursTotaux'] ?? 0}',
                subtitle: '${_data?['utilisateursActifs'] ?? 0} actifs ce mois',
                icon: Icons.group_outlined,
              ),
              StatCard(
                title: 'Activités',
                value: '${_data?['activites'] ?? 0}',
                subtitle: 'Services proposés',
                icon: Icons.calendar_today_outlined,
              ),
              StatCard(
                title: 'Demandes',
                value: '${_data?['demandes'] ?? 0}',
                subtitle: '${_data?['demandesEnAttente'] ?? 0} en attente',
                icon: Icons.chat_bubble_outline_rounded,
              ),
              StatCard(
                title: 'Engagement',
                value: '${_data?['engagement'] ?? 0}%',
                subtitle: 'Taux de participation',
                icon: Icons.bar_chart_rounded,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Two columns
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final children = [
                _buildActivitesRecentes(),
                _buildActionsRapides(),
              ];
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children.map((w) => Expanded(child: w)).toList(),
                    )
                  : Column(children: [children[0], const SizedBox(height: 16), children[1]]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivitesRecentes() {
    final activites = _data?['activitesRecentes'] as List? ?? [];
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activités récentes',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
          Text('Dernières actions sur la plateforme',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400])),
          const SizedBox(height: 20),
          ...activites.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E), shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a['temps'] ?? '', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400])),
                    Text(a['message'] ?? '', style: GoogleFonts.poppins(fontSize: 13)),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionsRapides() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Actions rapides',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
          Text('Accès rapide aux fonctionnalités',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400])),
          const SizedBox(height: 20),
          _quickAction(Icons.notifications_outlined, 'Envoyer une notification', Colors.black),
          const SizedBox(height: 10),
          _quickAction(Icons.person_add_outlined, 'Ajouter un utilisateur', const Color(0xFF1A1A2E)),
          const SizedBox(height: 10),
          _quickAction(Icons.add_circle_outline, 'Créer un service', const Color(0xFF1A1A2E)),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, Color bg) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 18),
        label: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
