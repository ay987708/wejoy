import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wejoy/chat_tab.dart';
import 'package:wejoy/theme/theme_provider.dart';
import 'dart:convert';

const String _baseUrl = 'http://localhost:5000';
const Color _rose   = Color(0xFFD63FBF);
const Color _violet = Color(0xFF7C3AED);
const Color _ink    = Color(0xFF0F0F1A);
const Color _slate  = Color(0xFF64748B);
const Color _snow   = Color(0xFFF8FAFC);
const Color _border = Color(0xFFEEEEF5);

String _mimeSubtype(String? name) {
  final ext = (name ?? '').split('.').last.toLowerCase();
  switch (ext) {
    case 'png':  return 'png';
    case 'gif':  return 'gif';
    case 'webp': return 'webp';
    default:     return 'jpeg';
  }
}

// PAGE LISTE
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
  String _selCat            = 'Tous';
  final _cats = ['Tous','Cuisine','Lecture','Jardinage','Yoga','Sport','Autre'];

  Color get _rose   => context.read<ThemeProvider>().color1;
  Color get _violet => context.read<ThemeProvider>().color2;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _filter();
    });
    _fetch();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<String?> _tok() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('auth_token');
  }

  Future<void> _fetch() async {
    // activ l'indicateur de chargement.
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/activities'),
        headers: {'Authorization': 'Bearer ${await _tok()}'},
      );
      if (res.statusCode == 200) {
        setState(() { _activities = jsonDecode(res.body); _filter(); });
      }
    } catch (e) { debugPrint('$e'); }
    //arrête l'indicateur de chargement.
    finally { setState(() => _loading = false); }
  }

  void _filter() {
    setState(() {
      var l = List<dynamic>.from(_activities);
      if (_tabController.index == 1) l = l.where((a) => a['isOfficial'] == true).toList();
      if (_tabController.index == 2) l = l.where((a) => a['isOfficial'] == false).toList();
      if (_selCat != 'Tous') l = l.where((a) => a['category'] == _selCat).toList();
      if (_search.isNotEmpty) {
        l = l.where((a) =>
          (a['title'] as String).toLowerCase().contains(_search.toLowerCase())).toList();
      }
      _filtered = l;
    });
  }

  Future<void> _createActivity() async {
    final rose   = _rose;
    final violet = _violet;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CreateDialog(rose: rose, violet: violet),
    );
    if (result == null) return;

    final res = await http.post(
      Uri.parse('$_baseUrl/api/activities'),
      headers: {
        //token d’authentification
        'Authorization': 'Bearer ${await _tok()}',
        //format JSON
        'Content-Type': 'application/json',
      },
      body: jsonEncode(result),
    );
    if (res.statusCode == 201 && mounted) {
      _fetch();
      _showSuccess('Activité créée !');
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: _snow,
      body: Column(children: [
        Container(
          color: Colors.white,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                      gradient: LinearGradient(colors: [_rose, _violet]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Créer', style: TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: _snow, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: TextField(
                  onChanged: (v) { _search = v; _filter(); },
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une activité...',
                    hintStyle: TextStyle(color: _slate.withOpacity(0.5), fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded,
                      color: _slate.withOpacity(0.5), size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? Colors.white : _slate,
                    )),
                  ),
                );
              },
            )),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              labelColor: _rose,
              unselectedLabelColor: _slate,
              indicatorColor: _rose,
              indicatorWeight: 2,
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
        Expanded(child: _loading
          ? Center(child: CircularProgressIndicator(color: _rose))
          : _filtered.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('Aucune activité',
                  style: TextStyle(color: _slate.withOpacity(0.5), fontSize: 14)),
              ]))
            : RefreshIndicator(
                onRefresh: _fetch, color: _rose,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 340, childAspectRatio: 0.72,
                    crossAxisSpacing: 16, mainAxisSpacing: 16,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _ActivityCard(
                    activity: _filtered[i],
                    rose: _rose,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ActivityDetailPage(
                          activityId: _filtered[i]['_id'].toString())));
                      _fetch();
                    },
                  ),
                ),
              )),
      ]),
    );
  }
}

// ── Carte activité ──────────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final VoidCallback onTap;
  final Color rose;
  const _ActivityCard({required this.activity, required this.onTap, required this.rose});

  @override
  Widget build(BuildContext context) {
    final isOfficial = activity['isOfficial'] == true;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05), blurRadius: 12,
            offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: activity['imageUrl'] != null &&
                     activity['imageUrl'].toString().isNotEmpty
                ? Image.network(activity['imageUrl'],
                    height: 130, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgPlaceholder(activity['category']))
                : _imgPlaceholder(activity['category']),
            ),
            Positioned(top: 8, right: 8, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(10)),
              child: Text(isOfficial ? 'Officiel' : 'Communautaire',
                style: const TextStyle(
                  color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
            )),
          ]),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: rose.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(activity['category'] ?? '',
                  style: TextStyle(fontSize: 9, color: rose, fontWeight: FontWeight.w600)),
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
                child: const Text("Voir l'activité",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _imgPlaceholder(String? category) {
    const emojis = {
      'Cuisine':'🍳','Lecture':'📚','Jardinage':'🌱',
      'Yoga':'🧘','Sport':'⚽','Autre':'✨'
    };
    return Container(
      height: 130, width: double.infinity,
      color: rose.withOpacity(0.07),
      child: Center(child: Text(emojis[category] ?? '✨',
        style: const TextStyle(fontSize: 40))));
  }
}
// page détailll
class ActivityDetailPage extends StatefulWidget {
  final String activityId;
  const ActivityDetailPage({super.key, required this.activityId});
  @override State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic>? _activity;
  bool _loading        = true;
  bool _isMember       = false;
  bool _isPending      = false; 
  bool _isGroupAdmin   = false;
  int  _unreadChat     = 0;
  String _currentUserId = '';

