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
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await context.read<AdminApiService>().getServices();
      if (mounted) setState(() => _services = list);
    } catch (e) {
      debugPrint('❌ getServices: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  // ── Formulaire créer / modifier ───────────────────────────────────────────
  void _showForm({dynamic service}) {
    final titreCtrl    = TextEditingController(text: service?['titre'] ?? '');
    final descCtrl     = TextEditingController(text: service?['description'] ?? '');
    final imageCtrl    = TextEditingController(text: service?['imageUrl'] ?? '');
    final dateCtrl     = TextEditingController();
    final horaireCtrl  = TextEditingController(text: service?['horaire'] ?? '');
    final maxCtrl      = TextEditingController(text: service?['maxParticipants']?.toString() ?? '');
    final locationCtrl = TextEditingController(text: service?['location'] ?? '');
    String selCat  = (service?['tags'] as List?)?.isNotEmpty == true ? service['tags'][0] : 'Cuisine';
    String selType = ((service?['tags'] as List?)?.length ?? 0) > 1 ? service['tags'][1] : 'Collectif';
    final isEdit = service != null;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 560,
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // En-tête
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFFEC4899)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(isEdit ? 'Modifier le service' : 'Créer un service',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ]),
                const SizedBox(height: 20),
                _field(titreCtrl, 'Titre du service', Icons.title_rounded),
                const SizedBox(height: 12),
                _field(descCtrl, 'Description', Icons.description_outlined, maxLines: 3),
                const SizedBox(height: 12),
                _field(imageCtrl, 'URL de l\'image (optionnel)', Icons.image_outlined),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _dropdown(selCat,
                    ['Cuisine', 'Lecture', 'Jardinage', 'Yoga', 'Sport', 'Autre'],
                    (v) => setS(() => selCat = v!))),
                  const SizedBox(width: 12),
                  Expanded(child: _dropdown(selType,
                    ['Collectif', 'Individuel'],
                    (v) => setS(() => selType = v!))),
                ]),
                const SizedBox(height: 12),
                _field(dateCtrl, 'Date (ex: 2026-03-20)', Icons.calendar_today_outlined),
                const SizedBox(height: 12),
                _field(horaireCtrl, 'Horaire (ex: 14h00 - 16h00)', Icons.access_time_rounded),
                const SizedBox(height: 12),
                _field(maxCtrl, 'Participants max', Icons.group_outlined, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _field(locationCtrl, 'Lieu (optionnel)', Icons.location_on_outlined),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Annuler', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA855F7), foregroundColor: Colors.white,
                      elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (titreCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('Titre et description obligatoires'),
                          backgroundColor: Colors.red,
                        ));
                        return;
                      }
                      Navigator.pop(ctx);
                      await _save(
                        id: service?['id']?.toString(),
                        isEdit: isEdit,
                        body: {
                          'titre':           titreCtrl.text.trim(),
                          'description':     descCtrl.text.trim(),
                          'imageUrl':        imageCtrl.text.trim(),
                          'category':        selCat,
                          'type':            selType,
                          'date':            dateCtrl.text.trim().isEmpty ? null : dateCtrl.text.trim(),
                          'horaire':         horaireCtrl.text.trim().isEmpty ? null : horaireCtrl.text.trim(),
                          'maxParticipants': maxCtrl.text.trim().isEmpty ? null : maxCtrl.text.trim(),
                          'location':        locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
                        },
                      );
                    },
                    child: Text(isEdit ? 'Modifier' : 'Créer',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save({String? id, required bool isEdit, required Map<String, dynamic> body}) async {
    try {
      if (isEdit) {
        await context.read<AdminApiService>().updateService(id! as String, body);
      } else {
        await context.read<AdminApiService>().createService(body);
      }
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(isEdit ? 'Service modifié ✅' : 'Service créé et utilisateurs notifiés ✅',
              style: GoogleFonts.poppins()),
          ]),
          backgroundColor: const Color(0xFFA855F7),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      debugPrint('❌ _save: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _delete(dynamic s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Supprimer "${s['titre']}" ?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
        content: Text('Ce service sera supprimé définitivement.',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: GoogleFonts.poppins())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await context.read<AdminApiService>().deleteService(s['id'].toString() as String);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Service supprimé', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      debugPrint('❌ delete: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Gestion des services',
              style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
            Text('Gérer les activités et services proposés aux utilisateurs',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
          ])),
          ElevatedButton.icon(
            onPressed: () => _showForm(),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text('Créer un service', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white, elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
        const SizedBox(height: 28),
        _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFA855F7)))
          : _services.isEmpty
            ? Center(child: Padding(
                padding: const EdgeInsets.all(60),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Aucun service pour le moment',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[400])),
                  const SizedBox(height: 8),
                  Text('Cliquez sur "Créer un service" pour commencer',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400])),
                ]),
              ))
            : Wrap(
                spacing: 20, runSpacing: 20,
                children: _services.map((s) => _buildCard(s)).toList(),
              ),
      ]),
    );
  }

  Widget _buildCard(dynamic s) {
    final tags = (s['tags'] as List?)?.cast<String>() ?? [];
    return Container(
      width: 360,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Image ou placeholder par catégorie ──────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: (s['imageUrl'] != null && s['imageUrl'].toString().isNotEmpty)
            ? Image.network(
                s['imageUrl'],
                height: 140, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _categoryPlaceholder(tags.isNotEmpty ? tags[0] : 'Autre'),
              )
            : _categoryPlaceholder(tags.isNotEmpty ? tags[0] : 'Autre'),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text(s['titre'] ?? '',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20)),
            child: Text('Actif', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(s['description'] ?? '',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], height: 1.4),
          maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 10),
        Wrap(spacing: 6, children: tags.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(6)),
          child: Text(t, style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFFA855F7), fontWeight: FontWeight.w500)),
        )).toList()),
        const SizedBox(height: 12),
        if (s['date'] != null) Row(children: [
          Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey[400]),
          const SizedBox(width: 6),
          Expanded(child: Text(
            '${s['date']}${s['horaire'] != null ? ' - ${s['horaire']}' : ''}',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]))),
        ]),
        if (s['maxParticipants'] != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.people_outline_rounded, size: 13, color: Colors.grey[400]),
            const SizedBox(width: 6),
            Text('Participants: ${s['participants'] ?? 0}/${s['maxParticipants']}',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
          ]),
        ],
        if (s['location'] != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[400]),
            const SizedBox(width: 6),
            Text('${s['location']}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
          ]),
        ],
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () => _showForm(service: s),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text('Modifier', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700], side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
            onPressed: () => _delete(s),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _categoryPlaceholder(String category) {
    final Map<String, Map<String, dynamic>> config = {
      'Cuisine':   {'icon': Icons.restaurant_rounded,     'color': const Color(0xFFFF6B6B)},
      'Lecture':   {'icon': Icons.menu_book_rounded,      'color': const Color(0xFF4ECDC4)},
      'Jardinage': {'icon': Icons.yard_rounded,           'color': const Color(0xFF45B7D1)},
      'Yoga':      {'icon': Icons.self_improvement_rounded,'color': const Color(0xFF96CEB4)},
      'Sport':     {'icon': Icons.sports_soccer_rounded,  'color': const Color(0xFFA855F7)},
      'Autre':     {'icon': Icons.category_rounded,       'color': const Color(0xFF6366F1)},
    };
    final cfg = config[category] ?? config['Autre']!;
    return Container(
      height: 140, width: double.infinity,
      decoration: BoxDecoration(
        color: (cfg['color'] as Color).withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(cfg['icon'] as IconData, size: 48, color: cfg['color'] as Color),
        const SizedBox(height: 8),
        Text(category, style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: cfg['color'] as Color,
        )),
      ]),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl, maxLines: maxLines, keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey[400]),
        filled: true, fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFA855F7), width: 2)),
      ),
    );
  }

  Widget _dropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF)),
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1A1A2E)),
          items: items.map((i) => DropdownMenuItem(value: i,
            child: Text(i, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}