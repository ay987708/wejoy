import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wejoy/theme/theme_provider.dart';

const String _baseUrl = 'http://localhost:5000';

// ── Palette ────────────────────────────────────────────────────────────────
const Color _ink     = Color(0xFF0D0D1A);
const Color _slate   = Color(0xFF64748B);
const Color _muted   = Color(0xFFA0AABA);
const Color _snow    = Color(0xFFF9FAFB);
const Color _white   = Colors.white;
const Color _border  = Color(0xFFEEEEF5);
const Color _green   = Color(0xFF22C55E);
const Color _orange  = Color(0xFFF97316);
const Color _red     = Color(0xFFEF4444);
const Color _bgPage  = Color(0xFFF4F3FF);

// ── Helpers ────────────────────────────────────────────────────────────────
LinearGradient _grad(Color a, Color b) =>
    LinearGradient(colors: [a, b], begin: Alignment.topLeft, end: Alignment.bottomRight);

BoxShadow _softShadow({double opacity = 0.07, double blur = 16, Offset offset = const Offset(0, 6)}) =>
    BoxShadow(color: Colors.black.withOpacity(opacity), blurRadius: blur, offset: offset);

// ══════════════════════════════════════════════════════════════════════════
class TachesPage extends StatefulWidget {
  const TachesPage({super.key});
  @override
  State<TachesPage> createState() => _TachesPageState();
}

