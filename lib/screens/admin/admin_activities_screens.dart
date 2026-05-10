import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const String _baseUrl = 'http://10.0.2.2:5000';

// ════════════════════════════════════════════════════════════════════════════
// ADMIN ACTIVITIES SCREEN
// ════════════════════════════════════════════════════════════════════════════

class AdminActivitiesScreen extends StatefulWidget {
  const AdminActivitiesScreen({super.key});
  @override
  State<AdminActivitiesScreen> createState() => _AdminActivitiesScreenState();
}

class _AdminActivitiesScreenState extends State<AdminActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _activities = [];
  List<dynamic> _filtered   = [];
  bool   _loading           = true;
  String _search            = '';
  String _selectedCategory  = 'Tous';

  final List<String> _categories = [
    'Tous', 'Cuisine', 'Lecture', 'Jardinage', 'Yoga', 'Sport', 'Autre'
  ];

  static const Color _accent   = Color(0xFFA855F7);
  static const Color _accentPk = Color(0xFFEC4899);
  static const Color _bg       = Color(0xFFF8F8FB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _applyFilter();
    });
    _fetchActivities();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<String?> _getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> _fetchActivities() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      if (token == null) { setState(() => _loading = false); return; }
      final res = await http.get(
        Uri.parse('$_baseUrl/api/activities'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() { _activities = data; _applyFilter(); });
      }
    } catch (e) { debugPrint('❌ $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _createActivity(Map<String, dynamic> body) async {
    try {
      final token = await _getToken();
      final res = await http.post(
        Uri.parse('$_baseUrl/api/activities'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 201) {
        _fetchActivities();
        if (mounted) _showSnack('Activité créée avec succès ✅', _accent, Icons.check_circle_rounded);
      } else {
        if (mounted) _showSnack('Erreur création: ${res.statusCode}', Colors.red, Icons.error_outline);
      }
    } catch (e) {
      if (mounted) _showSnack('Erreur réseau', Colors.red, Icons.wifi_off_rounded);
    }
  }

  Future<void> _deleteActivity(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Supprimer l\'activité',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: RichText(text: TextSpan(
          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
          children: [
            const TextSpan(text: 'Êtes-vous sûr de vouloir supprimer '),
            TextSpan(text: '"$title"',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            const TextSpan(text: ' ?\n\nCette action est '),
            TextSpan(text: 'irréversible',
              style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w600)),
            const TextSpan(text: '.'),
          ],
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final token = await _getToken();
      final res = await http.delete(
        Uri.parse('$_baseUrl/api/activities/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        _fetchActivities();
        if (mounted) _showSnack('Activité supprimée', Colors.green, Icons.check_circle_rounded);
      } else {
        if (mounted) _showSnack('Erreur lors de la suppression', Colors.red, Icons.error_outline);
      }
    } catch (e) {
      if (mounted) _showSnack('Erreur réseau', Colors.red, Icons.wifi_off_rounded);
    }
  }

  Future<void> _editActivity(Map<String, dynamic> activity) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EditActivityDialog(activity: activity),
    );
    if (result == null) return;
    try {
      final token = await _getToken();
      final res = await http.put(
        Uri.parse('$_baseUrl/api/activities/${activity['_id']}'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(result),
      );
      if (res.statusCode == 200) {
        _fetchActivities();
        if (mounted) _showSnack('Activité modifiée avec succès', Colors.green, Icons.check_circle_rounded);
      } else {
        if (mounted) _showSnack('Erreur lors de la modification', Colors.red, Icons.error_outline);
      }
    } catch (e) {
      if (mounted) _showSnack('Erreur réseau', Colors.red, Icons.wifi_off_rounded);
    }
  }

  Future<void> _toggleOfficial(Map<String, dynamic> activity) async {
    final newValue = !(activity['isOfficial'] == true);
    try {
      final token = await _getToken();
      await http.put(
        Uri.parse('$_baseUrl/api/activities/${activity['_id']}'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'isOfficial': newValue}),
      );
      _fetchActivities();
      if (mounted) _showSnack(
        newValue ? 'Activité marquée Officielle' : 'Activité marquée Communautaire',
        _accent, Icons.verified_outlined,
      );
    } catch (e) { debugPrint('❌ $e'); }
  }

  Future<void> _showCreateDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _CreateActivityDialog(),
    );
    if (result == null) return;
    await _createActivity(result);
  }

  void _applyFilter() {
    setState(() {
      var list = List<dynamic>.from(_activities);
      if (_tabController.index == 1) list = list.where((a) => a['isOfficial'] == true).toList();
      if (_tabController.index == 2) list = list.where((a) => a['isOfficial'] == false).toList();
      if (_selectedCategory != 'Tous') list = list.where((a) => a['category'] == _selectedCategory).toList();
      if (_search.isNotEmpty) list = list.where((a) =>
        (a['title'] as String? ?? '').toLowerCase().contains(_search.toLowerCase()) ||
        (a['description'] as String? ?? '').toLowerCase().contains(_search.toLowerCase())
      ).toList();
      _filtered = list;
    });
  }

  void _showSnack(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg, style: GoogleFonts.poppins()),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final officielCount  = _activities.where((a) => a['isOfficial'] == true).length;
    final communautCount = _activities.where((a) => a['isOfficial'] == false).length;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [

        // ── En-tête ──────────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Titre + bouton créer
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Gestion des Activités',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
                Text('Gérez, modifiez et supprimez les activités de la plateforme',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
              ])),
              ElevatedButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('Créer une activité',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // 3 cartes stats
            Row(children: [
              _StatMini(label: 'Total',          value: '${_activities.length}', color: _accent,                 icon: Icons.event_rounded),
              const SizedBox(width: 12),
              _StatMini(label: 'Officielles',    value: '$officielCount',        color: const Color(0xFF22C55E), icon: Icons.verified_rounded),
              const SizedBox(width: 12),
              _StatMini(label: 'Communautaires', value: '$communautCount',       color: _accentPk,               icon: Icons.people_rounded),
            ]),
            const SizedBox(height: 16),

            // Barre de recherche
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                onChanged: (v) { _search = v; _applyFilter(); },
                decoration: InputDecoration(
                  hintText: 'Rechercher par titre ou description...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filtres catégories
            SizedBox(height: 34, child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat    = _categories[i];
                final active = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () { setState(() => _selectedCategory = cat); _applyFilter(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? _accent.withOpacity(0.1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? _accent : Colors.grey.shade300),
                    ),
                    child: Text(cat, style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? _accent : Colors.grey[600],
                    )),
                  ),
                );
              },
            )),
            const SizedBox(height: 12),

            // Onglets
            TabBar(
              controller: _tabController,
              labelColor: _accent,
              unselectedLabelColor: Colors.grey[500],
              indicatorColor: _accent,
              indicatorWeight: 2.5,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 13),
              tabs: [
                Tab(text: 'Toutes (${_activities.length})'),
                Tab(text: 'Officielles ($officielCount)'),
                Tab(text: 'Communautaires ($communautCount)'),
              ],
            ),
          ]),
        ),

        // ── Liste ────────────────────────────────────────────────────────────
        Expanded(
          child: _loading
            ? Center(child: CircularProgressIndicator(color: _accent))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildList(_filtered),
                  _buildList(_filtered.where((a) => a['isOfficial'] == true).toList()),
                  _buildList(_filtered.where((a) => a['isOfficial'] == false).toList()),
                ],
              ),
        ),
      ]),
    );
  }

  Widget _buildList(List<dynamic> items) {
    if (items.isEmpty) return _buildEmpty();
    return RefreshIndicator(
      onRefresh: _fetchActivities,
      color: _accent,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _ActivityAdminCard(
          activity: items[i],
          onEdit:           () => _editActivity(items[i]),
          onDelete:         () => _deleteActivity(items[i]['_id'].toString(), items[i]['title'] ?? ''),
          onToggleOfficial: () => _toggleOfficial(items[i]),
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.event_busy_rounded, size: 56, color: Colors.grey[300]),
    const SizedBox(height: 12),
    Text('Aucune activité trouvée',
      style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 15)),
    const SizedBox(height: 8),
    Text('Cliquez sur "Créer une activité" pour commencer',
      style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12)),
  ]));
}

