import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wejoy/screens/service/admin_api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifs = [];
  bool _loading = true;

  final _titreCtrl   = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _emailCtrl   = TextEditingController();
  bool _sending = false;
  bool _toBroadcast = true; // toggle tous / par email

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _messageCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _notifs = await context.read<AdminApiService>().getNotifications();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _send() async {
    if (_titreCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      _snack('Veuillez remplir le titre et le message', error: true);
      return;
    }
    if (!_toBroadcast && _emailCtrl.text.trim().isEmpty) {
      _snack('Veuillez entrer un email destinataire', error: true);
      return;
    }

    setState(() => _sending = true);
    try {
      await context.read<AdminApiService>().sendNotification({
        'titre':   _titreCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'type':    'info',
        'email':   _toBroadcast ? '@tous' : _emailCtrl.text.trim(),
      });
      _titreCtrl.clear();
      _messageCtrl.clear();
      _emailCtrl.clear();
      _snack('Notification envoyée ✅');
      _load();
    } catch (e) {
      _snack('Erreur : $e', error: true);
    }
    setState(() => _sending = false);
  }

  Future<void> _delete(String id) async {
    final confirm = await _confirmDialog('Supprimer cette notification ?');
    if (!confirm) return;
    try {
      await context.read<AdminApiService>().deleteNotification(id);
      _snack('Notification supprimée');
      _load();
    } catch (e) {
      _snack('Erreur : $e', error: true);
    }
  }

  Future<void> _edit(Map<String, dynamic> notif) async {
    final titreCtrl   = TextEditingController(text: notif['titre'] ?? '');
    final messageCtrl = TextEditingController(text: notif['message'] ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Modifier la notification',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titreCtrl,
              decoration: _inputDeco('Titre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageCtrl,
              maxLines: 3,
              decoration: _inputDeco('Message'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: GoogleFonts.poppins(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA855F7),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sauvegarder',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<AdminApiService>().updateNotification(
          notif['_id'] ?? notif['id'],
          {'titre': titreCtrl.text.trim(), 'message': messageCtrl.text.trim()},
        );
        _snack('Notification modifiée ✅');
        _load();
      } catch (e) {
        _snack('Erreur : $e', error: true);
      }
    }
  }

  Future<bool> _confirmDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Confirmation',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Annuler',
                    style: GoogleFonts.poppins(color: Colors.grey[600])),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text('Confirmer',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      backgroundColor:
          error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête ──────────────────────────────────────────
          Text('Notifications',
              style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E))),
          Text('Envoyez des notifications ciblées ou globales',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 28),

          // ── Formulaire ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Color(0xFFA855F7), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Envoyer une notification',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Toggle tous / par email ───────────────────
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _toggleBtn('Tous les utilisateurs',
                          _toBroadcast, () => setState(() => _toBroadcast = true))),
                      Expanded(child: _toggleBtn('Par email',
                          !_toBroadcast, () => setState(() => _toBroadcast = false))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Champ email (si ciblé) ────────────────────
                if (!_toBroadcast) ...[
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDeco(
                        'Email du destinataire', Icons.alternate_email),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Titre ─────────────────────────────────────
                TextField(
                  controller: _titreCtrl,
                  decoration: _inputDeco('Titre de la notification',
                      Icons.title_rounded),
                ),
                const SizedBox(height: 12),

                // ── Message ───────────────────────────────────
                TextField(
                  controller: _messageCtrl,
                  maxLines: 3,
                  decoration:
                      _inputDeco('Message', Icons.message_outlined),
                ),
                const SizedBox(height: 20),

                // ── Bouton envoyer ────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _toBroadcast
                          ? 'Envoyer à tous les utilisateurs'
                          : 'Envoyer au destinataire',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Historique ───────────────────────────────────────
          Text('Historique des notifications',
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_notifs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Icon(Icons.notifications_off_outlined,
                        size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('Aucune notification envoyée',
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey[400])),
                  ],
                ),
              ),
            )
          else
            ..._notifs.map((n) => _notifCard(n)),
        ],
      ),
    );
  }

  // ── Notification card ─────────────────────────────────────────────────────
  Widget _notifCard(Map<String, dynamic> n) {
    final isBroadcast = n['broadcast'] == true || n['destinataire'] == 'Tous les utilisateurs';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isBroadcast
                  ? const Color(0xFFF3E8FF)
                  : const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isBroadcast
                  ? Icons.campaign_outlined
                  : Icons.person_outline_rounded,
              color: isBroadcast
                  ? const Color(0xFFA855F7)
                  : const Color(0xFF0EA5E9),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre + badge
                Row(
                  children: [
                    Expanded(
                      child: Text(n['titre'] ?? '',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A2E))),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isBroadcast
                            ? const Color(0xFFF3E8FF)
                            : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isBroadcast ? 'Broadcast' : 'Ciblé',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isBroadcast
                              ? const Color(0xFFA855F7)
                              : const Color(0xFF0EA5E9),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Message
                Text(n['message'] ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 8),

                // Destinataire + date
                Row(
                  children: [
                    Icon(Icons.group_outlined,
                        size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      isBroadcast
                          ? '${n['envoyees'] ?? 0} destinataires'
                          : (n['destinataire'] ?? ''),
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey[400]),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time_rounded,
                        size: 11, color: Colors.grey[300]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(n['createdAt']),
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Boutons modifier / supprimer
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _edit(n),
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: Text('Modifier',
                          style: GoogleFonts.poppins(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _delete(n['_id']?.toString() ?? n['id']?.toString() ?? ''),
                      icon: const Icon(Icons.delete_outline_rounded, size: 14),
                      label: Text('Supprimer',
                          style: GoogleFonts.poppins(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(
                            color: Color(0xFFFEE2E2)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
                  color: active
                      ? const Color(0xFF1A1A2E)
                      : Colors.grey[500])),
        ),
      ),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  InputDecoration _inputDeco(String label, [IconData? icon]) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
      prefixIcon: icon != null
          ? Icon(icon, size: 18, color: Colors.grey[400])
          : null,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFA855F7), width: 2)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
