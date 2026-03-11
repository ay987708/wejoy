import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wejoy/screens/service/admin_api_service.dart';


class DemandesScreen extends StatefulWidget {
  const DemandesScreen({super.key});

  @override
  State<DemandesScreen> createState() => _DemandesScreenState();
}

class _DemandesScreenState extends State<DemandesScreen> {
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
      _data = await context.read<AdminApiService>().getDemandes();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final demandes = _data?['demandes'] as List? ?? [];
    final enAttente = demandes.where((d) => d['statut'] == 'En attente').toList();
    final traitees = demandes.where((d) => d['statut'] == 'Traitée').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Demandes des utilisateurs',
            style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
          Text('Consultez et gérez les demandes envoyées par les utilisateurs',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 28),
          Wrap(
            spacing: 16, runSpacing: 16,
            children: [
              _statBox('Total', '${_data?['total'] ?? 0}', Colors.black),
              _statBox('En attente', '${_data?['enAttente'] ?? 0}', const Color(0xFFF59E0B)),
              _statBox('Traitées', '${_data?['traitees'] ?? 0}', const Color(0xFF22C55E)),
            ],
          ),
          const SizedBox(height: 28),
          if (enAttente.isNotEmpty) ...[
            Text('Demandes en attente',
              style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...enAttente.map((d) => _DemandeCard(
              demande: d,
              onApprouver: () async {
                await context.read<AdminApiService>().approuverDemande(d['id']);
                _load();
              },
              onRejeter: () async {
                await context.read<AdminApiService>().rejeterDemande(d['id']);
                _load();
              },
            )),
          ],
          if (traitees.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Demandes traitées',
              style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...traitees.map((d) => _DemandeCard(demande: d)),
          ],
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color valueColor) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: valueColor)),
        ],
      ),
    );
  }
}

class _DemandeCard extends StatelessWidget {
  final Map<String, dynamic> demande;
  final VoidCallback? onApprouver;
  final VoidCallback? onRejeter;

  const _DemandeCard({required this.demande, this.onApprouver, this.onRejeter});

  @override
  Widget build(BuildContext context) {
    final pending = demande['statut'] == 'En attente';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFF3E8FF),
                child: Text(
                  (demande['auteur'] as String? ?? 'U').split(' ').map((e) => e[0]).take(2).join(),
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFA855F7)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(demande['titre'] ?? '', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('${demande['auteur']} · ${demande['date']}',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(demande['type'] ?? '',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(demande['message'] ?? '', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
          if (pending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: Text('Voir détails', style: GoogleFonts.poppins(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onApprouver,
                  icon: const Icon(Icons.check, size: 16),
                  label: Text('Approuver', style: GoogleFonts.poppins(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF22C55E),
                    side: const BorderSide(color: Color(0xFFDCFCE7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onRejeter,
                  icon: const Icon(Icons.close, size: 16),
                  label: Text('Rejeter', style: GoogleFonts.poppins(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFFEE2E2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF22C55E), size: 16),
                const SizedBox(width: 6),
                Text('${demande['action'] ?? 'Traitée'}',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF22C55E))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}