// ════════════════════════════════════════════════════════════════════════════
// CARTE ACTIVITÉ ADMIN
// ════════════════════════════════════════════════════════════════════════════

class _ActivityAdminCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleOfficial;

  static const Color _accent   = Color(0xFFA855F7);
  static const Color _accentPk = Color(0xFFEC4899);

  const _ActivityAdminCard({
    required this.activity,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleOfficial,
  });

  @override
  Widget build(BuildContext context) {
    final isOfficial = activity['isOfficial'] == true;
    final members    = activity['membersCount'] ?? 0;
    final category   = activity['category'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Contenu principal ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Miniature
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: activity['imageUrl'] != null && activity['imageUrl'].toString().isNotEmpty
                ? Image.network(activity['imageUrl'], width: 72, height: 72, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgPlaceholder())
                : _imgPlaceholder(),
            ),
            const SizedBox(width: 14),

            // Infos
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Titre + badge
              Row(children: [
                Expanded(child: Text(activity['title'] ?? '',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onToggleOfficial,
                  child: Tooltip(
                    message: isOfficial
                      ? 'Cliquer pour rendre Communautaire'
                      : 'Cliquer pour rendre Officielle',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOfficial
                          ? const Color(0xFF22C55E).withOpacity(0.12)
                          : _accentPk.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOfficial ? const Color(0xFF22C55E) : _accentPk, width: 1),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(isOfficial ? Icons.verified_rounded : Icons.people_rounded,
                          size: 12,
                          color: isOfficial ? const Color(0xFF22C55E) : _accentPk),
                        const SizedBox(width: 4),
                        Text(isOfficial ? 'Officielle' : 'Communautaire',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                            color: isOfficial ? const Color(0xFF22C55E) : _accentPk)),
                      ]),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 4),

              // Description
              Text(activity['description'] ?? '',
                style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),

              // Métadonnées
              Wrap(spacing: 12, runSpacing: 4, children: [
                _meta(Icons.label_outline_rounded, category, _accent),
                _meta(Icons.people_outline_rounded, '$members membres', Colors.grey),
                if (activity['date'] != null)
                  _meta(Icons.calendar_today_rounded, _shortDate(activity['date']), Colors.grey),
                if (activity['timeSlot'] != null)
                  _meta(Icons.access_time_rounded, activity['timeSlot'], Colors.grey),
                if (activity['location'] != null)
                  _meta(Icons.location_on_outlined, activity['location'], Colors.grey),
                if (activity['createdBy'] != null)
                  _meta(Icons.person_outline_rounded,
                    'Par ${activity['createdBy']['username'] ?? 'inconnu'}', _accentPk),
              ]),
            ])),
          ]),
        ),

        // ── Barre d'actions ──────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            border: Border(top: BorderSide(color: Colors.grey.shade100)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text('${(activity['chat'] as List?)?.length ?? 0} msgs',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(width: 12),
            Icon(Icons.article_outlined, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text('${(activity['content'] as List?)?.length ?? 0} posts',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const Spacer(),
            _ActionBtn(
              label: isOfficial ? 'Communautaire' : 'Officielle',
              icon:  isOfficial ? Icons.people_rounded : Icons.verified_rounded,
              color: isOfficial ? _accentPk : const Color(0xFF22C55E),
              onTap: onToggleOfficial,
            ),
            const SizedBox(width: 8),
            _ActionBtn(label: 'Modifier',  icon: Icons.edit_outlined,         color: _accent,    onTap: onEdit),
            const SizedBox(width: 8),
            _ActionBtn(label: 'Supprimer', icon: Icons.delete_outline_rounded, color: Colors.red, onTap: onDelete),
          ]),
        ),
      ]),
    );
  }

  Widget _imgPlaceholder() => Container(
    width: 72, height: 72,
    decoration: BoxDecoration(
      color: _accent.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10)),
    child: const Icon(Icons.image_rounded, color: _accent, size: 28),
  );

  Widget _meta(IconData icon, String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ],
  );

  String _shortDate(dynamic d) {
    try {
      final dt = DateTime.parse(d.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return d.toString().length > 10 ? d.toString().substring(0, 10) : d.toString();
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BOUTON ACTION COMPACT
// ════════════════════════════════════════════════════════════════════════════

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// STAT MINI CARD
// ════════════════════════════════════════════════════════════════════════════

class _StatMini extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _StatMini({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18, color: color)),
        Text(label,  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
      ]),
    ]),
  ));
}