  Color get _rose   => context.read<ThemeProvider>().color1;
  Color get _violet => context.read<ThemeProvider>().color2;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _fetch();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<String?> _tok() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('auth_token');
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('user_id') ?? '';

      final res = await http.get(
        Uri.parse('$_baseUrl/api/activities/${widget.activityId}'),
        headers: {'Authorization': 'Bearer ${await _tok()}'},
      );
      if (res.statusCode == 200) {
        final data    = jsonDecode(res.body);
        final lastSeen = prefs.getInt('chat_last_seen_${widget.activityId}') ?? 0;
        final chat    = List<dynamic>.from(data['chat'] ?? []);
        final unread  = chat.where((m) {
          final t = DateTime.tryParse(m['createdAt'] ?? '')
            ?.millisecondsSinceEpoch ?? 0;
          return t > lastSeen;
        }).length;

        setState(() {
          _activity     = data;
          _isMember     = data['isMember']     == true;
          _isPending    = data['isPending']    == true;
          _isGroupAdmin = data['isGroupAdmin'] == true;
          _unreadChat   = unread;
        });
      }
    } catch (e) { debugPrint('$e'); }
    finally { setState(() => _loading = false); }
  }

  Future<void> _markChatRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'chat_last_seen_${widget.activityId}',
      DateTime.now().millisecondsSinceEpoch,
    );
    setState(() => _unreadChat = 0);
  }

  //  MODIFIÉ : gère 3 états — non-membre, en attente, membre
  Future<void> _toggleJoin() async {
    final rose = _rose;

    // État : en attente → proposer d'annuler
    if (_isPending) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Annuler la demande',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
          content: Text('Voulez-vous annuler votre demande d\'adhésion ?',
            style: TextStyle(fontSize: 13, color: _slate.withOpacity(0.8))),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: _slate, side: const BorderSide(color: _border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Non'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[400], foregroundColor: Colors.white,
                elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Annuler la demande',
                style: TextStyle(fontWeight: FontWeight.w600)))),
          ])],
        ),
      );
      if (confirmed != true) return;

      final res = await http.post(
        Uri.parse('$_baseUrl/api/activities/${widget.activityId}/join/cancel'),
        headers: {'Authorization': 'Bearer ${await _tok()}'},
      );
      if (res.statusCode == 200 && mounted) {
        setState(() => _isPending = false);
        _showSuccess('Demande annulée');
      }
      return;
    }

    // État : membre → proposer de quitter
    if (_isMember) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Quitter l\'activité',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
          content: Text('Voulez-vous quitter cette activité ?',
            style: TextStyle(fontSize: 13, color: _slate.withOpacity(0.8))),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: _slate, side: const BorderSide(color: _border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Annuler'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400], foregroundColor: Colors.white,
                elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Quitter',
                style: TextStyle(fontWeight: FontWeight.w600)))),
          ])],
        ),
      );
      if (confirmed != true) return;

      final res = await http.post(
        Uri.parse('$_baseUrl/api/activities/${widget.activityId}/leave'),
        headers: {'Authorization': 'Bearer ${await _tok()}'},
      );
      if (res.statusCode == 200 && mounted) {
        setState(() { _isMember = false; _isPending = false; });
        _fetch();
      }
      return;
    }

    // État : non-membre → envoyer une demande
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rejoindre l\'activité',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [rose.withOpacity(0.15), _violet.withOpacity(0.15)]),
              shape: BoxShape.circle),
            child: Icon(Icons.how_to_reg_outlined, color: rose, size: 28)),
          const SizedBox(height: 14),
          Text(
            'Votre demande sera envoyée à l\'administrateur du groupe qui pourra l\'accepter ou la refuser.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _slate.withOpacity(0.8), height: 1.5)),
        ]),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: _slate, side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Annuler'))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: rose, foregroundColor: Colors.white,
              elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Envoyer la demande',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)))),
        ])],
      ),
    );
    if (confirmed != true) return;

    final res = await http.post(
      Uri.parse('$_baseUrl/api/activities/${widget.activityId}/join'),
      headers: {'Authorization': 'Bearer ${await _tok()}'},
    );
    if (mounted) {
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['isPending'] == true) {
        setState(() => _isPending = true);
        _showInfo('Demande envoyée ! En attente de validation');
      } else if (res.statusCode == 400 && body['isPending'] == true) {
        setState(() => _isPending = true);
        _showInfo('Vous avez déjà une demande en attente');
      }
    }
  }

  //  Accepter un membre (admin)
  Future<void> _approveMember(String userId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/activities/${widget.activityId}/join/$userId/approve'),
      headers: {'Authorization': 'Bearer ${await _tok()}'},
    );
    if (res.statusCode == 200 && mounted) {
      _showSuccess('Membre accepté ');
      _fetch();
    }
  }

  //  Refuser un membre (admin)
  Future<void> _rejectMember(String userId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Refuser $username',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: const Text('La demande de cet utilisateur sera refusée.',
          style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400], foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Refuser')),
        ],
      ),
    );
    if (confirmed != true) return;

    final res = await http.post(
      Uri.parse('$_baseUrl/api/activities/${widget.activityId}/join/$userId/reject'),
      headers: {'Authorization': 'Bearer ${await _tok()}'},
    );
    if (res.statusCode == 200 && mounted) {
      _showSuccess('Demande refusée');
      _fetch();
    }
  }

  Future<void> _likeContent(String contentId) async {
    await http.post(
      Uri.parse('$_baseUrl/api/activities/${widget.activityId}/content/$contentId/like'),
      headers: {'Authorization': 'Bearer ${await _tok()}'},
    );
    _fetch();
  }

  Future<void> _commentContent(String contentId) async {
    final rose = _rose;
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ajouter un commentaire',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(controller: ctrl, autofocus: true, maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Votre commentaire...',
            hintStyle: TextStyle(color: _slate.withOpacity(0.5), fontSize: 13),
            filled: true, fillColor: _snow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: rose, width: 2)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: rose, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Publier')),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    await http.post(
      Uri.parse('$_baseUrl/api/activities/${widget.activityId}/content/$contentId/comment'),
      headers: {'Authorization': 'Bearer ${await _tok()}', 'Content-Type': 'application/json'},
      body: jsonEncode({'text': result}),
    );
    _fetch();
  }

  Future<void> _editContent(String contentId, Map<String, dynamic> current) async {
    final rose   = _rose;
    final violet = _violet;
    final titleCtrl = TextEditingController(text: current['title']?.toString() ?? '');
    final bodyCtrl  = TextEditingController(text: current['body']?.toString() ?? '');
    String type = current['type']?.toString() ?? 'Autre';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [rose, violet]),
                    borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Modifier le contenu',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _ink))),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 18),
              TextField(
                controller: titleCtrl, style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Titre',
                  hintStyle: TextStyle(color: _slate.withOpacity(0.4), fontSize: 13),
                  filled: true, fillColor: _snow,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: rose, width: 2))),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyCtrl, maxLines: 4, style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Contenu...',
                  hintStyle: TextStyle(color: _slate.withOpacity(0.4), fontSize: 13),
                  filled: true, fillColor: _snow,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: rose, width: 2))),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: type,
                decoration: InputDecoration(
                  filled: true, fillColor: _snow,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border))),
                style: const TextStyle(fontSize: 13, color: _ink),
                items: ['Recette','Article','Conseil','Autre'].map((t) =>
                  DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setStateDialog(() => type = v!),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _slate, side: const BorderSide(color: _border),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Annuler'))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx, {
                      'title': titleCtrl.text.trim(),
                      'body':  bodyCtrl.text.trim(),
                      'type':  type,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: rose, foregroundColor: Colors.white, elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Enregistrer',
                    style: TextStyle(fontWeight: FontWeight.w600)))),
              ]),
            ]),
          ),
        ),
      ),
    );

    if (result == null) return;
    final res = await http.put(
      Uri.parse('$_baseUrl/api/activities/${widget.activityId}/content/$contentId'),
      headers: {'Authorization': 'Bearer ${await _tok()}', 'Content-Type': 'application/json'},
      body: jsonEncode(result),
    );
    if ((res.statusCode == 200 || res.statusCode == 201) && mounted) {
      _showSuccess('Contenu modifié ✅');
      _fetch();
    }
  }

  Future<void> _deleteContent(String contentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer ce contenu',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
        content: Text('Cette action est irréversible.',
          style: TextStyle(fontSize: 13, color: _slate.withOpacity(0.8))),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: _slate, side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Annuler'))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400], foregroundColor: Colors.white,
              elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Supprimer',
              style: TextStyle(fontWeight: FontWeight.w600)))),
        ])],
      ),
    );
    if (confirmed != true) return;
    final res = await http.delete(
      Uri.parse('$_baseUrl/api/activities/${widget.activityId}/content/$contentId'),
      headers: {'Authorization': 'Bearer ${await _tok()}'},
    );
    if ((res.statusCode == 200 || res.statusCode == 204) && mounted) {
      _showSuccess('Contenu supprimé ✅');
      _fetch();
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFF59E0B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _deleteChatMessage(String msgId) async {
    await http.delete(
      Uri.parse('$_baseUrl/api/activities/${widget.activityId}/chat/$msgId'),
      headers: {'Authorization': 'Bearer ${await _tok()}'},
    );
    _fetch();
  }

  Future<void> _blockMember(String userId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Bloquer $username',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: const Text(
          'Ce membre sera retiré de l\'activité et ne pourra plus y participer.',
          style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400], foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Bloquer')),
        ],
      ),
    );
    if (confirmed != true) return;
    await http.post(
      Uri.parse('$_baseUrl/api/activities/${widget.activityId}/members/$userId/block'),
      headers: {'Authorization': 'Bearer ${await _tok()}'},
    );
    _fetch();
  }

  Future<void> _changeGroupTheme() async {
    final rose   = _rose;
    final violet = _violet;
    final themes = [
      {'color': rose,                       'label': 'Principal'},
      {'color': violet,                     'label': 'Secondaire'},
      {'color': const Color(0xFF0EA5E9),    'label': 'Bleu'},
      {'color': const Color(0xFF10B981),    'label': 'Vert'},
      {'color': const Color(0xFFF59E0B),    'label': 'Ambre'},
      {'color': const Color(0xFFEF4444),    'label': 'Rouge'},
      {'color': _ink,                       'label': 'Sombre'},
    ];
    Color? selected;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Thème du groupe',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
        content: Wrap(
          spacing: 12, runSpacing: 12,
          children: themes.map((t) => GestureDetector(
            onTap: () { selected = t['color'] as Color; Navigator.pop(context); },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: t['color'] as Color, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.12), blurRadius: 6)]),
            ),
          )).toList()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ],
      ),
    );
    if (selected == null) return;
    final colorHex =
      '#${selected!.value.toRadixString(16).substring(2).toUpperCase()}';
    await http.patch(
      Uri.parse('$_baseUrl/api/activities/${widget.activityId}/theme'),
      headers: {'Authorization': 'Bearer ${await _tok()}', 'Content-Type': 'application/json'},
      body: jsonEncode({'themeColor': colorHex}),
    );
    _fetch();
  }

  Future<void> _addContent() async {
    final rose   = _rose;
    final violet = _violet;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AddContentDialog(rose: rose, violet: violet),
    );
    if (result == null) return;

    final Uint8List? imageBytes = result['imageBytes'] as Uint8List?;
    final String?   imageName  = result['imageName']  as String?;

    if (imageBytes != null && imageName != null) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/activities/${widget.activityId}/content'),
      );
      request.headers['Authorization'] = 'Bearer ${await _tok()}';
      request.fields['title'] = result['title'] ?? '';
      request.fields['body']  = result['body']  ?? '';
      request.fields['type']  = result['type']  ?? '';
      request.files.add(http.MultipartFile.fromBytes(
        'image', imageBytes,
        filename: imageName,
        contentType: MediaType('image', _mimeSubtype(imageName)),
      ));
      await request.send();
    } else {
      await http.post(
        Uri.parse('$_baseUrl/api/activities/${widget.activityId}/content'),
        headers: {'Authorization': 'Bearer ${await _tok()}', 'Content-Type': 'application/json'},
        body: jsonEncode({'title': result['title'], 'body': result['body'], 'type': result['type']}),
      );
    }
    _fetch();
  }

  // ✅ Builder du bouton d'action selon l'état
  Widget _buildJoinButton() {
    if (_isMember) {
      return GestureDetector(
        onTap: _toggleJoin,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3))),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.person_remove_outlined, color: Colors.white, size: 14),
            SizedBox(width: 6),
            Text('Quitter', style: TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
    }

    if (_isPending) {
      return GestureDetector(
        onTap: _toggleJoin,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3))),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 12, height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5, color: Colors.white)),
            SizedBox(width: 7),
            Text('En attente', style: TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
    }

    // Non-membre
    return GestureDetector(
      onTap: _toggleJoin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _rose,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3))),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.person_add_outlined, color: Colors.white, size: 14),
          SizedBox(width: 6),
          Text('Rejoindre', style: TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();

    if (_loading) return Scaffold(
      backgroundColor: _snow,
      body: Center(child: CircularProgressIndicator(color: _rose)));
    if (_activity == null) return const Scaffold(
      body: Center(child: Text('Activité introuvable')));

    final a              = _activity!;
    final members        = List<dynamic>.from(a['members']        ?? []);
    final content        = List<dynamic>.from(a['content']        ?? []);
    final chat           = List<dynamic>.from(a['chat']           ?? []);
    final pendingMembers = List<dynamic>.from(a['pendingMembers'] ?? []);

    return Scaffold(
      backgroundColor: _snow,
      body: CustomScrollView(slivers: [
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
              Positioned(bottom: 16, left: 16, right: 16,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _rose.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(a['category'] ?? '', style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
                  Text(a['title'] ?? '', style: const TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(a['description'] ?? '', style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 12),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                ])),
            ]),
          ),
          actions: [
            if (_isGroupAdmin) ...[
              // ✅ Badge demandes en attente
              if (pendingMembers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.mark_email_unread_outlined,
                          color: Colors.white, size: 20),
                        tooltip: 'Demandes en attente',
                        onPressed: () => _showPendingSheet(pendingMembers)),
                      Positioned(
                        top: 4, right: 4,
                        child: Container(
                          width: 16, height: 16,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B), shape: BoxShape.circle),
                          child: Center(
                            child: Text('${pendingMembers.length}',
                              style: const TextStyle(
                                color: Colors.white, fontSize: 9,
                                fontWeight: FontWeight.w800))))),
                    ],
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.palette_outlined, color: Colors.white, size: 20),
                tooltip: 'Changer le thème',
                onPressed: _changeGroupTheme),
            ],
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              child: _buildJoinButton()),
          ],
        ),

        // ✅ Bannière "En attente de validation" pour les non-membres en attente
        if (_isPending && !_isMember)
          SliverToBoxAdapter(child: _PendingBanner(
            onCancel: _toggleJoin, rose: _rose)),

        SliverToBoxAdapter(child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabCtrl,
            onTap: (i) { if (i == 2) _markChatRead(); },
            labelColor: _rose, unselectedLabelColor: _slate,
            indicatorColor: _rose, indicatorWeight: 2,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: [
              Tab(text: 'Contenu (${content.length})'),
              Tab(text: 'Membres (${members.length})'),
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Chat (${chat.length})', style: const TextStyle(fontSize: 13)),
                if (_unreadChat > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    child: Text('$_unreadChat', style: const TextStyle(
                      color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
                ],
              ])),
            ],
          ),
        )),

        SliverFillRemaining(child: (!_isMember)
          ? _LockedContent(
              isPending: _isPending,
              onJoin: _toggleJoin,
              rose: _rose,
              violet: _violet)
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _ContentTab(
                  content: content,
                  onAdd: _addContent,
                  onLike: _likeContent,
                  onComment: _commentContent,
                  onEdit: (id) {
                    final item = content.firstWhere(
                      (c) => c['id'].toString() == id,
                      orElse: () => <String, dynamic>{});
                    if (item.isNotEmpty) _editContent(id, item as Map<String, dynamic>);
                  },
                  onDelete: _deleteContent,
                  currentUserId: _currentUserId,
                  isGroupAdmin: _isGroupAdmin,
                  rose: _rose,
                  violet: _violet,
                ),
                _MembersTab(
                  members: members,
                  isGroupAdmin: _isGroupAdmin,
                  onBlock: _blockMember,
                  rose: _rose),
                ChatTab(
                  activityId: widget.activityId,
                  members: members,
                  isGroupAdmin: _isGroupAdmin,
                  onDeleteMessage: _deleteChatMessage),
              ],
            )),
      ]),
    );
  }

  // ✅ Bottom sheet pour gérer les demandes en attente
  void _showPendingSheet(List<dynamic> pending) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PendingMembersSheet(
        pending: pending,
        rose: _rose,
        onApprove: _approveMember,
        onReject: _rejectMember,
      ),
    );
  }

  Widget _gradientBg() => Container(decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [_rose, _violet],
      begin: Alignment.topLeft, end: Alignment.bottomRight)));
}