class _TachesPageState extends State<TachesPage>
    with SingleTickerProviderStateMixin {
  Color get _rose   => context.read<ThemeProvider>().color1;
  Color get _violet => context.read<ThemeProvider>().color2;

  late TabController _tab;
  List<dynamic> _personal = [];
  List<dynamic> _collab   = [];
  bool _loading = true;
  final _personalCtrl = TextEditingController();
  Timer? _timer;

  // Filtre actif onglet Perso
  String _filter = 'Toutes';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _tab.dispose();
    _personalCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<String?> _tok() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('auth_token');
  }

  Future<Map<String, String>> _headers() async => {
    'Authorization': 'Bearer ${await _tok()}',
    'Content-Type': 'application/json',
  };

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/tasks'), headers: await _headers());
      if (res.statusCode == 200 && mounted) {
        final all = List<dynamic>.from(jsonDecode(res.body));
        setState(() {
          _personal = all.where((t) => t['type'] == 'personal').toList();
          _collab   = all.where((t) => t['type'] == 'collaborative').toList();
        });
      }
    } catch (_) {} finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _addPersonal() async {
    final title = _personalCtrl.text.trim();
    if (title.isEmpty) return;
    await http.post(
      Uri.parse('$_baseUrl/api/tasks'),
      headers: await _headers(),
      body: jsonEncode({'title': title, 'type': 'personal'}),
    );
    _personalCtrl.clear();
    _load(silent: true);
  }

  Future<void> _toggleComplete(String id) async {
    await http.post(Uri.parse('$_baseUrl/api/tasks/$id/complete'), headers: await _headers());
    _load(silent: true);
  }

  Future<void> _delete(String id) async {
    await http.delete(Uri.parse('$_baseUrl/api/tasks/$id'), headers: await _headers());
    _load(silent: true);
  }

  Future<void> _remind(String id, String title) async {
    final res = await http.post(Uri.parse('$_baseUrl/api/tasks/$id/remind'), headers: await _headers());
    if (mounted) {
      final data = jsonDecode(res.body);
      _showSnack(data['message'] ?? 'Rappel envoyé !', _violet);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  // ─── Stat rapide ──────────────────────────────────────────────────────
  int get _doneCnt  => _personal.where((t) => t['completedByMe'] == true).length;
  int get _todoCnt  => _personal.where((t) => t['completedByMe'] != true).length;
  int get _collabCnt => _collab.length;

  // ─── Filtre perso ────────────────────────────────────────────────────
  List<dynamic> get _filteredPersonal {
    switch (_filter) {
      case 'Faites':
        return _personal.where((t) => t['completedByMe'] == true).toList();
      case 'À faire':
        return _personal.where((t) => t['completedByMe'] != true).toList();
      default:
        return _personal;
    }
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────
  void _showCreateCollab() {
    final rose = _rose; final violet = _violet;
    final titleCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    final membersCtrl = TextEditingController();
    DateTime? dueDate;
    String priority = 'medium';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [_softShadow(opacity: 0.18, blur: 40)]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            // ── Header coloré
            Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 20, 20),
              decoration: BoxDecoration(
                gradient: _grad(rose, violet),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
              child: Row(children: [
                const Icon(Icons.group_add_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                const Text('Tâche collaborative',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 16))),
              ]),
            ),

            // ── Contenu
            Flexible(child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _dialogField(titleCtrl, 'Titre de la tâche *', Icons.task_alt_rounded, rose),
                const SizedBox(height: 12),
                _dialogField(descCtrl, 'Description (optionnel)', Icons.notes_rounded, rose, lines: 3),
                const SizedBox(height: 12),
                _dialogField(membersCtrl, 'Usernames des membres', Icons.people_outline_rounded, rose),
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 4),
                  child: Text('Ex : alice, bob, charlie',
                    style: TextStyle(fontSize: 11, color: _muted))),
                const SizedBox(height: 14),

                // Date picker
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (_, child) => Theme(
                        data: ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: rose)),
                        child: child!));
                    if (picked != null) setS(() => dueDate = picked);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: dueDate != null ? rose.withOpacity(0.05) : _snow,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: dueDate != null ? rose : _border, width: dueDate != null ? 1.5 : 1)),
                    child: Row(children: [
                      Icon(Icons.calendar_today_rounded, size: 17,
                        color: dueDate != null ? rose : _muted),
                      const SizedBox(width: 10),
                      Text(
                        dueDate != null
                          ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                          : 'Date limite (optionnel)',
                        style: TextStyle(
                          fontSize: 13,
                          color: dueDate != null ? rose : _muted,
                          fontWeight: dueDate != null ? FontWeight.w600 : FontWeight.w400)),
                      const Spacer(),
                      if (dueDate != null)
                        GestureDetector(
                          onTap: () => setS(() => dueDate = null),
                          child: Icon(Icons.close_rounded, size: 15, color: _muted)),
                    ])),
                ),
                const SizedBox(height: 16),

                // Priorité
                Text('Priorité', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _slate, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Row(children: [
                  for (final p in ['low', 'medium', 'high']) ...[
                    Expanded(child: _PriorityChip(
                      label: _priorityLabel(p),
                      color: _priorityColor(p),
                      selected: priority == p,
                      onTap: () => setS(() => priority = p),
                    )),
                    if (p != 'high') const SizedBox(width: 8),
                  ]
                ]),
              ]),
            )),

            // ── Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
              child: Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _slate,
                    side: const BorderSide(color: _border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                  child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.w500)))),
                const SizedBox(width: 12),
                Expanded(child: Container(
                  decoration: BoxDecoration(
                    gradient: _grad(rose, violet),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [BoxShadow(color: rose.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))]),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      final members = membersCtrl.text.trim().isEmpty
                        ? [] : membersCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                      Navigator.pop(ctx);
                      await http.post(
                        Uri.parse('$_baseUrl/api/tasks'),
                        headers: await _headers(),
                        body: jsonEncode({
                          'title': titleCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'type': 'collaborative',
                          'memberUsernames': members,
                          'dueDate': dueDate?.toIso8601String(),
                          'priority': priority,
                        }));
                      _load();
                      _showSnack('Tâche créée et membres notifiés 🎉', _green);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                    child: const Text('Créer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14))))),
              ]),
            ),
          ]),
        ),
      )),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final rose   = context.watch<ThemeProvider>().color1;
    final violet = context.watch<ThemeProvider>().color2;

    return Scaffold(
      backgroundColor: _bgPage,
      body: Column(children: [

        // ── HEADER ──────────────────────────────────────────────────────
        _Header(
          rose: rose, violet: violet,
          tab: _tab,
          personalCount: _personal.length,
          collabCount: _collab.length,
          doneCnt: _doneCnt,
          todoCnt: _todoCnt,
          onCreateCollab: _showCreateCollab,
        ),

        // ── BODY ────────────────────────────────────────────────────────
        Expanded(child: _loading
          ? Center(child: CircularProgressIndicator(color: rose, strokeWidth: 2.5))
          : TabBarView(controller: _tab, children: [
              _buildPersonalTab(rose, violet),
              _buildCollabTab(rose, violet),
            ])),
      ]),
    );
  }

  // ── Onglet Personnelles ───────────────────────────────────────────────
  Widget _buildPersonalTab(Color rose, Color violet) {
    final filters = ['Toutes', 'À faire', 'Faites'];

    return RefreshIndicator(
      onRefresh: _load, color: rose,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Column(children: [

              // Input ajout
              _AddTaskBar(controller: _personalCtrl, onAdd: _addPersonal, rose: rose),
              const SizedBox(height: 14),

              // Filtres
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => _FilterChip(
                    label: filters[i],
                    active: _filter == filters[i],
                    rose: rose,
                    onTap: () => setState(() => _filter = filters[i]),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ]),
          )),

          if (_filteredPersonal.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                icon: Icons.task_alt_rounded,
                title: _filter == 'Faites'
                  ? 'Aucune tâche terminée' : 'Aucune tâche personnelle',
                sub: 'Ajoutez une tâche ci-dessus',
                rose: rose))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final t = _filteredPersonal[i];
                  return _PersonalTaskCard(
                    key: ValueKey(t['id']),
                    task: t,
                    rose: rose,
                    violet: violet,
                    onToggle: () => _toggleComplete(t['id'].toString()),
                    onDelete: () => _delete(t['id'].toString()),
                  );
                },
                childCount: _filteredPersonal.length,
              ))),
        ],
      ),
    );
  }

  // ── Onglet Collaboratives ─────────────────────────────────────────────
  Widget _buildCollabTab(Color rose, Color violet) {
    final active  = _collab.where((t) => t['status'] == 'active').toList();
    final overdue = _collab.where((t) => t['status'] == 'overdue').toList();
    final done    = _collab.where((t) => t['status'] == 'completed').toList();

    return RefreshIndicator(
      onRefresh: _load, color: rose,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (_collab.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                icon: Icons.group_outlined,
                title: 'Aucune tâche collaborative',
                sub: 'Créez une tâche et invitez vos amis !',
                rose: rose))
          else ...[
            if (overdue.isNotEmpty) ...[
              _SliverSectionHeader(label: 'En retard', count: overdue.length, color: _red),
              _SliverTaskList(tasks: overdue, rose: rose, violet: violet,
                onToggle: (id) => _toggleComplete(id),
                onDelete: (id) => _delete(id),
                onRemind: (id, t) => _remind(id, t)),
            ],
            if (active.isNotEmpty) ...[
              _SliverSectionHeader(label: 'En cours', count: active.length, color: _orange),
              _SliverTaskList(tasks: active, rose: rose, violet: violet,
                onToggle: (id) => _toggleComplete(id),
                onDelete: (id) => _delete(id),
                onRemind: (id, t) => _remind(id, t)),
            ],
            if (done.isNotEmpty) ...[
              _SliverSectionHeader(label: 'Terminées', count: done.length, color: _green),
              _SliverTaskList(tasks: done, rose: rose, violet: violet,
                onToggle: (id) => _toggleComplete(id),
                onDelete: (id) => _delete(id),
                onRemind: (id, t) => _remind(id, t)),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
          ],
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint, IconData icon, Color rose, {int lines = 1}) =>
    TextField(
      controller: ctrl,
      maxLines: lines,
      style: const TextStyle(fontSize: 13, color: _ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _muted, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: _muted),
        filled: true, fillColor: _snow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: rose, width: 1.5))));
}

