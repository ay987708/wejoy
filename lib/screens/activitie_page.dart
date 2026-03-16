import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const String _baseUrl = 'http://localhost:5000';
const Color _primary  = Color(0xFFD63FBF);
const Color _dark     = Color(0xFF9C27B0);
const Color _bg       = Color(0xFFF5F5F5);
const Color _navy     = Color(0xFF1A1A2E);

// ═══════════════════════════════════════════════════════════════════════════
// PAGE LISTE DES ACTIVITÉS
// ═══════════════════════════════════════════════════════════════════════════

class ActivitiePage extends StatefulWidget {
  const ActivitiePage({super.key});
  @override
  State<ActivitiePage> createState() => _ActivitiePageState();
}

class _ActivitiePageState extends State<ActivitiePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _activities = [];
  List<dynamic> _filtered   = [];
  bool   _loading           = true;
  String _search            = '';
  String _selectedCategory  = 'Tous';

  final List<String> _categories = [
    'Tous','Cuisine','Lecture','Jardinage','Yoga','Sport','Autre'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() { if (!_tabController.indexIsChanging) _applyFilter(); });
    _fetchActivities();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token'); // ✅ même clé que ApiService
  }

  Future<void> _fetchActivities() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$_baseUrl/api/activities'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        setState(() { _activities = jsonDecode(res.body); _applyFilter(); });
      }
    } catch (e) { debugPrint('❌ $e'); }
    finally { setState(() => _loading = false); }
  }

  void _applyFilter() {
    setState(() {
      var list = List<dynamic>.from(_activities);
      if (_tabController.index == 1) list = list.where((a) => a['isOfficial'] == true).toList();
      if (_tabController.index == 2) list = list.where((a) => a['isOfficial'] == false).toList();
      if (_selectedCategory != 'Tous') list = list.where((a) => a['category'] == _selectedCategory).toList();
      if (_search.isNotEmpty) list = list.where((a) => (a['title'] as String).toLowerCase().contains(_search.toLowerCase())).toList();
      _filtered = list;
    });
  }

  Future<void> _createActivity() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context, builder: (_) => const _CreateActivityDialog());
    if (result == null) return;
    try {
      final token = await _getToken();
      final res = await http.post(
        Uri.parse('$_baseUrl/api/activities'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(result),
      );
      if (res.statusCode == 201) {
        _fetchActivities();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Activité créée avec succès !'),
          ]),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) { debugPrint('❌ $e'); }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [

        // ── Bloc header blanc (titre + recherche + tabs) ─────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Column(children: [

            // Titre + bouton Créer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Découvrir les activités',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Rejoignez ou créez votre activité',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ])),
                ElevatedButton.icon(
                  onPressed: _createActivity,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Créer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary, foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ]),
            ),

            // Barre de recherche — même style que home
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: TextField(
                  onChanged: (v) { _search = v; _applyFilter(); },
                  decoration: InputDecoration(
                    hintText: 'Rechercher une activité...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Filtres catégories — pilules rose comme home
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat    = _categories[i];
                  final active = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () { setState(() => _selectedCategory = cat); _applyFilter(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? _primary.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? _primary : Colors.grey[300]!),
                      ),
                      child: Text(cat, style: TextStyle(
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? _primary : Colors.grey[600],
                      )),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Onglets — indicateur rose comme home
            TabBar(
              controller: _tabController,
              labelColor: _primary,
              unselectedLabelColor: Colors.grey[500],
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
              indicatorColor: _primary,
              indicatorWeight: 2.5,
              tabs: [
                Tab(text: 'Toutes (${_activities.length})'),
                Tab(text: 'Officielles (${_activities.where((a) => a['isOfficial'] == true).length})'),
                Tab(text: 'Communautaires (${_activities.where((a) => a['isOfficial'] == false).length})'),
              ],
            ),
          ]),
        ),

        // ── Grille ────────────────────────────────────────────────────────────
        Expanded(
          child: _loading
            ? Center(child: CircularProgressIndicator(color: _primary))
            : _filtered.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchActivities,
                  color: _primary,
                  backgroundColor: Colors.white,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 340,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _ActivityCard(
                      activity: _filtered[i],
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ActivityDetailPage(activityId: _filtered[i]['_id'].toString())));
                        _fetchActivities();
                      },
                    ),
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _buildEmptyState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
    const SizedBox(height: 12),
    Text('Aucune activité trouvée', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
  ]));
}