//  bannière "en attente de validation"
class _PendingBanner extends StatelessWidget {
  final VoidCallback onCancel;
  final Color rose;
  const _PendingBanner({required this.onCancel, required this.rose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(0.15),
            shape: BoxShape.circle),
          child: const Center(child: Text('⏳', style: TextStyle(fontSize: 18)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Demande en attente',
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: Color(0xFF92400E))),
          const SizedBox(height: 2),
          Text('L\'administrateur du groupe doit valider votre demande.',
            style: TextStyle(fontSize: 11, color: const Color(0xFF92400E).withOpacity(0.7))),
        ])),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onCancel,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8)),
            child: const Text('Annuler',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: Color(0xFF92400E)))),
        ),
      ]),
    );
  }
}

//  Bottom sheet des demandes en attente (vue admin)
class _PendingMembersSheet extends StatelessWidget {
  final List<dynamic> pending;
  final Color rose;
  final Function(String) onApprove;
  final Function(String, String) onReject;

  const _PendingMembersSheet({
    required this.pending,
    required this.rose,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, scrollCtrl) => Column(children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: _border, borderRadius: BorderRadius.circular(2))),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.mark_email_unread_outlined,
                color: Color(0xFFF59E0B), size: 18)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Demandes d\'adhésion',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
              Text('${pending.length} demande${pending.length > 1 ? 's' : ''} en attente',
                style: TextStyle(fontSize: 12, color: _slate.withOpacity(0.6))),
            ]),
          ])),
        const Divider(height: 24),
        // Liste
        Expanded(child: pending.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 10),
              Text('Aucune demande en attente',
                style: TextStyle(color: _slate.withOpacity(0.5), fontSize: 14)),
            ]))
          : ListView.separated(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: pending.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final p        = pending[i];
                final userId   = p['userId']?.toString() ?? '';
                final username = p['username']?.toString() ?? 'Utilisateur';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8, offset: const Offset(0, 2))]),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: rose.withOpacity(0.12),
                      child: Text(username[0].toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w700, color: rose, fontSize: 18))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14, color: _ink)),
                      if (p['requestedAt'] != null)
                        Text(_formatDate(p['requestedAt']),
                          style: TextStyle(fontSize: 11, color: _slate.withOpacity(0.5))),
                    ])),
                    // Bouton refuser
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onReject(userId, username);
                      },
                      child: Container(
                        width: 36, height: 36,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.close_rounded,
                          color: Colors.red, size: 18))),
                    // Bouton accepter
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onApprove(userId);
                      },
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.check_rounded,
                          color: Color(0xFF10B981), size: 18))),
                  ]),
                );
              },
            )),
        const SizedBox(height: 20),
      ]),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final d    = DateTime.parse(date.toString()).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return 'À l\'instant';
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return ''; }
  }
}