// ══════════════════════════════════════════════════════════════════════════
// HEADER
// ══════════════════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final Color rose, violet;
  final TabController tab;
  final int personalCount, collabCount, doneCnt, todoCnt;
  final VoidCallback onCreateCollab;

  const _Header({
    required this.rose, required this.violet, required this.tab,
    required this.personalCount, required this.collabCount,
    required this.doneCnt, required this.todoCnt,
    required this.onCreateCollab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _white,
        boxShadow: [BoxShadow(color: Color(0x09000000), blurRadius: 20, offset: Offset(0, 4))]),
      child: Column(children: [

        // ── Top row ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Mes Tâches',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5)),
              const SizedBox(height: 3),
              Text('Organisez et collaborez efficacement',
                style: TextStyle(fontSize: 12, color: _muted)),
            ]),
            const Spacer(),

            // Bouton Collaboratif premium
            GestureDetector(
              onTap: onCreateCollab,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [rose, violet], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: rose.withOpacity(0.38), blurRadius: 14, offset: const Offset(0, 5))]),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 17),
                  SizedBox(width: 6),
                  Text('Collaboratif',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                ])),
            ),
          ]),
        ),

        // ── Stats row ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(children: [
            _StatPill(label: 'À faire', value: todoCnt, color: rose),
            const SizedBox(width: 10),
            _StatPill(label: 'Terminées', value: doneCnt, color: _green),
            const SizedBox(width: 10),
            _StatPill(label: 'Équipes', value: collabCount, color: violet),
          ]),
        ),

        // ── TabBar ───────────────────────────────────────────────────────
        TabBar(
          controller: tab,
          labelColor: rose,
          unselectedLabelColor: _muted,
          indicatorColor: rose,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: [
            Tab(text: 'Personnelles  $personalCount'),
            Tab(text: 'Collaboratives  $collabCount'),
          ],
        ),
      ]),
    );
  }
}