// ════════════════════════════════════════════════════════════════════════════
// DIALOG CRÉER ACTIVITÉ
// ════════════════════════════════════════════════════════════════════════════

class _CreateActivityDialog extends StatefulWidget {
  const _CreateActivityDialog();
  @override
  State<_CreateActivityDialog> createState() => _CreateActivityDialogState();
}

class _CreateActivityDialogState extends State<_CreateActivityDialog> {
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _imageCtrl    = TextEditingController();
  final _dateCtrl     = TextEditingController();
  final _timeCtrl     = TextEditingController();
  final _maxCtrl      = TextEditingController();
  final _locationCtrl = TextEditingController();

  String _category = 'Yoga';
  String _type     = 'individual';
  bool   _isDaily  = false;

  static const Color _accent = Color(0xFFA855F7);

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _imageCtrl.dispose();
    _dateCtrl.dispose();  _timeCtrl.dispose(); _maxCtrl.dispose();
    _locationCtrl.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

            // En-tête
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFFEC4899)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Créer une activité',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('L\'activité sera visible par tous les utilisateurs',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
              ])),
              IconButton(
                icon: Icon(Icons.close, color: Colors.grey[400]),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            const SizedBox(height: 20),

            _label('Titre *'),
            _field(_titleCtrl, 'Titre de l\'activité'),
            const SizedBox(height: 12),

            _label('Description *'),
            _field(_descCtrl, 'Description...', maxLines: 3),
            const SizedBox(height: 12),

            _label('URL de l\'image'),
            _field(_imageCtrl, 'https://images.unsplash.com/...'),
            const SizedBox(height: 12),

            // Catégorie + Type
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Catégorie'),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: _inputDeco('Catégorie'),
                  items: ['Yoga', 'Cuisine', 'Lecture', 'Jardinage', 'Sport', 'Autre']
                    .map((c) => DropdownMenuItem(value: c,
                      child: Text(c, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ])),
            ]),
            const SizedBox(height: 12),

            // Toggle quotidienne
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isDaily ? _accent.withOpacity(0.05) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDaily ? _accent.withOpacity(0.3) : Colors.grey.shade200),
              ),
              child: Row(children: [
                Icon(Icons.repeat_rounded, size: 18,
                  color: _isDaily ? _accent : Colors.grey[500]),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Activité quotidienne',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600,
                      color: _isDaily ? _accent : Colors.grey[700])),
                  Text(_isDaily ? 'Apparaît chaque jour dans l\'app' : 'Activité ponctuelle',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                ])),
                Switch(
                  value: _isDaily,
                  onChanged: (v) => setState(() => _isDaily = v),
                  activeColor: _accent,
                ),
              ]),
            ),
            const SizedBox(height: 12),

            _label('Date'),
            _field(_dateCtrl, 'ex: 2026-03-20'),
            const SizedBox(height: 12),

            _label('Horaire'),
            _field(_timeCtrl, 'ex: 14h00 - 16h00'),
            const SizedBox(height: 12),

            _label('Participants max'),
            _field(_maxCtrl, 'ex: 20', type: TextInputType.number),
            const SizedBox(height: 12),

            _label('Lieu'),
            _field(_locationCtrl, 'ex: Salle communautaire'),
            const SizedBox(height: 24),

            // Boutons
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text('Annuler', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () {
                  if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) return;
                  Navigator.pop(context, {
                    'title':           _titleCtrl.text.trim(),
                    'description':     _descCtrl.text.trim(),
                    'imageUrl':        _imageCtrl.text.trim(),
                    'category':        _category,
                    'isDaily':         _isDaily,
                    'isOfficial':      true,
                    'date':            _dateCtrl.text.trim().isNotEmpty ? _dateCtrl.text.trim() : null,
                    'timeSlot':        _timeCtrl.text.trim().isNotEmpty ? _timeCtrl.text.trim() : null,
                    'maxParticipants': _maxCtrl.text.trim().isNotEmpty ? int.tryParse(_maxCtrl.text.trim()) : null,
                    'location':        _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.trim() : null,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent, foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text('Créer l\'activité',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: GoogleFonts.poppins(
      fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])));

  Widget _field(TextEditingController ctrl, String hint,
      {int maxLines = 1, TextInputType type = TextInputType.text}) =>
    TextField(controller: ctrl, maxLines: maxLines, keyboardType: type,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: _inputDeco(hint));

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
    filled: true, fillColor: Colors.grey[50],
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFA855F7), width: 2)),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// DIALOG MODIFIER ACTIVITÉ
// ════════════════════════════════════════════════════════════════════════════