// ── Contenu verrouillé ──────────────────────────────────────────────────────
class _LockedContent extends StatelessWidget {
  final VoidCallback onJoin;
  final bool isPending;   
  final Color rose;
  final Color violet;
  const _LockedContent({
    required this.onJoin,
    required this.isPending,
    required this.rose,
    required this.violet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _snow,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // icone différente selon l'état
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPending
                      ? [const Color(0xFFF59E0B).withOpacity(0.15), const Color(0xFFFDE68A).withOpacity(0.15)]
                      : [rose.withOpacity(0.15), violet.withOpacity(0.15)]),
                  shape: BoxShape.circle),
                child: isPending
                  ? const Center(child: Text('⏳', style: TextStyle(fontSize: 36)))
                  : Icon(Icons.lock_rounded, size: 36, color: rose),
              ),
              const SizedBox(height: 20),
              Text(
                isPending
                  ? 'Demande en cours d\'examen'
                  : 'Contenu réservé aux membres',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: _ink),
              ),
              const SizedBox(height: 10),
              Text(
                isPending
                  ? 'Votre demande a été envoyée à l\'administrateur. Vous aurez accès au contenu, aux membres et au chat dès validation.'
                  : 'Rejoignez cette activité pour accéder au contenu, aux membres et au chat.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13, color: _slate.withOpacity(0.7), height: 1.5),
              ),
              if (isPending) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onJoin,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3))),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.cancel_outlined, size: 16, color: Color(0xFF92400E)),
                      SizedBox(width: 8),
                      Text('Annuler la demande',
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E))),
                    ]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Onglet Contenu ──────────────────────────────────────────────────────────
