import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _base  = 'http://localhost:5000';
const Color _rose   = Color(0xFFD63FBF);
const Color _violet = Color(0xFF7C3AED);
const Color _ink    = Color(0xFF0F0F1A);
const Color _slate  = Color(0xFF64748B);
const Color _snow   = Color(0xFFF8FAFC);
const Color _border = Color(0xFFEEEEF5); 
const Color _green  = Color(0xFF10B981);
const Color _orange = Color(0xFFF59E0B);
const Color _red    = Color(0xFFEF4444);

class TachesPage extends StatefulWidget {
  const TachesPage({super.key});
  @override State<TachesPage> createState() => _TachesPageState();
}

class _TachesPageState extends State<TachesPage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _personal = [];
  List<dynamic> _collab   = [];
  bool _loading = true;
  final _personalCtrl = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load(silent: true));
  }

  @override
  void dispose() { _tab.dispose(); _personalCtrl.dispose(); _timer?.cancel(); super.dispose(); }

  Future<String?> _tok() async { final p = await SharedPreferences.getInstance(); return p.getString('auth_token'); }
  Future<Map<String, String>> _headers() async => {'Authorization': 'Bearer ${await _tok()}', 'Content-Type': 'application/json'};

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$_base/api/tasks'), headers: await _headers());
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

  // ── Ajouter tache personnelle rapide ─────────────────────────────────────
  Future<void> _addPersonal() async {
    final title = _personalCtrl.text.trim();
    if (title.isEmpty) return;
    await http.post(Uri.parse('$_base/api/tasks'), headers: await _headers(),
      body: jsonEncode({'title': title, 'type': 'personal'}));
    _personalCtrl.clear();
    _load(silent: true);
  }

  // ── Completer / Decompleter ───────────────────────────────────────────────
  Future<void> _toggleComplete(String id) async {
    await http.post(Uri.parse('$_base/api/tasks/$id/complete'), headers: await _headers());
    _load(silent: true);
  }

  // ── Supprimer ─────────────────────────────────────────────────────────────
  Future<void> _delete(String id) async {
    await http.delete(Uri.parse('$_base/api/tasks/$id'), headers: await _headers());
    _load(silent: true);
  }

  // ── Envoyer rappel ────────────────────────────────────────────────────────
  Future<void> _remind(String id, String title) async {
    final res = await http.post(Uri.parse('$_base/api/tasks/$id/remind'), headers: await _headers());
    if (mounted) {
      final data = jsonDecode(res.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data['message'] ?? 'Rappel envoyé !'),
        backgroundColor: _violet,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  // ── Dialog nouvelle tache collaborative ──────────────────────────────────
  void _showCreateCollab() {
    final titleCtrl  = TextEditingController();
    final descCtrl   = TextEditingController();
    final membersCtrl = TextEditingController();
    DateTime? dueDate;
    String priority = 'medium';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [_rose, _violet]), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 22)),
              const SizedBox(width: 12),
              const Text('Nouvelle tâche collaborative', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _ink)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 20),

            // Titre
            _inputField(titleCtrl, 'Titre de la tâche *', Icons.task_alt_rounded),
            const SizedBox(height: 12),

            // Description
            _inputField(descCtrl, 'Description (optionnel)', Icons.description_outlined, lines: 3),
            const SizedBox(height: 12),

            // Membres
            _inputField(membersCtrl, 'Usernames des membres (séparés par virgule)', Icons.people_outline_rounded),
            Padding(padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text('Ex: alice, bob, charlie', style: TextStyle(fontSize: 11, color: _slate.withOpacity(0.6)))),
            const SizedBox(height: 12),

            // Date limite
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (_, child) => Theme(
                    data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: _rose)),
                    child: child!),
                );
                if (picked != null) setS(() => dueDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _snow, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dueDate != null ? _rose : _border)),
                child: Row(children: [
                  Icon(Icons.calendar_today_rounded, size: 18, color: dueDate != null ? _rose : _slate.withOpacity(0.5)),
                  const SizedBox(width: 10),
                  Text(
                    dueDate != null ? 'Limite : ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}' : 'Date limite (optionnel)',
                    style: TextStyle(fontSize: 13, color: dueDate != null ? _rose : _slate.withOpacity(0.5), fontWeight: dueDate != null ? FontWeight.w600 : FontWeight.w400)),
                  const Spacer(),
                  if (dueDate != null) GestureDetector(
                    onTap: () => setS(() => dueDate = null),
                    child: Icon(Icons.close_rounded, size: 16, color: _slate.withOpacity(0.5))),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // Priorité
            const Text('Priorité', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
            const SizedBox(height: 8),
            Row(children: ['low', 'medium', 'high'].map((p) {
              final colors = {'low': _green, 'medium': _orange, 'high': _red};
              final labels = {'low': 'Faible', 'medium': 'Moyenne', 'high': 'Élevée'};
              final sel = priority == p;
              return Expanded(child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setS(() => priority = p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? colors[p]!.withOpacity(0.1) : _snow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? colors[p]! : _border, width: sel ? 2 : 1)),
                    child: Center(child: Text(labels[p]!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? colors[p]! : _slate)))),
                )));
            }).toList()),
            const SizedBox(height: 20),

            // Boutons
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(foregroundColor: _slate, side: const BorderSide(color: _border),
                  padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.w500)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) return;
                  final members = membersCtrl.text.trim().isEmpty ? [] : membersCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                  Navigator.pop(ctx);
                  await http.post(Uri.parse('$_base/api/tasks'), headers: await _headers(),
                    body: jsonEncode({
                      'title':           titleCtrl.text.trim(),
                      'description':     descCtrl.text.trim(),
                      'type':            'collaborative',
                      'memberUsernames': members,
                      'dueDate':         dueDate?.toIso8601String(),
                      'priority':        priority,
                    }));
                  _load();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Tâche créée et membres notifiés ✅'),
                    backgroundColor: _green, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                },
                style: ElevatedButton.styleFrom(backgroundColor: _rose, foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Créer', style: TextStyle(fontWeight: FontWeight.w600)))),
            ]),
          ])),
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _snow,
      body: Column(children: [
        // ── Header ────────────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Mes Tâches', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
                Text('Organisez vos tâches personnelles et collaboratives', style: TextStyle(fontSize: 12, color: _slate.withOpacity(0.7))),
              ]),
              const Spacer(),
              GestureDetector(
                onTap: _showCreateCollab,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_rose, _violet]),
                    borderRadius: BorderRadius.circular(12)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Collaboratif', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]))),
            ]),
            const SizedBox(height: 16),
            TabBar(
              controller: _tab,
              labelColor: _rose, unselectedLabelColor: _slate,
              indicatorColor: _rose, indicatorWeight: 2,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(text: 'Personnelles  ${_personal.length}'),
                Tab(text: 'Collaboratives  ${_collab.length}'),
              ],
            ),
          ]),
        ),

        // ── Contenu ───────────────────────────────────────────────────────────
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: _rose))
          : TabBarView(controller: _tab, children: [
              _buildPersonalTab(),
              _buildCollabTab(),
            ])),
      ]),
    );
  }

  // ── Tab Personnelles ──────────────────────────────────────────────────────
  Widget _buildPersonalTab() {
    return RefreshIndicator(
      onRefresh: _load, color: _rose,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Champ ajout rapide
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
            child: Row(children: [
              Expanded(child: TextField(
                controller: _personalCtrl,
                style: const TextStyle(fontSize: 13),
                onSubmitted: (_) => _addPersonal(),
                decoration: InputDecoration(
                  hintText: 'Ajouter une tâche personnelle...',
                  hintStyle: TextStyle(color: _slate.withOpacity(0.5), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13)),
              )),
              GestureDetector(
                onTap: _addPersonal,
                child: Container(margin: const EdgeInsets.all(6), width: 36, height: 36,
                  decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 20))),
            ]),
          ),
          const SizedBox(height: 16),
          if (_personal.isEmpty)
            _buildEmpty('Aucune tâche personnelle', 'Ajoutez une tâche ci-dessus', Icons.task_alt_rounded)
          else
            ..._personal.map((t) => _PersonalTaskCard(
              task: t,
              onToggle: () => _toggleComplete(t['id'].toString()),
              onDelete: () => _delete(t['id'].toString()),
            )),
        ]),
      ),
    );
  }

  // ── Tab Collaboratives ────────────────────────────────────────────────────
  Widget _buildCollabTab() {
    final active   = _collab.where((t) => t['status'] == 'active').toList();
    final overdue  = _collab.where((t) => t['status'] == 'overdue').toList();
    final done     = _collab.where((t) => t['status'] == 'completed').toList();

    return RefreshIndicator(
      onRefresh: _load, color: _rose,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_collab.isEmpty) _buildEmpty('Aucune tâche collaborative', 'Créez une tâche et invitez vos amis !', Icons.group_outlined),

          if (overdue.isNotEmpty) ...[
            _sectionLabel('🔴 En retard', overdue.length, _red),
            const SizedBox(height: 8),
            ...overdue.map((t) => _CollabTaskCard(task: t, onToggle: () => _toggleComplete(t['id'].toString()), onDelete: () => _delete(t['id'].toString()), onRemind: () => _remind(t['id'].toString(), t['title']))),
            const SizedBox(height: 16),
          ],

          if (active.isNotEmpty) ...[
            _sectionLabel('⚡ En cours', active.length, _orange),
            const SizedBox(height: 8),
            ...active.map((t) => _CollabTaskCard(task: t, onToggle: () => _toggleComplete(t['id'].toString()), onDelete: () => _delete(t['id'].toString()), onRemind: () => _remind(t['id'].toString(), t['title']))),
            const SizedBox(height: 16),
          ],

          if (done.isNotEmpty) ...[
            _sectionLabel('✅ Terminées', done.length, _green),
            const SizedBox(height: 8),
            ...done.map((t) => _CollabTaskCard(task: t, onToggle: () => _toggleComplete(t['id'].toString()), onDelete: () => _delete(t['id'].toString()), onRemind: () => _remind(t['id'].toString(), t['title']))),
          ],
        ]),
      ),
    );
  }

  Widget _sectionLabel(String label, int count, Color color) => Row(children: [
    Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
    const SizedBox(width: 8),
    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text('$count', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700))),
  ]);

  Widget _buildEmpty(String title, String sub, IconData icon) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: _rose.withOpacity(0.07), shape: BoxShape.circle),
        child: Icon(icon, size: 40, color: _rose.withOpacity(0.4))),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
      const SizedBox(height: 6),
      Text(sub, style: TextStyle(fontSize: 13, color: _slate.withOpacity(0.6)), textAlign: TextAlign.center),
    ]),
  );

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon, {int lines = 1}) =>
    TextField(controller: ctrl, maxLines: lines, style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: _slate.withOpacity(0.4), fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: _slate.withOpacity(0.5)),
        filled: true, fillColor: _snow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _rose, width: 2))));
}