// ── Stat pill ─────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$value',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(width: 6),
      Text(label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color.withOpacity(0.7))),
    ]));
}

// ══════════════════════════════════════════════════════════════════════════
// COMPOSANTS PARTAGÉS
// ══════════════════════════════════════════════════════════════════════════

class _AddTaskBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;
  final Color rose;
  const _AddTaskBar({required this.controller, required this.onAdd, required this.rose});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
    child: Row(children: [
      Expanded(child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14, color: _ink),
        onSubmitted: (_) => onAdd(),
        decoration: InputDecoration(
          hintText: 'Nouvelle tâche...',
          hintStyle: const TextStyle(color: _muted, fontSize: 14),
          prefixIcon: Icon(Icons.add_task_rounded, size: 20, color: rose.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14)),
      )),
      Padding(
        padding: const EdgeInsets.all(7),
        child: GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [rose, rose.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: rose.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]),
            child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 19)))),
    ]),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color rose;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.rose, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: active ? rose : _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? rose : _border)),
      child: Center(child: Text(label,
        style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: active ? Colors.white : _slate)))));
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final Color rose;
  const _EmptyState({required this.icon, required this.title, required this.sub, required this.rose});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [rose.withOpacity(0.12), rose.withOpacity(0.04)]),
          shape: BoxShape.circle),
        child: Icon(icon, size: 36, color: rose.withOpacity(0.45))),
      const SizedBox(height: 18),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
      const SizedBox(height: 6),
      Text(sub, style: const TextStyle(fontSize: 13, color: _muted)),
    ]));
}

// ── Sliver helpers ──────────────────────────────────────────────────────
class _SliverSectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SliverSectionHeader({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
    sliver: SliverToBoxAdapter(child: Row(children: [
      Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Text('$count', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w800))),
    ])));
}

class _SliverTaskList extends StatelessWidget {
  final List<dynamic> tasks;
  final Color rose, violet;
  final Function(String) onToggle, onDelete;
  final Function(String, String) onRemind;
  const _SliverTaskList({
    required this.tasks, required this.rose, required this.violet,
    required this.onToggle, required this.onDelete, required this.onRemind,
  });

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    sliver: SliverList(delegate: SliverChildBuilderDelegate(
      (_, i) {
        final t = tasks[i];
        return _CollabTaskCard(
          key: ValueKey(t['id']),
          task: t, rose: rose, violet: violet,
          onToggle: () => onToggle(t['id'].toString()),
          onDelete: () => onDelete(t['id'].toString()),
          onRemind: () => onRemind(t['id'].toString(), t['title']),
        );
      },
      childCount: tasks.length,
    )));
}

// ══════════════════════════════════════════════════════════════════════════
// CARTE TÂCHE PERSONNELLE
// ══════════════════════════════════════════════════════════════════════════
class _PersonalTaskCard extends StatefulWidget {
  final dynamic task;
  final Color rose, violet;
  final VoidCallback onToggle, onDelete;
  const _PersonalTaskCard({
    super.key, required this.task, required this.rose, required this.violet,
    required this.onToggle, required this.onDelete,
  });
  @override State<_PersonalTaskCard> createState() => _PersonalTaskCardState();
}

