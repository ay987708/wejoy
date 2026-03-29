import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wejoy/chat_tab.dart';
import 'dart:convert';


const String _baseUrl = 'http://localhost:5001';
const Color _rose   = Color(0xFFD63FBF);
const Color _violet = Color(0xFF7C3AED);
const Color _ink    = Color(0xFF0F0F1A);
const Color _slate  = Color(0xFF64748B);
const Color _snow   = Color(0xFFF8FAFC);
const Color _border = Color(0xFFEEEEF5);

// ═══════════════════════════════════════════════════════════════════════════
// PAGE LISTE
// ═══════════════════════════════════════════════════════════════════════════
class ActivitiePage extends StatefulWidget {
  const ActivitiePage({super.key});
  @override
  State<ActivitiePage> createState() => _ActivitiePageState();
}

class _ActivitiePageState extends State<ActivitiePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _activities = [];
  List<dynamic> _filtered   = [];
  bool   _loading           = true;
  String _search            = '';
  String _selCat            = 'Tous';
  final _cats = ['Tous','Cuisine','Lecture','Jardinage','Yoga','Sport','Autre'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() { if (!_tabController.indexIsChanging) _filter(); });
    _fetch();
  }
  @override void dispose() { _tabController.dispose(); super.dispose(); }

  Future<String?> _tok() async { final p = await SharedPreferences.getInstance(); return p.getString('auth_token'); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/activities'),
        headers: {'Authorization': 'Bearer ${await _tok()}'});
      if (res.statusCode == 200) setState(() { _activities = jsonDecode(res.body); _filter(); });
    } catch (e) { debugPrint('$e'); }
    finally { setState(() => _loading = false); }
  }

  void _filter() {
    setState(() {
      var l = List<dynamic>.from(_activities);
      if (_tabController.index == 1) l = l.where((a) => a['isOfficial'] == true).toList();
      if (_tabController.index == 2) l = l.where((a) => a['isOfficial'] == false).toList();
      if (_selCat != 'Tous') l = l.where((a) => a['category'] == _selCat).toList();
      if (_search.isNotEmpty) l = l.where((a) => (a['title'] as String).toLowerCase().contains(_search.toLowerCase())).toList();
      _filtered = l;
    });
  }

  Future<void> _createActivity() async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => const _CreateDialog());
    if (result == null) return;
    final res = await http.post(Uri.parse('$_baseUrl/api/activities'),
      headers: {'Authorization': 'Bearer ${await _tok()}', 'Content-Type': 'application/json'},
      body: jsonEncode(result));
    if (res.statusCode == 201 && mounted) {
      _fetch();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Activité créée ! ✅'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _snow,
      body: Column(children: [
        // ── Header ────────────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Découvrir les activités',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _ink)),
                  Text('Rejoignez ou créez votre activité',
                    style: TextStyle(fontSize: 13, color: _slate.withOpacity(0.7))),
                ])),
                GestureDetector(
                  onTap: _createActivity,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_rose, _violet]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Créer', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
            ),
            // Recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(color: _snow, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                child: TextField(
                  onChanged: (v) { _search = v; _filter(); },
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une activité...',
                    hintStyle: TextStyle(color: _slate.withOpacity(0.5), fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: _slate.withOpacity(0.5), size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Catégories
            SizedBox(height: 36, child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final active = _selCat == _cats[i];
                return GestureDetector(
                  onTap: () { setState(() => _selCat = _cats[i]); _filter(); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? _rose : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? _rose : _border),
                    ),
                    child: Text(_cats[i], style: TextStyle(
                      fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? Colors.white : _slate,
                    )),
                  ),
                );
              },
            )),
            const SizedBox(height: 8),
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: _rose, unselectedLabelColor: _slate,
              indicatorColor: _rose, indicatorWeight: 2,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
              tabs: [
                Tab(text: 'Toutes (${_activities.length})'),
                Tab(text: 'Officielles (${_activities.where((a) => a['isOfficial'] == true).length})'),
                Tab(text: 'Communautaires (${_activities.where((a) => a['isOfficial'] == false).length})'),
              ],
            ),
          ]),
        ),
        // ── Grille ────────────────────────────────────────────────────────────
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: _rose))
          : _filtered.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('Aucune activité', style: TextStyle(color: _slate.withOpacity(0.5), fontSize: 14)),
              ]))
            : RefreshIndicator(
                onRefresh: _fetch, color: _rose,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 340, childAspectRatio: 0.72, crossAxisSpacing: 16, mainAxisSpacing: 16),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _ActivityCard(
                    activity: _filtered[i],
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ActivityDetailPage(activityId: _filtered[i]['_id'].toString())));
                      _fetch();
                    },
                  ),
                ),
              )),
      ]),
    );
  }
}