class _ContentTab extends StatelessWidget {
  final List<dynamic> content;
  final VoidCallback onAdd;
  final Function(String) onLike;
  final Function(String) onComment;
  final Function(String) onEdit;
  final Function(String) onDelete;
  final String currentUserId;
  final bool isGroupAdmin;
  final Color rose;
  final Color violet;

  const _ContentTab({
    required this.content,
    required this.onAdd,
    required this.onLike,
    required this.onComment,
    required this.onEdit,
    required this.onDelete,
    required this.currentUserId,
    required this.isGroupAdmin,
    required this.rose,
    required this.violet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(color: _snow, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          const Text('Posts partagés',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _ink)),
          const Spacer(),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [rose, violet]),
                borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('Partager', style: TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ])),
      Expanded(child: content.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.article_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Soyez le premier à partager !',
              style: TextStyle(color: _slate.withOpacity(0.5), fontSize: 14)),
          ]))
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: content.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _PostCard(
              item: content[i] as Map<String, dynamic>,
              rose: rose,
              currentUserId: currentUserId,
              isGroupAdmin: isGroupAdmin,
              onLike:    () => onLike(content[i]['id'].toString()),
              onComment: () => onComment(content[i]['id'].toString()),
              onEdit:    () => onEdit(content[i]['id'].toString()),
              onDelete:  () => onDelete(content[i]['id'].toString()),
            ),
          )),
    ]));
  }
}

