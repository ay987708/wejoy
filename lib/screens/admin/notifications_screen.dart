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
  final _titreCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _notifs = await context.read<AdminApiService>().getNotifications();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _send() async {
    if (_titreCtrl.text.isEmpty || _messageCtrl.text.isEmpty) return;
    setState(() => _sending = true);
    await context.read<AdminApiService>().sendNotification({
      'titre': _titreCtrl.text,
      'message': _messageCtrl.text,
      'type': 'info',
    });
    _titreCtrl.clear();
    _messageCtrl.clear();
    setState(() => _sending = false);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notifications',
            style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
          Text('Envoyez des notifications à vos utilisateurs',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 28),
          // Send form
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Envoyer une notification',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                TextField(
                  controller: _titreCtrl,
                  decoration: _inputDeco('Titre de la notification'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageCtrl,
                  maxLines: 3,
                  decoration: _inputDeco('Message'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.notifications_outlined, size: 18),
                  label: Text('Envoyer à tous les utilisateurs',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Historique des notifications',
            style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            ..._notifs.map((n) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_outlined, color: Color(0xFFA855F7), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n['titre'] ?? '', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(n['message'] ?? '', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(n['date'] ?? '', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400])),
                      const SizedBox(height: 4),
                      Text('${n['envoyees']} destinataires',
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.poppins(fontSize: 13),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFA855F7), width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}