// ── Carte activité ────────────────────────────────────────────────────────────
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
          color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: activity['imageUrl'] != null && activity['imageUrl'].toString().isNotEmpty
                ? Image.network(activity['imageUrl'], height: 130, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgPlaceholder(activity['category']))
                : _imgPlaceholder(activity['category']),
            ),
            Positioned(top: 8, right: 8, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), borderRadius: BorderRadius.circular(10)),
              child: Text(isOfficial ? 'Officiel' : 'Communautaire',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
            )),
          ]),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: _rose.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(activity['category'] ?? '',
                  style: const TextStyle(fontSize: 9, color: _rose, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              Text(activity['title'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _ink),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(activity['description'] ?? '',
                style: TextStyle(color: _slate.withOpacity(0.7), fontSize: 11),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.people_outline_rounded, size: 11, color: _slate.withOpacity(0.5)),
                const SizedBox(width: 3),
                Text('${activity['membersCount'] ?? 0} membres',
                  style: TextStyle(color: _slate.withOpacity(0.6), fontSize: 10)),
                const Spacer(),
                Icon(Icons.chat_bubble_outline_rounded, size: 11, color: _slate.withOpacity(0.5)),
                const SizedBox(width: 3),
                Text('${activity['chatCount'] ?? 0}',
                  style: TextStyle(color: _slate.withOpacity(0.6), fontSize: 10)),
              ]),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ink, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0, minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text("Voir l'activité", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _imgPlaceholder(String? category) {
    const emojis = {'Cuisine':'🍳','Lecture':'📚','Jardinage':'🌱','Yoga':'🧘','Sport':'⚽','Autre':'✨'};
    return Container(height: 130, width: double.infinity,
      color: _rose.withOpacity(0.07),
      child: Center(child: Text(emojis[category] ?? '✨', style: const TextStyle(fontSize: 40))));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAGE DÉTAIL
// ═══════════════════════════════════════════════════════════════════════════
class ActivityDetailPage extends StatefulWidget {
  final String activityId;
  const ActivityDetailPage({super.key, required this.activityId});
  @override State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic>? _activity;
  bool _loading  = true;
  bool _isMember = false;
  final _chatCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); _fetch(); }
  @override void dispose() { _tabCtrl.dispose(); _chatCtrl.dispose(); super.dispose(); }

  Future<String?> _tok() async { final p = await SharedPreferences.getInstance(); return p.getString('auth_token'); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/activities/${widget.activityId}'),
        headers: {'Authorization': 'Bearer ${await _tok()}'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() { _activity = data; _isMember = data['isMember'] == true; });
      }
    } catch (e) { debugPrint('$e'); }
    finally { setState(() => _loading = false); }
  }

  Future<void> _toggleJoin() async {
    final ep = _isMember ? 'leave' : 'join';
    final res = await http.post(Uri.parse('$_baseUrl/api/activities/${widget.activityId}/$ep'),
      headers: {'Authorization': 'Bearer ${await _tok()}'});
    if (res.statusCode == 200 || res.statusCode == 201) { setState(() => _isMember = !_isMember); _fetch(); }
  }

  Future<void> _sendMessage() async {
    final text = _chatCtrl.text.trim(); if (text.isEmpty) return;
    await http.post(Uri.parse('$_baseUrl/api/activities/${widget.activityId}/chat'),
      headers: {'Authorization': 'Bearer ${await _tok()}', 'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}));
    _chatCtrl.clear(); _fetch();
  }

  Future<void> _likeContent(String contentId) async {
    await http.post(Uri.parse('$_baseUrl/api/activities/${widget.activityId}/content/$contentId/like'),
      headers: {'Authorization': 'Bearer ${await _tok()}'});
    _fetch();
  }

  Future<void> _commentContent(String contentId) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ajouter un commentaire', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(controller: ctrl, autofocus: true, maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Votre commentaire...',
            hintStyle: TextStyle(color: _slate.withOpacity(0.5), fontSize: 13),
            filled: true, fillColor: _snow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _rose, width: 2)),
          )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: _rose, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Publier')),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    await http.post(Uri.parse('$_baseUrl/api/activities/${widget.activityId}/content/$contentId/comment'),
      headers: {'Authorization': 'Bearer ${await _tok()}', 'Content-Type': 'application/json'},
      body: jsonEncode({'text': result}));
    _fetch();
  }

  Future<void> _addContent() async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => const _AddContentDialog());
    if (result == null) return;
    await http.post(Uri.parse('$_baseUrl/api/activities/${widget.activityId}/content'),
      headers: {'Authorization': 'Bearer ${await _tok()}', 'Content-Type': 'application/json'},
      body: jsonEncode(result));
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: _snow, body: Center(child: CircularProgressIndicator(color: _rose)));
    if (_activity == null) return const Scaffold(body: Center(child: Text('Activité introuvable')));

    final a       = _activity!;
    final members = List<dynamic>.from(a['members']  ?? []);
    final content = List<dynamic>.from(a['content']  ?? []);
    final chat    = List<dynamic>.from(a['chat']     ?? []);

    return Scaffold(
      backgroundColor: _snow,
      body: CustomScrollView(slivers: [
        // ── SliverAppBar ───────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 260, pinned: true,
          backgroundColor: _violet,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context)),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              a['imageUrl'] != null && a['imageUrl'].toString().isNotEmpty
                ? Image.network(a['imageUrl'], fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _gradientBg())
                : _gradientBg(),
              Container(decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)]))),
              Positioned(bottom: 16, left: 16, right: 16, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _rose.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                    child: Text(a['category'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
                  Text(a['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(a['description'] ?? '',
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                ])),
            ]),
          ),
          actions: [
            Padding(padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              child: GestureDetector(
                onTap: _toggleJoin,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isMember ? Colors.white.withOpacity(0.2) : _rose,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_isMember ? Icons.person_remove_outlined : Icons.person_add_outlined,
                      color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(_isMember ? 'Quitter' : 'Rejoindre',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              )),
          ],
        ),

        // ── Infos rapides ──────────────────────────────────────────────────────
        SliverToBoxAdapter(child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            _chip(Icons.people_outline_rounded, '${members.length} membres'),
            _chip(Icons.article_outlined, '${content.length} posts'),
            _chip(Icons.chat_bubble_outline_rounded, '${chat.length} messages'),
            if (a['date'] != null)     _chip(Icons.calendar_today_rounded, a['date']),
            if (a['timeSlot'] != null) _chip(Icons.access_time_rounded, a['timeSlot']),
            if (a['location'] != null) _chip(Icons.location_on_outlined, a['location']),
          ]),
        )),

        // ── TabBar ─────────────────────────────────────────────────────────────
        SliverToBoxAdapter(child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabCtrl,
            labelColor: _rose, unselectedLabelColor: _slate,
            indicatorColor: _rose, indicatorWeight: 2,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: [
              Tab(text: 'Contenu (${content.length})'),
              Tab(text: 'Membres (${members.length})'),
              Tab(text: 'Chat (${chat.length})'),
            ],
          ),
        )),

        SliverFillRemaining(child: TabBarView(controller: _tabCtrl, children: [
          _ContentTab(content: content, onAdd: _addContent, onLike: _likeContent, onComment: _commentContent),
          _MembersTab(members: members),
          ChatTab(activityId: widget.activityId, members: members),
        ])),
      ]),
    );
  }

  Widget _gradientBg() => Container(decoration: const BoxDecoration(
    gradient: LinearGradient(colors: [_rose, _violet], begin: Alignment.topLeft, end: Alignment.bottomRight)));

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: _rose.withOpacity(0.07), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: _rose),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: _rose, fontWeight: FontWeight.w500)),
    ]),
  );
}