class _PersonalTaskCardState extends State<_PersonalTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final done = widget.task['completedByMe'] == true;

    return GestureDetector(
      onTapDown: (_) => _anim.forward(),
      onTapUp: (_) => _anim.reverse(),
      onTapCancel: () => _anim.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: done ? _green.withOpacity(0.25) : _border,
              width: done ? 1.5 : 1),
            boxShadow: [BoxShadow(
              color: done
                ? _green.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
              blurRadius: 12, offset: const Offset(0, 4))]),
          child: Row(children: [

            // Check animé
            GestureDetector(
              onTap: widget.onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: 24, height: 24,
                decoration: BoxDecoration(
                  gradient: done ? LinearGradient(colors: [_green, const Color(0xFF16A34A)]) : null,
                  color: done ? null : Colors.transparent,
                  border: done ? null : Border.all(color: _border, width: 2),
                  borderRadius: BorderRadius.circular(7)),
                child: done
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                  : null)),

            const SizedBox(width: 14),

            Expanded(child: Text(
              widget.task['title'] ?? '',
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500,
                color: done ? _muted : _ink,
                decoration: done ? TextDecoration.lineThrough : null,
                decorationColor: _muted))),

            // Delete
            GestureDetector(
              onTap: () => _confirmDelete(context),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(9)),
                child: Icon(Icons.delete_outline_rounded, size: 16, color: _red.withOpacity(0.7)))),
          ]),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer ?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: const Text('Cette tâche sera supprimée définitivement.', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: _slate))),
          TextButton(onPressed: () { Navigator.pop(context); widget.onDelete(); },
            child: const Text('Supprimer', style: TextStyle(color: _red, fontWeight: FontWeight.w700))),
        ],
      ));
  }
}

// ══════════════════════════════════════════════════════════════════════════
// CARTE TÂCHE COLLABORATIVE
// ══════════════════════════════════════════════════════════════════════════
class _CollabTaskCard extends StatelessWidget {
  final dynamic task;
  final VoidCallback onToggle, onDelete, onRemind;
  final Color rose, violet;
  const _CollabTaskCard({
    super.key, required this.task, required this.onToggle, required this.onDelete,
    required this.onRemind, required this.rose, required this.violet,
  });

