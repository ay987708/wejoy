import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wejoy/screens/service/admin_api_service.dart';


class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<dynamic> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _services = await context.read<AdminApiService>().getServices();
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showCreateService() {
    final titreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final horaireCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Créer un service', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(titreCtrl, 'Titre du service'),
              const SizedBox(height: 12),
              _field(descCtrl, 'Description'),
              const SizedBox(height: 12),
              _field(dateCtrl, 'Date'),
              const SizedBox(height: 12),
              _field(horaireCtrl, 'Horaire'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler', style: GoogleFonts.poppins())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white),
            onPressed: () async {
              await context.read<AdminApiService>().createService({
                'titre': titreCtrl.text,
                'description': descCtrl.text,
                'date': dateCtrl.text,
                'horaire': horaireCtrl.text,
                'statut': 'Actif',
                'tags': [],
              });
              if (mounted) Navigator.pop(context);
              _load();
            },
            child: Text('Créer', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  TextField _field(TextEditingController ctrl, String label) => TextField(
    controller: ctrl,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(fontSize: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFA855F7), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gestion des services',
                      style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
                    Text('Gérer les activités et services proposés aux utilisateurs',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateService,
                icon: const Icon(Icons.add, size: 18),
                label: Text('Créer un service', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _services.map((s) => _ServiceCard(
                service: s,
                onDelete: () async {
                  await context.read<AdminApiService>().deleteService(s['id']);
                  _load();
                },
              )).toList(),
            ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onDelete;
  const _ServiceCard({required this.service, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final tags = (service['tags'] as List?) ?? [];
    final participants = service['participants'];
    final maxP = service['maxParticipants'];

    return Container(
      width: 340,
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
              Expanded(
                child: Text(service['titre'] ?? '',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(service['statut'] ?? 'Actif',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(service['description'] ?? '',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(t.toString(), style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700])),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text('${service['date'] ?? ''} - ${service['horaire'] ?? ''}',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
          if (participants != null && maxP != null) ...[
            const SizedBox(height: 4),
            Text('Participants: $participants/$maxP',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text('Modifier', style: GoogleFonts.poppins(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A2E),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                onPressed: onDelete,
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFEE2E2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}