// ── Carte activité — style identique aux cartes home ──────────────────────────
class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final VoidCallback onTap;
  const _ActivityCard({required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOfficial = activity['isOfficial'] == true;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Image + badge
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: activity['imageUrl'] != null && activity['imageUrl'].toString().isNotEmpty
                ? Image.network(activity['imageUrl'], height: 130, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
            ),
            // Badge Officiel/Communautaire — fond sombre translucide comme home
            Positioned(top: 8, right: 8, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(isOfficial ? 'Officiel' : 'Communautaire',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            )),
          ]),

          // Contenu — même padding/style que les cartes home
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Badge catégorie rose comme home
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(activity['category'] ?? '',
                  style: const TextStyle(fontSize: 9, color: _primary, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),

              // Titre
              Text(activity['title'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),

              // Description
              Text(activity['description'] ?? '',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),

              // Membres + date — même style que home
              Row(children: [
                Icon(Icons.people_outline_rounded, size: 10, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('${activity['membersCount'] ?? 0} membres',
                  style: TextStyle(color: Colors.grey[500], fontSize: 9)),
                const Spacer(),
                if (activity['date'] != null) ...[
                  Icon(Icons.calendar_today_rounded, size: 10, color: Colors.grey[400]),
                  const SizedBox(width: 3),
                  Text(
                    activity['date'].toString().length > 10
                      ? activity['date'].toString().substring(0, 10)
                      : activity['date'].toString(),
                    style: TextStyle(color: Colors.grey[500], fontSize: 9)),
                ],
              ]),
              const SizedBox(height: 8),

              // Bouton — fond navy comme home
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0, minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text("Voir l'activité",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
    height: 130, width: double.infinity,
    color: _primary.withOpacity(0.08),
    child: const Center(child: Icon(Icons.image_rounded, color: _primary, size: 32)));
}

// ═══════════════════════════════════════════════════════════════════════════
// PAGE DÉTAIL ACTIVITÉ
// ═══════════════════════════════════════════════════════════════════════════

class ActivityDetailPage extends StatefulWidget {
  final String activityId;
  const ActivityDetailPage({super.key, required this.activityId});
  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _activity;
  bool  _loading  = true;
  bool  _isMember = false;
  final _chatCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _tabController = TabController(length: 3, vsync: this); _fetchDetail(); }
  @override
  void dispose() { _tabController.dispose(); _chatCtrl.dispose(); super.dispose(); }

  Future<String?> _getToken() async { final p = await SharedPreferences.getInstance(); return p.getString('auth_token'); }

  Future<void> _fetchDetail() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      final res = await http.get(Uri.parse('$_baseUrl/api/activities/${widget.activityId}'), headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) setState(() => _activity = jsonDecode(res.body));
    } catch (e) { debugPrint('❌ $e'); }
    finally { setState(() => _loading = false); }
  }

  Future<void> _toggleJoin() async {
    final token = await _getToken();
    final ep = _isMember ? 'leave' : 'join';
    final res = await http.post(Uri.parse('$_baseUrl/api/activities/${widget.activityId}/$ep'), headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode == 200 || res.statusCode == 201) { setState(() => _isMember = !_isMember); _fetchDetail(); }
  }

  Future<void> _sendMessage() async {
    final text = _chatCtrl.text.trim(); if (text.isEmpty) return;
    final token = await _getToken();
    await http.post(Uri.parse('$_baseUrl/api/activities/${widget.activityId}/chat'), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode({'text': text}));
    _chatCtrl.clear(); _fetchDetail();
  }

  Future<void> _addContent() async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => const _AddContentDialog());
    if (result == null) return;
    final token = await _getToken();
    await http.post(Uri.parse('$_baseUrl/api/activities/${widget.activityId}/content'), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode(result));
    _fetchDetail();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(backgroundColor: _bg, body: Center(child: CircularProgressIndicator(color: _primary)));
    if (_activity == null) return const Scaffold(body: Center(child: Text('Activité introuvable')));

    final a        = _activity!;
    final members  = List<dynamic>.from(a['members']  ?? []);
    final content  = List<dynamic>.from(a['content']  ?? []);
    final chat     = List<dynamic>.from(a['chat']     ?? []);
    final official = a['isOfficial'] == true;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(slivers: [

        // ── SliverAppBar hero — dégradé rose/violet comme home ──────────────
        SliverAppBar(
          expandedHeight: 240, pinned: true,
          backgroundColor: _dark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context)),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              // Image ou dégradé
              a['imageUrl'] != null && a['imageUrl'].toString().isNotEmpty
                ? Image.network(a['imageUrl'], fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [_primary, _dark], begin: Alignment.topLeft, end: Alignment.bottomRight))))
                : Container(decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [_primary, _dark], begin: Alignment.topLeft, end: Alignment.bottomRight))),
              // Overlay sombre bas
              Container(decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.75)]))),
              // Titre + description
              Positioned(bottom: 16, left: 16, right: 120, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Badge catégorie — rose comme home
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _primary.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                    child: Text(a['category'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
                  Text(a['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  if (a['description'] != null)
                    Text(a['description'], style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                ])),
              // Badge Officiel / Communautaire
              Positioned(bottom: 16, right: 16, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
                child: Text(official ? 'Officiel' : 'Communautaire',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)))),
            ]),
          ),
          // Bouton Rejoindre/Quitter dans l'AppBar
          actions: [
            Padding(padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              child: ElevatedButton.icon(
                onPressed: _toggleJoin,
                icon: Icon(_isMember ? Icons.person_remove_outlined : Icons.person_add_outlined, size: 15),
                label: Text(_isMember ? 'Quitter' : 'Rejoindre', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isMember ? Colors.white.withOpacity(0.25) : _primary,
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
              )),
          ],
        ),

        // ── Chips infos rapides — style pilule rose home ─────────────────────
        SliverToBoxAdapter(child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Wrap(spacing: 8, children: [
            _infoChip(Icons.people_outline_rounded, '${members.length} membres'),
            if (a['date']     != null) _infoChip(Icons.calendar_today_rounded, a['date']),
            if (a['timeSlot'] != null) _infoChip(Icons.access_time_rounded,    a['timeSlot']),
          ]),
        )),

        // ── TabBar — indicateur rose comme home ──────────────────────────────
        SliverToBoxAdapter(child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: _primary,
            unselectedLabelColor: Colors.grey[500],
            indicatorColor: _primary,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
            tabs: [
              Tab(text: 'Contenu (${content.length})'),
              Tab(text: 'Membres (${members.length})'),
              Tab(text: 'Chat (${chat.length})'),
            ],
          ),
        )),

        SliverFillRemaining(child: TabBarView(controller: _tabController, children: [
          _ContentTab(content: content, onAdd: _addContent),
          _MembersTab(members: members),
          _ChatTab(chat: chat, controller: _chatCtrl, onSend: _sendMessage),
        ])),
      ]),
    );
  }

  Widget _infoChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: _primary.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: _primary),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.w500)),
    ]),
  );
}