// ── Card post ───────────────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String currentUserId;
  final bool isGroupAdmin;
  final Color rose;

  const _PostCard({
    required this.item,
    required this.onLike,
    required this.onComment,
    required this.onEdit,
    required this.onDelete,
    required this.currentUserId,
    required this.isGroupAdmin,
    required this.rose,
  });

  @override
  Widget build(BuildContext context) {
    final comments = List<dynamic>.from(item['comments'] ?? []);
    final liked    = item['likedByMe'] == true;
    final rawUrl   = item['imageUrl']?.toString() ?? '';
    final imageUrl = rawUrl.replaceFirst('localhost', '127.0.0.1');

    final isAuthor  = item['userId']?.toString() == currentUserId;
    final canManage = isAuthor || isGroupAdmin;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04), blurRadius: 10,
          offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
          child: Row(children: [
            _avatar(item['username']),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['username'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _ink)),
              Text(_fmtDate(item['createdAt']),
                style: TextStyle(color: _slate.withOpacity(0.5), fontSize: 11)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: rose.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(item['type'] ?? '',
                style: TextStyle(fontSize: 10, color: rose, fontWeight: FontWeight.w600))),
            if (item['edited'] == true) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _slate.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                child: Text('modifié',
                  style: TextStyle(fontSize: 9, color: _slate.withOpacity(0.6)))),
            ],
            if (canManage)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: _slate.withOpacity(0.5), size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4, color: Colors.white,
                onSelected: (v) {
                  if (v == 'edit')   onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  if (isAuthor)
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: rose.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.edit_outlined, size: 14, color: rose)),
                        const SizedBox(width: 10),
                        const Text('Modifier',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ])),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.delete_outline_rounded,
                          size: 14, color: Colors.red)),
                      const SizedBox(width: 10),
                      const Text('Supprimer',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                          color: Colors.red)),
                    ])),
                ],
              ),
          ])),
        Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _ink)),
            const SizedBox(height: 6),
            Text(item['body'] ?? '',
              style: TextStyle(fontSize: 13, color: _slate.withOpacity(0.8), height: 1.5)),
          ])),
        if (imageUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imageUrl,
                width: double.infinity, height: 220, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox()))),
        Padding(padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(children: [
            GestureDetector(
              onTap: onLike,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: liked ? rose.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 18, color: liked ? rose : _slate.withOpacity(0.5)),
                  const SizedBox(width: 5),
                  Text('${item['likes'] ?? 0}', style: TextStyle(
                    fontSize: 12, color: liked ? rose : _slate.withOpacity(0.5),
                    fontWeight: FontWeight.w600)),
                ]))),
            GestureDetector(
              onTap: onComment,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 18,
                    color: _slate.withOpacity(0.5)),
                  const SizedBox(width: 5),
                  Text('${comments.length}', style: TextStyle(
                    fontSize: 12, color: _slate.withOpacity(0.5),
                    fontWeight: FontWeight.w600)),
                ]))),
          ])),
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
              ]))).toList())),
      ]),
    );
  }

  Widget _avatar(String? username, {double size = 18}) => CircleAvatar(
    radius: size, backgroundColor: rose.withOpacity(0.15),
    child: Text((username ?? 'U')[0].toUpperCase(),
      style: TextStyle(fontWeight: FontWeight.bold, color: rose, fontSize: size * 0.8)));

  String _fmtDate(dynamic date) {
    if (date == null) return '';
    try {
      final d    = DateTime.parse(date.toString()).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return 'A l\'instant';
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return ''; }
  }
}