// ── Onglet Contenu ─────────────────────────────────────────────────────────────
class _ContentTab extends StatelessWidget {
  final List<dynamic> content;
  final VoidCallback onAdd;
  final Function(String) onLike;
  final Function(String) onComment;
  const _ContentTab({required this.content, required this.onAdd, required this.onLike, required this.onComment});

  @override
  Widget build(BuildContext context) {
    return Container(color: _snow, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          const Text('Posts partagés', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _ink)),
          const Spacer(),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_rose, _violet]),
                borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('Partager', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ])),
      Expanded(child: content.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.article_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Soyez le premier à partager !', style: TextStyle(color: _slate.withOpacity(0.5), fontSize: 14)),
          ]))
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: content.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _PostCard(
              item: content[i],
              onLike: () => onLike(content[i]['id'].toString()),
              onComment: () => onComment(content[i]['id'].toString()),
            ),
          )),
    ]));
  }
}

// ── Card post ─────────────────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onLike;
  final VoidCallback onComment;
  const _PostCard({required this.item, required this.onLike, required this.onComment});

  @override
  Widget build(BuildContext context) {
    final comments = List<dynamic>.from(item['comments'] ?? []);
    final liked    = item['likedByMe'] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header auteur ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Row(children: [
            _avatar(item['username']),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _ink)),
              Text(_fmtDate(item['createdAt']), style: TextStyle(color: _slate.withOpacity(0.5), fontSize: 11)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _rose.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(item['type'] ?? '', style: const TextStyle(fontSize: 10, color: _rose, fontWeight: FontWeight.w600))),
          ]),
        ),
        // ── Contenu ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _ink)),
            const SizedBox(height: 6),
            Text(item['body'] ?? '', style: TextStyle(fontSize: 13, color: _slate.withOpacity(0.8), height: 1.5)),
          ]),
        ),
        // ── Photo si disponible ──────────────────────────────────────────────
        if (item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(item['imageUrl'],
                width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox()),
            ),
          ),
        // ── Actions ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(children: [
            // Like
            GestureDetector(
              onTap: onLike,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: liked ? _rose.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 18, color: liked ? _rose : _slate.withOpacity(0.5)),
                  const SizedBox(width: 5),
                  Text('${item['likes'] ?? 0}',
                    style: TextStyle(fontSize: 12, color: liked ? _rose : _slate.withOpacity(0.5),
                      fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            // Commenter
            GestureDetector(
              onTap: onComment,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 18, color: _slate.withOpacity(0.5)),
                  const SizedBox(width: 5),
                  Text('${comments.length}',
                    style: TextStyle(fontSize: 12, color: _slate.withOpacity(0.5), fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ),
        // ── Commentaires ─────────────────────────────────────────────────────
        if (comments.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _snow, borderRadius: BorderRadius.circular(12)),
            child: Column(children: comments.take(3).map<Widget>((c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _avatar(c['username'], size: 14),
                const SizedBox(width: 8),
                Expanded(child: RichText(text: TextSpan(children: [
                  TextSpan(text: '${c['username']}  ',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _ink)),
                  TextSpan(text: c['text'] ?? '',
                    style: TextStyle(fontSize: 12, color: _slate.withOpacity(0.8))),
                ]))),
              ]),
            )).toList()),
          ),
      ]),
    );
  }

  Widget _avatar(String? username, {double size = 18}) {
    return CircleAvatar(radius: size, backgroundColor: _rose.withOpacity(0.15),
      child: Text((username ?? 'U')[0].toUpperCase(),
        style: TextStyle(fontWeight: FontWeight.bold, color: _rose, fontSize: size * 0.8)));
  }

  String _fmtDate(dynamic date) {
    if (date == null) return '';
    try {
      final d = DateTime.parse(date.toString()).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return 'A l\'instant';
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return ''; }
  }
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
      Text('Aucun membre pour le moment', style: TextStyle(color: _slate.withOpacity(0.5), fontSize: 14)),
    ]));
    return Container(color: _snow, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Row(children: [
          const Text('Membres de l\'activité', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _ink)),
          const Spacer(),
          Text('${members.length} personnes', style: TextStyle(fontSize: 12, color: _slate.withOpacity(0.6))),
        ])),
      Expanded(child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final m = members[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              CircleAvatar(radius: 22, backgroundColor: _rose.withOpacity(0.12),
                child: Text((m['username'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: _rose, fontSize: 18))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _ink)),
                Text('${m['points'] ?? 0} points', style: TextStyle(fontSize: 11, color: _slate.withOpacity(0.6))),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🏆', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text('${m['points'] ?? 0}', style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.w700)),
                ])),
            ]),
          );
        },
      )),
    ]));
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
    return Container(color: _snow, child: Column(children: [
      Expanded(child: chat.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Commencez la conversation !', style: TextStyle(color: _slate.withOpacity(0.5), fontSize: 14)),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: chat.length,
            itemBuilder: (_, i) {
              final m = chat[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(radius: 17, backgroundColor: _rose.withOpacity(0.12),
                    child: Text((m['username'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _rose))),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(m['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _ink)),
                      const SizedBox(width: 8),
                      Text(_fmtDate(m['createdAt']), style: TextStyle(color: _slate.withOpacity(0.4), fontSize: 10)),
                    ]),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(14), bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                      ),
                      child: Text(m['text'] ?? '', style: const TextStyle(fontSize: 13, color: _ink, height: 1.4))),
                  ])),
                ]),
              );
            },
          )),
      // Saisie
      Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _border)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: Row(children: [
          Expanded(child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Écrivez votre message...',
              hintStyle: TextStyle(color: _slate.withOpacity(0.4), fontSize: 13),
              filled: true, fillColor: _snow,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: _rose, width: 1.5)),
            ),
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_rose, _violet]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _rose.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18)),
          ),
        ]),
      ),
    ]));
  }

  String _fmtDate(dynamic date) {
    if (date == null) return '';
    try {
      final d = DateTime.parse(date.toString()).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return 'A l\'instant';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${d.day}/${d.month}';
    } catch (_) { return ''; }
  }
}