// ── Onglet Contenu ─────────────────────────────────────────────────────────────
class _ContentTab extends StatelessWidget {
  final List<dynamic> content;
  final VoidCallback onAdd;
  const _ContentTab({required this.content, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(color: _bg, child: Column(children: [
      // Bouton partager
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Align(alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Partager du contenu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary, foregroundColor: Colors.white,
            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ))),
      Expanded(child: content.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.article_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Aucun contenu partagé', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          ]))
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: content.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ContentCard(item: content[i]),
          )),
    ]));
  }
}

class _ContentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ContentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Avatar — couleur rose comme home
          CircleAvatar(radius: 18, backgroundColor: _primary.withOpacity(0.15),
            child: Text((item['username'] ?? 'U')[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, color: _primary, fontSize: 14))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(_formatDate(item['createdAt']), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ])),
          // Badge type — rose comme home
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(item['type'] ?? '', style: const TextStyle(fontSize: 11, color: _primary, fontWeight: FontWeight.w500))),
        ]),
        const SizedBox(height: 12),
        Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 6),
        Text(item['body']  ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
        const SizedBox(height: 12),
        Row(children: [
          Icon(Icons.favorite_border, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text('${item['likes'] ?? 0}', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(width: 16),
          Icon(Icons.comment_outlined, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text('${item['comments'] ?? 0}', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ]),
      ]),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try { final d = DateTime.parse(date.toString()); return '${d.day} ${_months[d.month - 1]} à ${d.hour}h${d.minute.toString().padLeft(2, '0')}'; }
    catch (_) { return ''; }
  }
  static const _months = ['janv.','févr.','mars','avr.','mai','juin','juil.','août','sept.','oct.','nov.','déc.'];
}

// ── Onglet Membres ─────────────────────────────────────────────────────────────
class _MembersTab extends StatelessWidget {
  final List<dynamic> members;
  const _MembersTab({required this.members});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey[300]),
      const SizedBox(height: 12),
      Text('Aucun membre pour le moment', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
    ]));
    return Container(color: _bg, child: ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = members[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            // Avatar rose comme home
            CircleAvatar(radius: 20, backgroundColor: _primary.withOpacity(0.15),
              child: Text((m['username'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: _primary, fontSize: 16))),
            const SizedBox(width: 12),
            Text(m['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ]),
        );
      },
    ));
  }
}

// ── Onglet Chat ─────────────────────────────────────────────────────────────────
class _ChatTab extends StatelessWidget {
  final List<dynamic> chat;
  final TextEditingController controller;
  final VoidCallback onSend;
  const _ChatTab({required this.chat, required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(color: _bg, child: Column(children: [
      Expanded(child: chat.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Aucun message pour le moment', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          ]))
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chat.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final m = chat[i];
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(radius: 16, backgroundColor: _primary.withOpacity(0.15),
                  child: Text((m['username'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primary))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(m['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(_formatDate(m['createdAt']), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ]),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
                    ),
                    child: Text(m['text'] ?? '', style: const TextStyle(fontSize: 13))),
                ])),
              ]);
            },
          )),

