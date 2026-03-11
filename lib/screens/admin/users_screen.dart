import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const String _base = 'http://localhost:5001';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _users  = [];
  bool _loading         = true;
  final _searchCtrl     = TextEditingController();

  // ── Token ─────────────────────────────────────────────────────────────────
  Future<String?> _getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token'); // token admin
  }

  Future<Map<String, String>> _headers() async {
    final t = await _getToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $t'};
  }

  @override
  void initState() { super.initState(); _load(); }

  // ── Charger utilisateurs ──────────────────────────────────────────────────
  Future<void> _load({String? search}) async {
    setState(() => _loading = true);
    try {
      final url = search != null && search.isNotEmpty
          ? Uri.parse('$_base/api/users?search=$search')
          : Uri.parse('$_base/api/users');
      final res = await http.get(url, headers: await _headers());
      if (res.statusCode == 200) {
        setState(() => _users = jsonDecode(res.body));
      }
    } catch (e) { debugPrint('❌ $e'); }
    setState(() => _loading = false);
  }

  // ── Bloquer / Débloquer ───────────────────────────────────────────────────
  Future<void> _toggleBlock(dynamic u) async {
    final bool isBlocked = u['isBlocked'] == true;
    final String nom     = u['nom'] ?? 'cet utilisateur';
    final String action  = isBlocked ? 'Débloquer' : 'Bloquer';
    final Color  color   = isBlocked ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(
              isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
              color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('$action $nom ?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15))),
        ]),
        content: Text(
          isBlocked
            ? 'L\'utilisateur pourra à nouveau se connecter.'
            : 'L\'utilisateur ne pourra plus se connecter.',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: GoogleFonts.poppins())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action, style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await http.put(
        Uri.parse('$_base/api/users/${u['id']}/block'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        _load(search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              Icon(isBlocked ? Icons.check_circle : Icons.block_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(isBlocked ? '$nom a été débloqué' : '$nom a été bloqué',
                style: GoogleFonts.poppins()),
            ]),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
      }
    } catch (e) { debugPrint('❌ block error: $e'); }
  }

  // ── Supprimer ─────────────────────────────────────────────────────────────
  Future<void> _confirmDelete(dynamic u) async {
    final String nom = u['nom'] ?? 'cet utilisateur';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 22)),
          const SizedBox(width: 10),
          Expanded(child: Text('Supprimer $nom ?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15))),
        ]),
        content: Text('Cette action est irréversible. Le compte sera définitivement supprimé.',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: GoogleFonts.poppins())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await http.delete(
        Uri.parse('$_base/api/users/${u['id']}'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        _load(search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$nom supprimé', style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
      }
    } catch (e) { debugPrint('❌ delete error: $e'); }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Gestion des utilisateurs',
          style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
        Text('Bloquer, débloquer ou supprimer des comptes utilisateurs',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
        const SizedBox(height: 28),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(children: [
            // ── Barre titre + recherche + bouton ──────────────────────────
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Liste des utilisateurs',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                Text('${_users.length} utilisateurs inscrits',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400])),
              ])),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => _load(search: v.isEmpty ? null : v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
                    filled: true, fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFA855F7))),
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 20),

            // ── Tableau ────────────────────────────────────────────────────
            if (_loading)
              const Center(child: CircularProgressIndicator(color: Color(0xFFA855F7)))
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2.5),
                  2: FlexColumnWidth(1.2),
                  3: FlexColumnWidth(1.5),
                  4: FlexColumnWidth(0.8),
                  5: FlexColumnWidth(0.8),
                  6: FlexColumnWidth(1.4),
                },
                children: [
                  // En-têtes
                  TableRow(
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
                    children: ['Utilisateur', 'Email', 'Statut', 'Date', 'Activités', 'Points', 'Actions']
                      .map((h) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Text(h, style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                      )).toList(),
                  ),
                  // Lignes
                  ..._users.map((u) {
                    final bool isBlocked = u['isBlocked'] == true;
                    return TableRow(
                      decoration: BoxDecoration(
                        color: isBlocked ? const Color(0xFFFFF7ED) : Colors.transparent,
                        border: const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                      ),
                      children: [
                        // Nom + avatar
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          child: Row(children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isBlocked
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFF3E8FF),
                              child: Text(u['avatar'] ?? '??',
                                style: GoogleFonts.poppins(
                                  fontSize: 11, fontWeight: FontWeight.w600,
                                  color: isBlocked ? const Color(0xFFF59E0B) : const Color(0xFFA855F7))),
                            ),
                            const SizedBox(width: 10),
                            Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(u['nom'] ?? '',
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                              if (isBlocked)
                                Text('Bloqué', style: GoogleFonts.poppins(
                                  fontSize: 10, color: const Color(0xFFF59E0B))),
                            ])),
                          ]),
                        ),
                        // Email
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          child: Text(u['email'] ?? '',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                        ),
                        // Statut badge
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isBlocked
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(u['statut'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.w500,
                                color: isBlocked ? const Color(0xFFF59E0B) : Colors.white)),
                          ),
                        ),
                        // Date
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          child: Text(u['dateInscription'] ?? '',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                        ),
                        // Activités
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          child: Text('${u['activites'] ?? 0}',
                            style: GoogleFonts.poppins(fontSize: 13)),
                        ),
                        // Points
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          child: Text('${u['points'] ?? 0}',
                            style: GoogleFonts.poppins(fontSize: 13)),
                        ),
                        // Actions
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          child: Row(children: [
                            
                            Tooltip(
                              message: isBlocked ? 'Débloquer' : 'Bloquer',
                              child: IconButton(
                                icon: Icon(
                                  isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                                  size: 18,
                                  color: isBlocked
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFFF59E0B),
                                ),
                                onPressed: () => _toggleBlock(u),
                                splashRadius: 18,
                              ),
                            ),
                            // 🗑️ Bouton Supprimer
                            Tooltip(
                              message: 'Supprimer',
                              child: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Color(0xFFEF4444)),
                                onPressed: () => _confirmDelete(u),
                                splashRadius: 18,
                              ),
                            ),
                          ]),
                        ),
                      ],
                    );
                  }),
                ],
              ),
          ]),
        ),
      ]),
    );
  }
}