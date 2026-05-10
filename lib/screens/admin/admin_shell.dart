import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wejoy/screens/admin/admin_activities_screens.dart';
import 'package:wejoy/screens/service/admin_api_service.dart';
import 'dashboard_screen.dart';
import 'users_screen.dart';
import 'demandes_screen.dart';
import 'notifications_screen.dart';
import 'stats_screen.dart';

// ── Palette admin ─────────────────────────────────────────────────────────────
const _purple      = Color(0xFF6C3CE1);
const _purpleLight = Color(0xFF8B5CF6);
const _purpleDark  = Color(0xFF1E0A4A);
const _purpleMid   = Color(0xFF2D1060);
const _sidebarBg   = Color(0xFF1A0845);
const _bgPage      = Color(0xFFF4F6FA);
const _textGrey    = Color(0xFF9CA3AF);
const _textDark    = Color(0xFF1A1A2E);
const _cardBg      = Color(0xFFFFFFFF);
const _accent      = Color(0xFFE91E8C);

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  int _notifCount    = 3;
  bool _sidebarExpanded = true;

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_rounded,           label: 'Vue d\'ensemble'),
    _NavItem(icon: Icons.group_rounded,               label: 'Utilisateurs'),
    _NavItem(icon: Icons.chat_bubble_rounded,         label: 'Demandes'),
    _NavItem(icon: Icons.event_rounded,               label: 'Activités'),
    _NavItem(icon: Icons.notifications_rounded,       label: 'Notifications'),
    _NavItem(icon: Icons.show_chart_rounded,          label: 'Statistiques'),
    _NavItem(icon: Icons.settings_rounded,            label: 'Paramètres'),
    _NavItem(icon: Icons.assessment_rounded,          label: 'Rapports'),
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      const UsersScreen(),
      const DemandesScreen(),
      const AdminActivitiesScreen(),
      // Services supprimé
      NotificationsScreen(onAllRead: () => setState(() => _notifCount = 0)),
      const StatsScreen(),
      const Center(child: Text('Paramètres')),
      const Center(child: Text('Rapports')),
    ];
  }

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
                borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.logout_rounded,
                color: Colors.orange.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Text('Déconnexion',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: GoogleFonts.poppins(
              fontSize: 13, color: Colors.grey[700], height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: GoogleFonts.poppins(
                    color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Déconnecter',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final api = context.read<AdminApiService>();
    await api.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: Row(children: [
        // ── SIDEBAR ────────────────────────────────────────────────────────
        _buildSidebar(),
        // ── MAIN ───────────────────────────────────────────────────────────
        Expanded(
          child: Column(children: [
            _buildTopBar(),
            Expanded(child: _screens[_selectedIndex]),
          ]),
        ),
      ]),
    );
  }

  // ── SIDEBAR ───────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    final w = _sidebarExpanded ? 220.0 : 72.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: w,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_sidebarBg, _purpleDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(children: [
        // Logo
        Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Image.asset('assets/images/logowejoy.png',
                width: 38, height: 38, fit: BoxFit.contain),
            if (_sidebarExpanded) ...[
              const SizedBox(width: 10),
              Text('WEJOY',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: 1)),
            ],
            const Spacer(),
            GestureDetector(
              onTap: () =>
                  setState(() => _sidebarExpanded = !_sidebarExpanded),
              child: Icon(
                _sidebarExpanded
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: Colors.white54,
                size: 20,
              ),
            ),
          ]),
        ),

        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 12),

        // Nav items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              if (_sidebarExpanded)
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 8),
                  child: Text('MENU PRINCIPAL',
                      style: GoogleFonts.poppins(
                          color: Colors.white30,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                ),
              ...List.generate(6, (i) => _buildNavTile(i)),
              const SizedBox(height: 16),
              if (_sidebarExpanded)
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 8),
                  child: Text('CONFIGURATION',
                      style: GoogleFonts.poppins(
                          color: Colors.white30,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                ),
              _buildNavTile(6),
              _buildNavTile(7),
            ],
          ),
        ),

        // Plan premium
        if (_sidebarExpanded)
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7B2FBE), Color(0xFF6C3CE1)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFC857), size: 16),
                    const SizedBox(width: 6),
                    Text('Plan Premium',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                  Text('Votre plan est actif',
                      style: GoogleFonts.poppins(
                          color: Colors.white60, fontSize: 10)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _purple,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Gérer l\'abonnement',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
          ),

        // Aide
        if (_sidebarExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.help_outline_rounded,
                    color: Colors.white54, size: 16),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Besoin d\'aide ?',
                    style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                Text('Centre d\'aide',
                    style: GoogleFonts.poppins(
                        color: Colors.white30, fontSize: 10)),
              ]),
            ]),
          ),
      ]),
    );
  }

  Widget _buildNavTile(int i) {
    final sel = _selectedIndex == i;
    final item = _navItems[i];
    // Notifications est maintenant à l'index 4 (après suppression de Services)
    final hasBadge = i == 4 && _notifCount > 0;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 4),
        padding: EdgeInsets.symmetric(
            horizontal: _sidebarExpanded ? 14 : 0,
            vertical: 12),
        decoration: BoxDecoration(
          color: sel ? Colors.white.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: sel
              ? Border.all(color: Colors.white.withOpacity(0.08))
              : null,
        ),
        child: Row(
          mainAxisAlignment: _sidebarExpanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Stack(children: [
              Icon(item.icon,
                  size: 20,
                  color: sel ? Colors.white : Colors.white54),
              if (hasBadge)
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                        color: _accent, shape: BoxShape.circle),
                  ),
                ),
            ]),
            if (_sidebarExpanded) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(item.label,
                    style: GoogleFonts.poppins(
                        color: sel ? Colors.white : Colors.white60,
                        fontSize: 13,
                        fontWeight: sel
                            ? FontWeight.w700
                            : FontWeight.w400)),
              ),
              if (hasBadge)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('$_notifCount',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border(
            bottom: BorderSide(color: Colors.grey.shade100, width: 1.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        // Recherche
        Expanded(
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(children: [
              Icon(Icons.search_rounded,
                  color: Colors.grey.shade400, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    hintStyle: GoogleFonts.poppins(
                        color: Colors.grey.shade400, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: GoogleFonts.poppins(fontSize: 13, color: _textDark),
                ),
              ),
            ]),
          ),
        ),


        const SizedBox(width: 16),

        // Admin avatar + nom
        GestureDetector(
          onTap: _logout,
          child: Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundImage:
                  const AssetImage('assets/images/logowejoy.png'),
              backgroundColor: _purple.withOpacity(0.1),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Admin',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: _textDark)),
              Text('Administrateur',
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: _textGrey)),
            ]),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: _textGrey, size: 18),
          ]),
        ),
      ]),
    );
  }

  Widget _topBarBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, color: _textGrey, size: 20),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}