class _EditActivityDialog extends StatefulWidget {
  final Map<String, dynamic> activity;
  const _EditActivityDialog({required this.activity});
  @override
  State<_EditActivityDialog> createState() => _EditActivityDialogState();
}

class _EditActivityDialogState extends State<_EditActivityDialog> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _imageCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _maxCtrl;
  late TextEditingController _locationCtrl;
  late String _category;
  late bool   _isOfficial;

  static const Color _accent = Color(0xFFA855F7);

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    _titleCtrl    = TextEditingController(text: a['title']           ?? '');
    _descCtrl     = TextEditingController(text: a['description']     ?? '');
    _imageCtrl    = TextEditingController(text: a['imageUrl']        ?? '');
    _dateCtrl     = TextEditingController(text: a['date']            ?? '');
    _timeCtrl     = TextEditingController(text: a['timeSlot']        ?? '');
    _maxCtrl      = TextEditingController(text: a['maxParticipants']?.toString() ?? '');
    _locationCtrl = TextEditingController(text: a['location']        ?? '');
    _category     = a['category']   ?? 'Yoga';
    _isOfficial   = a['isOfficial'] == true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _imageCtrl.dispose();
    _dateCtrl.dispose();  _timeCtrl.dispose(); _maxCtrl.dispose();
    _locationCtrl.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

            // En-tête
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFFEC4899)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Modifier l\'activité',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Les modifications s\'appliquent immédiatement',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
              ])),
              IconButton(
                icon: Icon(Icons.close, color: Colors.grey[400]),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            const SizedBox(height: 20),

            _label('Titre *'),
            _field(_titleCtrl, 'Titre de l\'activité'),
            const SizedBox(height: 12),

            _label('Description *'),
            _field(_descCtrl, 'Description...', maxLines: 3),
            const SizedBox(height: 12),

            _label('URL de l\'image'),
            _field(_imageCtrl, 'https://...'),
            const SizedBox(height: 12),

            _label('Catégorie'),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: _inputDeco('Catégorie'),
              items: ['Yoga', 'Cuisine', 'Lecture', 'Jardinage', 'Sport', 'Autre']
                .map((c) => DropdownMenuItem(value: c,
                  child: Text(c, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),

            _label('Date'),
            _field(_dateCtrl, 'ex: 2026-03-20'),
            const SizedBox(height: 12),

            _label('Horaire'),
            _field(_timeCtrl, 'ex: 14h00 - 16h00'),
            const SizedBox(height: 12),

            _label('Participants max'),
            _field(_maxCtrl, 'ex: 20', type: TextInputType.number),
            const SizedBox(height: 12),

            _label('Lieu'),
            _field(_locationCtrl, 'ex: Salle communautaire'),
            const SizedBox(height: 16),

            // Toggle Officielle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isOfficial ? const Color(0xFF22C55E).withOpacity(0.07) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isOfficial
                    ? const Color(0xFF22C55E).withOpacity(0.4)
                    : Colors.grey.shade200),
              ),
              child: Row(children: [
                Icon(_isOfficial ? Icons.verified_rounded : Icons.people_rounded,
                  color: _isOfficial ? const Color(0xFF22C55E) : Colors.grey[500], size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Activité officielle',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(_isOfficial
                    ? 'Visible comme activité vérifiée WeJoy'
                    : 'Activité créée par la communauté',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                ])),
                Switch(
                  value: _isOfficial,
                  onChanged: (v) => setState(() => _isOfficial = v),
                  activeColor: const Color(0xFF22C55E),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // Boutons
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text('Annuler', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () {
                  if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) return;
                  Navigator.pop(context, {
                    'title':           _titleCtrl.text.trim(),
                    'description':     _descCtrl.text.trim(),
                    'imageUrl':        _imageCtrl.text.trim(),
                    'category':        _category,
                    'isOfficial':      _isOfficial,
                    'date':            _dateCtrl.text.trim().isNotEmpty ? _dateCtrl.text.trim() : null,
                    'timeSlot':        _timeCtrl.text.trim().isNotEmpty ? _timeCtrl.text.trim() : null,
                    'maxParticipants': _maxCtrl.text.trim().isNotEmpty ? int.tryParse(_maxCtrl.text.trim()) : null,
                    'location':        _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.trim() : null,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent, foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text('Enregistrer',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: GoogleFonts.poppins(
      fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])));

  Widget _field(TextEditingController ctrl, String hint,
      {int maxLines = 1, TextInputType type = TextInputType.text}) =>
    TextField(controller: ctrl, maxLines: maxLines, keyboardType: type,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: _inputDeco(hint));

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
    filled: true, fillColor: Colors.grey[50],
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFA855F7), width: 2)),
  );
}