// ════════════════════════════════════════════════════════════════════════════
// CARTE TACHE PERSONNELLE
// ════════════════════════════════════════════════════════════════════════════
class _PersonalTaskCard extends StatelessWidget {
  final dynamic task;
  final VoidCallback onToggle, onDelete;
  const _PersonalTaskCard({required this.task, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final done = task['completedByMe'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: done ? _green.withOpacity(0.3) : _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Row(children: [
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: done ? _green : Colors.transparent,
              border: Border.all(color: done ? _green : _border, width: 2),
              borderRadius: BorderRadius.circular(6)),
            child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null)),
        const SizedBox(width: 12),
        Expanded(child: Text(task['title'] ?? '',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: done ? _slate : _ink,
            decoration: done ? TextDecoration.lineThrough : null))),
        GestureDetector(onTap: onDelete,
          child: Icon(Icons.delete_outline_rounded, size: 18, color: _red.withOpacity(0.6))),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CARTE TACHE COLLABORATIVE
// ════════════════════════════════════════════════════════════════════════════
class _CollabTaskCard extends StatelessWidget {
  final dynamic task;
  final VoidCallback onToggle, onDelete, onRemind;
  const _CollabTaskCard({required this.task, required this.onToggle, required this.onDelete, required this.onRemind});

  Color get _statusColor {
    switch (task['status']) {
      case 'completed': return _green;
      case 'overdue':   return _red;
      default:          return _orange;
    }
  }

  Color get _priorityColor {
    switch (task['priority']) {
      case 'high':   return _red;
      case 'medium': return _orange;
      default:       return _green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final done     = task['completedByMe'] == true;
    final members  = List<dynamic>.from(task['members'] ?? []);
    final progress = (task['progress'] ?? 0.0).toDouble();
    final total    = task['totalMembers'] ?? 0;
    final completed = task['completedCount'] ?? 0;
    final dueDate  = task['dueDate'] != null ? DateTime.parse(task['dueDate']) : null;
    final isOverdue = task['status'] == 'overdue';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isOverdue ? _red.withOpacity(0.3) : done ? _green.withOpacity(0.3) : _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            // Checkbox
            GestureDetector(
              onTap: task['status'] != 'completed' ? onToggle : null,
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: done ? _green : Colors.transparent,
                  border: Border.all(color: done ? _green : _statusColor, width: 2),
                  borderRadius: BorderRadius.circular(7)),
                child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 15) : null)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task['title'] ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: task['status'] == 'completed' ? _slate : _ink,
                decoration: task['status'] == 'completed' ? TextDecoration.lineThrough : null)),
              if ((task['description'] ?? '').isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 3),
                  child: Text(task['description'], style: TextStyle(fontSize: 12, color: _slate.withOpacity(0.7)), maxLines: 2, overflow: TextOverflow.ellipsis)),
            ])),
            // Priorité badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _priorityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(_priorityLabel(task['priority']),
                style: TextStyle(fontSize: 10, color: _priorityColor, fontWeight: FontWeight.w700))),
          ]),
        ),

        const SizedBox(height: 12),

        // ── Barre de progression ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Progression', style: TextStyle(fontSize: 11, color: _slate.withOpacity(0.7), fontWeight: FontWeight.w500)),
              const Spacer(),
              Text('$completed / $total', style: TextStyle(fontSize: 11, color: _statusColor, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress, minHeight: 7,
                backgroundColor: _border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  task['status'] == 'completed' ? _green : isOverdue ? _red : _rose))),
          ]),
        ),

        const SizedBox(height: 12),

        // ── Membres ───────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Membres', style: TextStyle(fontSize: 11, color: _slate.withOpacity(0.7), fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ...members.map((m) {
              final memberDone = m['completed'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  CircleAvatar(radius: 14, backgroundColor: _rose.withOpacity(0.12),
                    child: Text((m['username'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _rose))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(m['username'] ?? '',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                  if (memberDone)
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Text('✅ Fait', style: TextStyle(fontSize: 10, color: _green, fontWeight: FontWeight.w600)))
                  else
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(isOverdue ? '🔴 En retard' : '⏳ En attente',
                        style: TextStyle(fontSize: 10, color: isOverdue ? _red : _orange, fontWeight: FontWeight.w600))),
                ]));
            }),
          ]),
        ),

        // ── Date limite ───────────────────────────────────────────────────────
        if (dueDate != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              Icon(Icons.calendar_today_rounded, size: 13, color: isOverdue ? _red : _slate.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text('Limite : ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                style: TextStyle(fontSize: 12, color: isOverdue ? _red : _slate.withOpacity(0.7), fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w400)),
              if (isOverdue) ...[
                const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: _red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: const Text('EN RETARD', style: TextStyle(fontSize: 9, color: _red, fontWeight: FontWeight.w800))),
              ],
            ]),
          ),

        // ── Actions ───────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(children: [
            // Rappel
            if (task['status'] != 'completed')
              Expanded(child: OutlinedButton.icon(
                onPressed: onRemind,
                icon: const Icon(Icons.notifications_rounded, size: 15),
                label: const Text('Rappeler', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                style: OutlinedButton.styleFrom(foregroundColor: _violet, side: BorderSide(color: _violet.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
            if (task['status'] != 'completed') const SizedBox(width: 8),
            // Mon statut
            if (task['status'] != 'completed')
              Expanded(child: ElevatedButton.icon(
                onPressed: onToggle,
                icon: Icon(done ? Icons.undo_rounded : Icons.check_rounded, size: 15),
                label: Text(done ? 'Annuler' : 'Marquer fait', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: done ? _slate.withOpacity(0.1) : _rose,
                  foregroundColor: done ? _slate : Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
            const SizedBox(width: 8),
            // Supprimer
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, color: _red, size: 18),
              style: IconButton.styleFrom(backgroundColor: _red.withOpacity(0.08), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
          ]),
        ),
      ]),
    );
  }

  String _priorityLabel(String? p) {
    switch (p) { case 'high': return '🔴 Élevée'; case 'medium': return '🟡 Moyenne'; default: return '🟢 Faible'; }
  }
}