      // Champ de saisie — même style que home
      Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: Row(children: [
          Expanded(child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Écrivez votre message...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              filled: true, fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
          )),
          const SizedBox(width: 8),
          // Bouton envoi — rose comme home
          IconButton(
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded),
            style: IconButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
          ),
        ]),
      ),
    ]));
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try { final d = DateTime.parse(date.toString()); return '${d.day} ${_months[d.month - 1]} à ${d.hour}h${d.minute.toString().padLeft(2, '0')}'; }
    catch (_) { return ''; }
  }
  static const _months = ['janv.','févr.','mars','avr.','mai','juin','juil.','août','sept.','oct.','nov.','déc.'];
}

// ═══════════════════════════════════════════════════════════════════════════
// DIALOG CRÉER ACTIVITÉ — style home
// ═══════════════════════════════════════════════════════════════════════════

class _CreateActivityDialog extends StatefulWidget {
  const _CreateActivityDialog();
  @override
  State<_CreateActivityDialog> createState() => _CreateActivityDialogState();
}

class _CreateActivityDialogState extends State<_CreateActivityDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _dateCtrl  = TextEditingController();
  final _timeCtrl  = TextEditingController();
  final _maxCtrl   = TextEditingController();
  String _category = 'Cuisine';
  String _type     = 'collective';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // En-tête avec icône dégradé rose
          Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [_primary, _dark]), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            const Text('Créer une activité', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 20),
          _field('Titre de l\'activité', _titleCtrl),
          const SizedBox(height: 12),
          _field('Description', _descCtrl, maxLines: 3),
          const SizedBox(height: 12),
          _field('URL de l\'image (optionnel)', _imageCtrl),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: _category, decoration: _inputDeco('Catégorie'),
            items: ['Cuisine','Lecture','Jardinage','Yoga','Sport','Autre'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v!)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: _type, decoration: _inputDeco('Type'),
            items: const [DropdownMenuItem(value: 'collective', child: Text('Collectif')), DropdownMenuItem(value: 'individual', child: Text('Individuel'))],
            onChanged: (v) => setState(() => _type = v!)),
          const SizedBox(height: 12),
          _field('Date (ex: 2026-03-20)', _dateCtrl),
          const SizedBox(height: 12),
          _field('Horaire (ex: 14h00 - 16h00)', _timeCtrl),
          const SizedBox(height: 12),
          _field('Participants max', _maxCtrl, type: TextInputType.number),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(foregroundColor: _primary, side: const BorderSide(color: _primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Annuler'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () {
                if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty) return;
                Navigator.pop(context, {
                  'title': _titleCtrl.text.trim(), 'description': _descCtrl.text.trim(),
                  'imageUrl': _imageCtrl.text.trim(), 'category': _category, 'type': _type,
                  'date': _dateCtrl.text.trim().isNotEmpty ? _dateCtrl.text.trim() : null,
                  'timeSlot': _timeCtrl.text.trim().isNotEmpty ? _timeCtrl.text.trim() : null,
                  'maxParticipants': _maxCtrl.text.trim().isNotEmpty ? int.tryParse(_maxCtrl.text.trim()) : null,
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Créer'))),
          ]),
        ])),
    );
  }

  Widget _field(String hint, TextEditingController ctrl, {int maxLines = 1, TextInputType type = TextInputType.text}) =>
    TextField(controller: ctrl, maxLines: maxLines, keyboardType: type, decoration: _inputDeco(hint));

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
    filled: true, fillColor: Colors.grey[50],
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: _primary, width: 2)),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// DIALOG AJOUTER CONTENU — style home
// ═══════════════════════════════════════════════════════════════════════════

class _AddContentDialog extends StatefulWidget {
  const _AddContentDialog();
  @override
  State<_AddContentDialog> createState() => _AddContentDialogState();
}

class _AddContentDialogState extends State<_AddContentDialog> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  String _type = 'Recette';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [_primary, _dark]), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            const Text('Partager du contenu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 20),
          TextField(controller: _titleCtrl, decoration: _inputDeco('Titre')),
          const SizedBox(height: 12),
          TextField(controller: _bodyCtrl, maxLines: 5, decoration: _inputDeco('Contenu...')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: _type, decoration: _inputDeco('Type'),
            items: ['Recette','Article','Conseil','Autre'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _type = v!)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(foregroundColor: _primary, side: const BorderSide(color: _primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Annuler'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () { if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) return; Navigator.pop(context, {'title': _titleCtrl.text.trim(), 'body': _bodyCtrl.text.trim(), 'type': _type}); },
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Publier'))),
          ]),
        ])),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
    filled: true, fillColor: Colors.grey[50],
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: _primary, width: 2)),
  );
}