// ── Dialog créer activité ──────────────────────────────────────────────────────
class _CreateDialog extends StatefulWidget {
  const _CreateDialog();
  @override State<_CreateDialog> createState() => _CreateDialogState();
}
class _CreateDialogState extends State<_CreateDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _dateCtrl  = TextEditingController();
  final _timeCtrl  = TextEditingController();
  final _maxCtrl   = TextEditingController();
  String _cat  = 'Cuisine';
  String _type = 'collective';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [_rose, _violet]), borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            const Text('Créer une activité', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _ink)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 18),
          _f('Titre de l\'activité', _titleCtrl),
          const SizedBox(height: 10),
          _f('Description', _descCtrl, lines: 3),
          const SizedBox(height: 10),
          _f('URL de l\'image (optionnel)', _imageCtrl),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _drop('Catégorie', _cat, ['Cuisine','Lecture','Jardinage','Yoga','Sport','Autre'], (v) => setState(() => _cat = v!))),
            const SizedBox(width: 10),
            Expanded(child: _drop('Type', _type == 'collective' ? 'Collectif' : 'Individuel', ['Collectif','Individuel'],
              (v) => setState(() => _type = v == 'Collectif' ? 'collective' : 'individual'))),
          ]),
          const SizedBox(height: 10),
          _f('Date (ex: 2026-03-20)', _dateCtrl),
          const SizedBox(height: 10),
          _f('Horaire (ex: 14h00 - 16h00)', _timeCtrl),
          const SizedBox(height: 10),
          _f('Participants max', _maxCtrl, kb: TextInputType.number),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(foregroundColor: _slate, side: const BorderSide(color: _border),
                padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.w500)))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () {
                if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty) return;
                Navigator.pop(context, {
                  'title': _titleCtrl.text.trim(), 'description': _descCtrl.text.trim(),
                  'imageUrl': _imageCtrl.text.trim(), 'category': _cat, 'type': _type,
                  'date': _dateCtrl.text.trim().isNotEmpty ? _dateCtrl.text.trim() : null,
                  'timeSlot': _timeCtrl.text.trim().isNotEmpty ? _timeCtrl.text.trim() : null,
                  'maxParticipants': _maxCtrl.text.trim().isNotEmpty ? int.tryParse(_maxCtrl.text.trim()) : null,
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: _rose, foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Créer', style: TextStyle(fontWeight: FontWeight.w600)))),
          ]),
        ])),
    );
  }

  Widget _f(String hint, TextEditingController c, {int lines = 1, TextInputType kb = TextInputType.text}) =>
    TextField(controller: c, maxLines: lines, keyboardType: kb, style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: _slate.withOpacity(0.4), fontSize: 13),
        filled: true, fillColor: _snow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _rose, width: 2)),
      ));

  Widget _drop(String hint, String val, List<String> items, ValueChanged<String?> onChange) =>
    DropdownButtonFormField<String>(value: val,
      decoration: InputDecoration(
        filled: true, fillColor: _snow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
      ),
      style: const TextStyle(fontSize: 13, color: _ink),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChange);
}