// ── Onglet Membres ──────────────────────────────────────────────────────────
class _MembersTab extends StatelessWidget {
  final List<dynamic> members;
  final bool isGroupAdmin;
  final Function(String userId, String username) onBlock;
  final Color rose;
  const _MembersTab({
    required this.members, required this.isGroupAdmin,
    required this.onBlock, required this.rose});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey[300]),
      const SizedBox(height: 12),
      Text('Aucun membre pour le moment',
        style: TextStyle(color: _slate.withOpacity(0.5), fontSize: 14)),
    ]));

    return Container(color: _snow, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Row(children: [
          const Text('Membres de l\'activité',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _ink)),
          const Spacer(),
          Text('${members.length} personnes',
            style: TextStyle(fontSize: 12, color: _slate.withOpacity(0.6))),
        ])),
      Expanded(child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final m         = members[i];
          final isCreator = m['isCreator'] == true;
          final isBlocked = m['isBlocked'] == true;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.03), blurRadius: 8,
                offset: const Offset(0, 2))]),
            child: Row(children: [
              CircleAvatar(
                radius: 22, backgroundColor: rose.withOpacity(0.12),
                child: Text((m['username'] ?? 'U')[0].toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.w700, color: rose, fontSize: 18))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(m['username'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _ink)),
                  if (isCreator) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6)),
                      child: const Text('👑 Admin', style: TextStyle(
                        fontSize: 9, color: Color(0xFFF59E0B), fontWeight: FontWeight.w700))),
                  ],
                ]),
                Text('${m['points'] ?? 0} points',
                  style: TextStyle(fontSize: 11, color: _slate.withOpacity(0.6))),
              ])),
              if (isGroupAdmin && !isCreator)
                GestureDetector(
                  onTap: () => onBlock(
                    (m['_id'] ?? m['userId'] ?? m['id']).toString(),
                    m['username'] ?? ''),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isBlocked
                        ? Colors.red.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isBlocked ? Colors.red.withOpacity(0.3) : _border)),
                    child: Text(isBlocked ? '🚫 Bloqué' : 'Bloquer',
                      style: TextStyle(
                        fontSize: 10,
                        color: isBlocked ? Colors.red : _slate,
                        fontWeight: FontWeight.w600))),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🏆', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text('${m['points'] ?? 0}', style: const TextStyle(
                      fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.w700)),
                  ])),
            ]),
          );
        },
      )),
    ]));
  }
}

