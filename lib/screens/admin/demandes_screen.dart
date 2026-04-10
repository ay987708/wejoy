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
  String? _filtreType;

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

  List<dynamic> get _demandes => _data?['demandes'] as List? ?? [];

  List<String> get _types {
    final all = _demandes.map((d) => d['type'] as String? ?? '').toSet().toList();
    all.sort();
    return all;
  }

  List<dynamic> get _filtered {
    if (_filtreType == null) return _demandes;
    return _demandes.where((d) => d['type'] == _filtreType).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final enAttente = _filtered.where((d) => d['statut'] == 'En attente').toList();
    final traitees  = _filtered.where((d) => d['statut'] == 'Traitée').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête ──────────────────────────────────────────
          Text('Demandes des utilisateurs',
              style: GoogleFonts.poppins(
                  fontSize: 26, fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E))),
          Text('Consultez et gérez les demandes envoyées par les utilisateurs',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 28),

          // ── Stat boxes ───────────────────────────────────────
          Wrap(
            spacing: 16, runSpacing: 16,
            children: [
              _statBox('Total',      '${_data?['total']     ?? 0}', Colors.black),
              _statBox('En attente', '${_data?['enAttente'] ?? 0}', const Color(0xFFF59E0B)),
              _statBox('Traitées',   '${_data?['traitees']  ?? 0}', const Color(0xFF22C55E)),
            ],
          ),
          const SizedBox(height: 28),

          // ── Filtre par type ──────────────────────────────────
          if (_types.isNotEmpty) ...[
            Text('Filtrer par type',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: Colors.grey[600])),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _filterChip('Tous', _filtreType == null,
                    () => setState(() => _filtreType = null)),
                ..._types.map((t) => _filterChip(
                    t, _filtreType == t,
                    () => setState(() => _filtreType = t))),
              ],
            ),
            const SizedBox(height: 28),
          ],

          // ── En attente ───────────────────────────────────────
          if (enAttente.isNotEmpty) ...[
            Text('Demandes en attente',
                style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...enAttente.map((d) => _demandeCard(
              demande: d,
              onApprouver: () async {
                await context.read<AdminApiService>().approuverDemande(d['id'].toString());
                _load();
              },
              onRejeter: () async {
                await context.read<AdminApiService>().rejeterDemande(d['id'].toString());
                _load();
              },
            )),
          ],

          // ── Traitées ─────────────────────────────────────────
          if (traitees.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Demandes traitées',
                style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...traitees.map((d) => _demandeCard(demande: d)),
          ],

          // ── Aucun résultat ───────────────────────────────────
          if (enAttente.isEmpty && traitees.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('Aucune demande pour ce filtre',
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey[400])),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Filter chip ───────────────────────────────────────────────────────────
  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFA855F7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? const Color(0xFFA855F7)
                  : const Color(0xFFE5E7EB)),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : Colors.grey[600])),
      ),
    );
  }

  // ── Stat box ──────────────────────────────────────────────────────────────
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
          Text(label,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 32, fontWeight: FontWeight.w700, color: valueColor)),
        ],
      ),
    );
  }

  // ── Demande card ──────────────────────────────────────────────────────────
  Widget _demandeCard({
    required Map<String, dynamic> demande,
    VoidCallback? onApprouver,
    VoidCallback? onRejeter,
  }) {
    final pending = demande['statut'] == 'En attente';

    final initiales = (demande['auteur'] as String? ?? 'U')
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    final typeColors = <String, Color>{
      'Problème technique':      const Color(0xFFEF4444),
      'Signaler un utilisateur': const Color(0xFFF59E0B),
      'Suggestion':              const Color(0xFF3B82F6),
      'Question générale':       const Color(0xFF8B5CF6),
      'Nouvelle activité':       const Color(0xFF22C55E),
      'Autre':                   const Color(0xFF6B7280),
    };
    final typeColor = typeColors[demande['type']] ?? const Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: pending
              ? const Color(0xFFF59E0B).withOpacity(0.3)
              : const Color(0xFF22C55E).withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Bande colorée ─────────────────────────────────────
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: typeColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── En-tête : avatar + infos + badge ─────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar initiales
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(initiales,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: typeColor)),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Nom + date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(demande['auteur'] ?? 'Utilisateur',
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A2E))),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded,
                                  size: 11, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(demande['date'] ?? '',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11, color: Colors.grey[400])),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Badge statut
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: pending
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: pending
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            pending ? 'En attente' : 'Traitée',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: pending
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF22C55E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Type chip + titre ─────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(demande['type'] ?? '',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: typeColor)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(demande['titre'] ?? '',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A2E)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Message ───────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEEEF5)),
                  ),
                  child: Text(demande['message'] ?? '',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.5)),
                ),

                // ── Boutons (en attente) ──────────────────────────
                if (pending &&
                    onApprouver != null &&
                    onRejeter != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onApprouver,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text('Approuver',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: onRejeter,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFEF4444)
                                      .withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.close_rounded,
                                    color: Color(0xFFEF4444), size: 16),
                                const SizedBox(width: 6),
                                Text('Rejeter',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFEF4444))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Résultat (traitée) ────────────────────────────
                if (!pending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        demande['action'] == 'Approuvée'
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: demande['action'] == 'Approuvée'
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        demande['action'] ?? 'Traitée',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: demande['action'] == 'Approuvée'
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}