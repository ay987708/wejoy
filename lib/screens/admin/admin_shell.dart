import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wejoy/screens/admin/admin_activities_screens.dart';
import 'package:wejoy/screens/service/admin_api_service.dart';
import 'dashboard_screen.dart';
import 'users_screen.dart';
import 'services_screen.dart';
import 'demandes_screen.dart';
import 'notifications_screen.dart';
import 'stats_screen.dart';


class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.bar_chart_rounded,           label: 'Vue d\'ensemble'),
    _NavItem(icon: Icons.group_outlined,              label: 'Utilisateurs'),
    _NavItem(icon: Icons.calendar_today_outlined,     label: 'Services'),
    _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Demandes'),
    _NavItem(icon: Icons.notifications_outlined,      label: 'Notifications'),
    _NavItem(icon: Icons.show_chart_rounded,          label: 'Statistiques'),
    _NavItem(icon: Icons.event_rounded,               label: 'Activités'),
  ];

  final List<Widget> _screens = [
    const DashboardScreen(),
    const UsersScreen(),
    const ServicesScreen(),
    const DemandesScreen(),
    const NotificationsScreen(),
    const StatsScreen(),
    const AdminActivitiesScreen(),
  ];

  // ── Déconnexion avec confirmation ─────────────────────────────────────────
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.logout_rounded, color: Colors.orange.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Text('Déconnexion',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          'Voulez-vous vraiment vous déconnecter de l\'espace administrateur ?',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700], height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
              style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA855F7),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Déconnecter',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // ✅ await le logout + redirection
    final api = context.read<AdminApiService>();
    await api.logout();

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFFEC4899)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Espace Administrateur',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFA855F7))),
            Text('WelJoy',
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400])),
          ]),
        ]),
        actions: [
          // ✅ Bouton déconnexion qui appelle _logout()
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: Text('Déconnexion',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(_navItems.length, (i) {
                  final selected = i == _selectedIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.transparent,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        border: selected ? const Border(
                          top:   BorderSide(color: Color(0xFFE5E7EB)),
                          left:  BorderSide(color: Color(0xFFE5E7EB)),
                          right: BorderSide(color: Color(0xFFE5E7EB)),
                        ) : null,
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_navItems[i].icon, size: 18,
                          color: selected ? const Color(0xFF1A1A2E) : Colors.grey[500]),
                        const SizedBox(width: 8),
                        Text(_navItems[i].label,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? const Color(0xFF1A1A2E) : Colors.grey[500],
                          )),
                      ]),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}