// ── Dialog créer activité ───────────────────────────────────────────────────
class _CreateDialog extends StatefulWidget {
  final Color rose;
  final Color violet;
  const _CreateDialog({required this.rose, required this.violet});
  @override State<_CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<_CreateDialog> {
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _dateCtrl     = TextEditingController();
  final _timeCtrl     = TextEditingController();
  final _maxCtrl      = TextEditingController();
  String _cat = 'Cuisine';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [widget.rose, widget.violet]),
                borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            const Text('Créer une activité',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _ink)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 18),
          _f('Titre de l\'activité', _titleCtrl),
          const SizedBox(height: 10),
          _f('Description', _descCtrl, lines: 3),
          const SizedBox(height: 10),
          _f('URL de l\'image (optionnel)', _imageUrlCtrl),
          const SizedBox(height: 10),
          _drop('Catégorie', _cat,
            ['Cuisine','Lecture','Jardinage','Yoga','Sport','Autre'],
            (v) => setState(() => _cat = v!)),
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
              style: OutlinedButton.styleFrom(
                foregroundColor: _slate, side: const BorderSide(color: _border),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Annuler'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () {
                if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty) return;
                Navigator.pop(context, {
                  'title':       _titleCtrl.text.trim(),
                  'description': _descCtrl.text.trim(),
                  'imageUrl':    _imageUrlCtrl.text.trim().isNotEmpty
                                   ? _imageUrlCtrl.text.trim() : null,
                  'category':    _cat,
                  'type':        'collective',
                  'date':        _dateCtrl.text.trim().isNotEmpty ? _dateCtrl.text.trim() : null,
                  'timeSlot':    _timeCtrl.text.trim().isNotEmpty ? _timeCtrl.text.trim() : null,
                  'maxParticipants': _maxCtrl.text.trim().isNotEmpty
                                   ? int.tryParse(_maxCtrl.text.trim()) : null,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.rose, foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Créer', style: TextStyle(fontWeight: FontWeight.w600)))),
          ]),
        ])),
    );
  }

  Widget _f(String hint, TextEditingController c,
    {int lines = 1, TextInputType kb = TextInputType.text}) =>
    TextField(controller: c, maxLines: lines, keyboardType: kb,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: _slate.withOpacity(0.4), fontSize: 13),
        filled: true, fillColor: _snow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.rose, width: 2))));

  Widget _drop(String hint, String val, List<String> items, ValueChanged<String?> onChange) =>
    DropdownButtonFormField<String>(value: val,
      decoration: InputDecoration(filled: true, fillColor: _snow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border))),
      style: const TextStyle(fontSize: 13, color: _ink),
      items: items.map((i) => DropdownMenuItem(
        value: i, child: Text(i, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChange);
}

// ── Dialog ajouter contenu ──────────────────────────────────────────────────
class _AddContentDialog extends StatefulWidget {
  final Color rose;
  final Color violet;
  const _AddContentDialog({required this.rose, required this.violet});
  @override State<_AddContentDialog> createState() => _AddContentDialogState();
}

class _AddContentDialogState extends State<_AddContentDialog> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  Uint8List? _imageBytes;
  String?    _imageName;
  String _type = 'Recette';

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() { _imageBytes = bytes; _imageName = picked.name; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [widget.rose, widget.violet]),
                borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            const Text('Partager du contenu',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _ink)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 18),
          _f('Titre', _titleCtrl),
          const SizedBox(height: 10),
          _f('Contenu...', _bodyCtrl, lines: 4),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: _imageBytes != null ? null : 80,
              decoration: BoxDecoration(
                color: _snow, borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _imageBytes != null ? widget.rose : _border,
                  width: _imageBytes != null ? 1.5 : 1)),
              child: _imageBytes != null
                ? Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.memory(_imageBytes!,
                        width: double.infinity, height: 140, fit: BoxFit.cover)),
                    Positioned(top: 6, right: 6,
                      child: GestureDetector(
                        onTap: () => setState(() { _imageBytes = null; _imageName = null; }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 14)))),
                  ])
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate_outlined, color: _slate.withOpacity(0.5), size: 26),
                    const SizedBox(height: 5),
                    Text('Ajouter une photo', style: TextStyle(fontSize: 12, color: _slate.withOpacity(0.6))),
                    Text('Depuis votre galerie', style: TextStyle(fontSize: 10, color: _slate.withOpacity(0.4))),
                  ])),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(value: _type,
            decoration: InputDecoration(filled: true, fillColor: _snow,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border))),
            style: const TextStyle(fontSize: 13, color: _ink),
            items: ['Recette','Article','Conseil','Autre'].map((t) =>
              DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _type = v!)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: _slate, side: const BorderSide(color: _border),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Annuler'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () {
                if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) return;
                Navigator.pop(context, {
                  'title':      _titleCtrl.text.trim(),
                  'body':       _bodyCtrl.text.trim(),
                  'type':       _type,
                  'imageBytes': _imageBytes,
                  'imageName':  _imageName,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.rose, foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Publier', style: TextStyle(fontWeight: FontWeight.w600)))),
          ]),
        ])),
    );
  }

  Widget _f(String hint, TextEditingController c, {int lines = 1}) =>
    TextField(controller: c, maxLines: lines,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: _slate.withOpacity(0.4), fontSize: 13),
        filled: true, fillColor: _snow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.rose, width: 2))));
}