  Color get _statusColor {
    switch (task['status']) {
      case 'completed': return _green;
      case 'overdue':   return _red;
      default:          return _orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final done      = task['completedByMe'] == true;
    final isOverdue = task['status'] == 'overdue';
    final isDone    = task['status'] == 'completed';
    final members   = List<dynamic>.from(task['members'] ?? []);
    final progress  = (task['progress'] ?? 0.0).toDouble();
    final total     = task['totalMembers'] ?? 0;
    final completed = task['completedCount'] ?? 0;
    final dueDate   = task['dueDate'] != null ? DateTime.parse(task['dueDate']) : null;
    final pColor    = _priorityColor(task['priority']);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverdue
            ? _red.withOpacity(0.25)
            : isDone
              ? _green.withOpacity(0.2)
              : _border),
        boxShadow: [_softShadow(opacity: 0.05, blur: 14)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Bande de priorité top ───────────────────────────────────────
        Container(
          height: 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [pColor, pColor.withOpacity(0.3)]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)))),

        // ── Header ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Check
            GestureDetector(
              onTap: isDone ? null : onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 26, height: 26, margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  gradient: done ? LinearGradient(colors: [_green, const Color(0xFF16A34A)]) : null,
                  color: done ? null : Colors.transparent,
                  border: done ? null : Border.all(color: _statusColor, width: 2),
                  borderRadius: BorderRadius.circular(8)),
                child: done
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : null)),

            const SizedBox(width: 12),

            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task['title'] ?? '',
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: isDone ? _muted : _ink,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  decorationColor: _muted)),
              if ((task['description'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(task['description'],
                  style: const TextStyle(fontSize: 12, color: _muted),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ])),

            const SizedBox(width: 10),

            // Badge priorité
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: pColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
              child: Text(_priorityLabel(task['priority']),
                style: TextStyle(fontSize: 10, color: pColor, fontWeight: FontWeight.w800, letterSpacing: 0.3))),
          ]),
        ),

        const SizedBox(height: 14),

        // ── Progression ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Progression',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted)),
              const Spacer(),
              Text('$completed/$total terminé${completed > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor)),
            ]),
            const SizedBox(height: 7),
            Stack(children: [
              Container(height: 7, decoration: BoxDecoration(
                color: _border, borderRadius: BorderRadius.circular(10))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                height: 7,
                width: (progress.clamp(0.0, 1.0)) * (MediaQuery.of(context).size.width - 72),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: isDone
                    ? [_green, const Color(0xFF16A34A)]
                    : isOverdue
                      ? [_red, _orange]
                      : [rose, violet]),
                  borderRadius: BorderRadius.circular(10))),
            ]),
          ]),
        ),

        const SizedBox(height: 14),

        // ── Membres ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Membres',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted)),
            const SizedBox(height: 8),
            ...members.map((m) => _MemberRow(member: m, isOverdue: isOverdue, rose: rose)),
          ]),
        ),

        // ── Date limite ─────────────────────────────────────────────────
        if (dueDate != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isOverdue ? _red.withOpacity(0.08) : _slate.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calendar_today_rounded, size: 12,
                    color: isOverdue ? _red : _muted),
                  const SizedBox(width: 5),
                  Text('${dueDate.day}/${dueDate.month}/${dueDate.year}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w500,
                      color: isOverdue ? _red : _muted)),
                  if (isOverdue) ...[
                    const SizedBox(width: 6),
                    const Text('· EN RETARD',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _red, letterSpacing: 0.5)),
                  ],
                ])),
            ]),
          ),

        // ── Actions ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Row(children: [
            if (!isDone) ...[
              // Rappel
              Expanded(child: _ActionButton(
                label: 'Rappeler',
                icon: Icons.notifications_outlined,
                color: violet,
                onTap: onRemind,
                filled: false,
              )),
              const SizedBox(width: 8),
              // Toggle
              Expanded(child: _ActionButton(
                label: done ? 'Annuler' : 'Marquer fait',
                icon: done ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                color: done ? _slate : rose,
                onTap: onToggle,
                filled: true,
              )),
              const SizedBox(width: 8),
            ],
            // Delete
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.delete_outline_rounded, size: 18, color: _red.withOpacity(0.7)))),
          ]),
        ),
      ]),
    );
  }
}

// ── Ligne membre ──────────────────────────────────────────────────────────
class _MemberRow extends StatelessWidget {
  final dynamic member;
  final bool isOverdue;
  final Color rose;
  const _MemberRow({required this.member, required this.isOverdue, required this.rose});

  @override
  Widget build(BuildContext context) {
    final done = member['completed'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: rose.withOpacity(0.12),
          child: Text(
            (member['username'] ?? 'U')[0].toUpperCase(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: rose))),
        const SizedBox(width: 10),
        Expanded(child: Text(member['username'] ?? '',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _ink))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: done ? _green.withOpacity(0.1) : (isOverdue ? _red.withOpacity(0.1) : _orange.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(8)),
          child: Text(
            done ? 'Fait ✓' : (isOverdue ? 'En retard' : 'En attente'),
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: done ? _green : (isOverdue ? _red : _orange)))),
      ]));
  }
}

// ── Bouton action ─────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool filled;
  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap, required this.filled});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: filled ? null : Border.all(color: color.withOpacity(0.25))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 15, color: filled ? Colors.white : color),
        const SizedBox(width: 6),
        Text(label,
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: filled ? Colors.white : color)),
      ])));
}

// ── Priority chip (dialog) ─────────────────────────────────────────────────
class _PriorityChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _PriorityChip({required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.1) : _snow,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: selected ? color : _border, width: selected ? 1.5 : 1)),
      child: Center(child: Text(label,
        style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: selected ? color : _slate)))));
}

// ── Helpers globaux ────────────────────────────────────────────────────────
Color _priorityColor(String? p) {
  switch (p) {
    case 'high':   return _red;
    case 'medium': return _orange;
    default:       return _green;
  }
}

String _priorityLabel(String? p) {
  switch (p) {
    case 'high':   return 'Élevée';
    case 'medium': return 'Moyenne';
    default:       return 'Faible';
  }
}