// ── Dialog ajouter contenu ─────────────────────────────────────────────────────
class _AddContentDialog extends StatefulWidget {
  const _AddContentDialog();
  @override State<_AddContentDialog> createState() => _AddContentDialogState();
}
class _AddContentDialogState extends State<_AddContentDialog> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  final _imageCtrl = TextEditingController(); // ✅ Photo
  String _type = 'Recette';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [_rose, _violet]), borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            const Text('Partager du contenu', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _ink)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 18),
          _f('Titre', _titleCtrl),
          const SizedBox(height: 10),
          _f('Contenu...', _bodyCtrl, lines: 4),
          const SizedBox(height: 10),
          // ✅ Champ photo
          _f('URL de la photo (optionnel)', _imageCtrl),
          const SizedBox(height: 4),
          Text('Astuce : copiez l\'URL d\'une image depuis le web',
            style: TextStyle(fontSize: 11, color: _slate.withOpacity(0.5))),
          // Aperçu photo si URL valide
          if (_imageCtrl.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(_imageCtrl.text, height: 150, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(value: _type,
            decoration: InputDecoration(filled: true, fillColor: _snow,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
            ),
            style: const TextStyle(fontSize: 13, color: _ink),
            items: ['Recette','Article','Conseil','Autre'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _type = v!)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(foregroundColor: _slate, side: const BorderSide(color: _border),
                padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.w500)))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () {
                if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) return;
                Navigator.pop(context, {
                  'title': _titleCtrl.text.trim(), 'body': _bodyCtrl.text.trim(),
                  'type': _type,
                  'imageUrl': _imageCtrl.text.trim().isNotEmpty ? _imageCtrl.text.trim() : null,
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: _rose, foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Publier', style: TextStyle(fontWeight: FontWeight.w600)))),
          ]),
        ])),
    );
  }

  Widget _f(String hint, TextEditingController c, {int lines = 1}) =>
    TextField(controller: c, maxLines: lines, style: const TextStyle(fontSize: 13),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: _slate.withOpacity(0.4), fontSize: 13),
        filled: true, fillColor: _snow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _rose, width: 2)),
      ));
}