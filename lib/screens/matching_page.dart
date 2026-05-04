// lib/pages/matching_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wejoy/theme/theme_provider.dart';
import 'dart:convert';
import 'dart:math' as math;

import 'profile_matching_page.dart';

const String _baseUrl = 'http://localhost:5000';

// ── Couleurs statiques (non thématiques) ─────────────────────────────────
const Color _bg          = Color(0xFFFDF4FB);
const Color _surface     = Color(0xFFFFFFFF);
const Color _pinkLight   = Color(0xFFFCE4F5);
const Color _purpleLight = Color(0xFFF3E8FF);
const Color _ink         = Color(0xFF2D1B3D);
const Color _muted       = Color(0xFFAA8CBF);
const Color _divider     = Color(0xFFF0E6F8);
const Color _success     = Color(0xFF27AE60);

// ═══════════════════════════════════════════════════════════════════════════
// MODÈLE
// ═══════════════════════════════════════════════════════════════════════════
class MatchProfile {
  final String       id;
  final String       username;
  final String?      avatarUrl;
  final int?         age;
  final int          score;
  final List<String> interests;
  final List<String> commonInterests;
  final List<String> commonAvailabilities;

  const MatchProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.age,
    required this.score,
    required this.interests,
    required this.commonInterests,
    required this.commonAvailabilities,
  });

  factory MatchProfile.fromJson(Map<String, dynamic> j) => MatchProfile(
    id:                   j['_id']?.toString() ?? '',
    username:             j['username']?.toString() ?? '',
    avatarUrl:            j['avatarUrl'] as String?,
    age:                  j['age'] as int?,
    score:                (j['score'] as num?)?.toInt() ?? 0,
    interests:            List<String>.from(j['interests'] ?? []),
    commonInterests:      List<String>.from(j['commonInterests'] ?? []),
    commonAvailabilities: List<String>.from(j['commonAvailabilities'] ?? []),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// PAGE MATCHING
// ═══════════════════════════════════════════════════════════════════════════
class MatchingPage extends StatefulWidget {
  const MatchingPage({super.key});
  @override
  State<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage>
    with SingleTickerProviderStateMixin {

  // ── Accesseurs thème dynamique ─────────────────────────────────────────
  Color get _rose   => context.read<ThemeProvider>().color1;
  Color get _violet => context.read<ThemeProvider>().color2;

  List<MatchProfile> _matches  = [];
  List<MatchProfile> _filtered = [];
  bool   _loading  = true;
  String _error    = '';
  String _search   = '';
  int    _minScore = 0;

  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _fetch();
  }

  @override
  void dispose() { _shimmerCtrl.dispose(); super.dispose(); }

  Future<String?> _tok() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('auth_token');
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/users/matches'),
        headers: {'Authorization': 'Bearer ${await _tok()}'},
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() {
          _matches = list.map((j) =>
            MatchProfile.fromJson(j as Map<String, dynamic>)).toList();
          _applyFilters();
        });
      } else {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() => _error = body['message']?.toString() ?? 'Erreur serveur');
      }
    } catch (_) {
      setState(() => _error = 'Connexion impossible');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filtered = _matches.where((m) {
        final matchSearch = _search.isEmpty ||
          m.username.toLowerCase().contains(_search.toLowerCase());
        return matchSearch && m.score >= _minScore;
      }).toList();
    });
  }

  Future<void> _goToProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProfileMatchingPage()));
    if (result == true) _fetch();
  }

  // ════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // On écoute les changements de thème pour rebuilder toute la page
    final rose   = context.watch<ThemeProvider>().color1;
    final violet = context.watch<ThemeProvider>().color2;

    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _fetch,
        backgroundColor: rose,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18)),
        child: _loading
          ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.refresh_rounded, color: Colors.white),
      ),
      body: CustomScrollView(slivers: [

        // ── AppBar WeJoy ─────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: _pinkLight,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(
                    color: rose.withOpacity(0.1),
                    blurRadius: 8, offset: const Offset(0, 2))]),
                child: Icon(Icons.arrow_back_rounded,
                  color: rose, size: 20)))),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              child: GestureDetector(
                onTap: _goToProfile,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                      color: rose.withOpacity(0.1),
                      blurRadius: 8, offset: const Offset(0, 2))]),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.tune_rounded, color: rose, size: 16),
                    const SizedBox(width: 6),
                    Text('Mon profil',
                      style: TextStyle(
                        color: rose, fontSize: 12,
                        fontWeight: FontWeight.w700)),
                  ])))),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _MatchingAppBar(
              loading: _loading,
              error:   _error,
              count:   _filtered.length,
              rose:    rose,
              violet:  violet,
            ),
          ),
        ),

        // ── Barre recherche + filtre score ───────────────────────────
        if (!_loading && _error.isEmpty)
          SliverToBoxAdapter(child: Container(
            color: _bg,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Column(children: [
              Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _divider, width: 1.2),
                  boxShadow: [BoxShadow(
                    color: rose.withOpacity(0.05),
                    blurRadius: 12, offset: const Offset(0, 4))]),
                child: TextField(
                  onChanged: (v) { _search = v; _applyFilters(); },
                  style: const TextStyle(
                    fontSize: 13, color: _ink, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un profil...',
                    hintStyle: TextStyle(
                      color: _muted.withOpacity(0.6), fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded,
                      color: _muted.withOpacity(0.6), size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14)),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _divider, width: 1.2)),
                child: Row(children: [
                  const Text('💜', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text('Score min. ',
                    style: TextStyle(
                      fontSize: 12, color: _muted.withOpacity(0.8),
                      fontWeight: FontWeight.w500)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _pinkLight,
                      borderRadius: BorderRadius.circular(10)),
                    child: Text('$_minScore%',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800,
                        color: rose))),
                  Expanded(child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor:   rose,
                      inactiveTrackColor: _divider,
                      thumbColor:         rose,
                      overlayColor:       rose.withOpacity(0.1),
                      trackHeight:        3.5,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 9)),
                    child: Slider(
                      value:     _minScore.toDouble(),
                      min:       0,
                      max:       100,
                      divisions: 10,
                      onChanged: (v) {
                        setState(() => _minScore = v.round());
                        _applyFilters();
                      }),
                  )),
                  Text('100%',
                    style: TextStyle(
                      fontSize: 10, color: _muted.withOpacity(0.5))),
                ]),
              ),
            ]),
          )),

        // ── Contenu principal ────────────────────────────────────────
        if (_loading)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (_, i) => _ShimmerCard(ctrl: _shimmerCtrl),
              childCount: 4)))

        else if (_error.isNotEmpty)
          SliverFillRemaining(child: _ErrorState(
            message:  _error,
            onAction: _goToProfile,
            rose:     rose,
            violet:   violet))

        else if (_filtered.isEmpty)
          SliverFillRemaining(child: _EmptyState(
            hasFilters: _search.isNotEmpty || _minScore > 0,
            onReset: () {
              setState(() { _search = ''; _minScore = 0; });
              _applyFilters();
            },
            onProfile: _goToProfile,
            rose:    rose,
            violet:  violet))

        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 80),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (_, i) => _MatchCard(
                profile: _filtered[i],
                index:   i,
                rose:    rose,
                violet:  violet),
              childCount: _filtered.length))),

      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// APP BAR MATCHING WEJOY
// ═══════════════════════════════════════════════════════════════════════════
class _MatchingAppBar extends StatelessWidget {
  final bool   loading;
  final String error;
  final int    count;
  final Color  rose;
  final Color  violet;
  const _MatchingAppBar({
    required this.loading,
    required this.error,
    required this.count,
    required this.rose,
    required this.violet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [rose.withOpacity(0.18), violet.withOpacity(0.12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight)),
      child: Stack(children: [
        Positioned(right: -20, top: -20,
          child: _Bubble(size: 130, color: rose.withOpacity(0.08))),
        Positioned(right: 60, bottom: 10,
          child: _Bubble(size: 70, color: violet.withOpacity(0.1))),
        Positioned(left: -10, bottom: -10,
          child: _Bubble(size: 100, color: rose.withOpacity(0.06))),
        const Positioned(right: 30, top: 60,
          child: Text('💜', style: TextStyle(fontSize: 14))),
        const Positioned(right: 90, top: 30,
          child: Text('✨', style: TextStyle(fontSize: 18))),
        const Positioned(left: 50, bottom: 30,
          child: Text('🌸', style: TextStyle(fontSize: 14))),
        SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: rose.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: rose.withOpacity(0.25))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('💜', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 5),
                Text('WeJoy · Compatibilité',
                  style: TextStyle(
                    color: rose, fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 0.4)),
              ])),
            const SizedBox(height: 10),
            const Text('Personnes\ncompatibles 🌸',
              style: TextStyle(
                color: _ink, fontSize: 24,
                fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20)),
              child: Text(
                loading
                  ? '🔍 Recherche en cours...'
                  : error.isNotEmpty
                    ? '⚠️ Complétez votre profil'
                    : '🎉 $count personne(s) trouvée(s)',
                style: const TextStyle(
                  fontSize: 12, color: _ink,
                  fontWeight: FontWeight.w600))),
          ]))),
      ]));
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  final Color  color;
  const _Bubble({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

// ═══════════════════════════════════════════════════════════════════════════
// CARTE PROFIL
// ═══════════════════════════════════════════════════════════════════════════
class _MatchCard extends StatefulWidget {
  final MatchProfile profile;
  final int          index;
  final Color        rose;
  final Color        violet;
  const _MatchCard({
    required this.profile,
    required this.index,
    required this.rose,
    required this.violet,
  });
  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _slide;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 380 + widget.index * 55));
    _slide = Tween(begin: 36.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(
      Duration(milliseconds: widget.index * 55), () {
        if (mounted) _ctrl.forward();
      });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  List<String> _grouped(List<String> avails) {
    final map = <String, List<String>>{};
    for (final a in avails) {
      final idx  = a.indexOf(' ');
      if (idx < 0) continue;
      final day  = a.substring(0, idx);
      final slot = a.substring(idx + 1);
      map.putIfAbsent(day, () => []).add(slot);
    }
    return map.entries
      .map((e) => '${e.key} (${e.value.join(', ')})')
      .toList();
  }

  Color _scoreColor(int s) {
    if (s >= 80) return const Color(0xFF27AE60);
    if (s >= 60) return widget.rose;
    if (s >= 40) return const Color(0xFFF39C12);
    return _muted;
  }

  String _scoreLabel(int s) {
    if (s >= 80) return '⭐ Très compatible';
    if (s >= 60) return '💜 Compatible';
    if (s >= 40) return '🤝 Quelques points communs';
    return '🔍 Peu de points communs';
  }

  @override
  Widget build(BuildContext context) {
    final p    = widget.profile;
    final rose   = widget.rose;
    final violet = widget.violet;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _slide.value),
        child: Opacity(opacity: _fade.value, child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _divider, width: 1.2),
          boxShadow: [BoxShadow(
            color: rose.withOpacity(0.06),
            blurRadius: 16, offset: const Offset(0, 6))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [

          // ── Header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(children: [
              _AvatarWidget(username: p.username, size: 52, rose: rose, violet: violet),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.username,
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: _ink)),
                const SizedBox(height: 5),
                Row(children: [
                  if (p.age != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _purpleLight,
                        borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisSize: MainAxisSize.min,
                        children: [
                        const Text('🎂',
                          style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text('${p.age} ans',
                          style: TextStyle(
                            fontSize: 11, color: violet,
                            fontWeight: FontWeight.w600)),
                      ])),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _pinkLight,
                      borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('✨',
                        style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 4),
                      Text('${p.interests.length} intérêt(s)',
                        style: TextStyle(
                          fontSize: 11, color: rose,
                          fontWeight: FontWeight.w600)),
                    ])),
                ]),
              ])),
              _ScoreRing(score: p.score, rose: rose, violet: violet),
            ]),
          ),

          Divider(height: 1, color: _divider),

          // ── Badges communs ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [

              if (p.commonInterests.isNotEmpty) ...[
                _BadgeRow(
                  icon:      Icons.favorite_rounded,
                  color:     rose,
                  bgColor:   _pinkLight,
                  label:     '${p.commonInterests.length} intérêt(s) en commun',
                  chips:     p.commonInterests,
                  chipColor: rose),
                const SizedBox(height: 12),
              ],

              if (p.commonAvailabilities.isNotEmpty)
                _BadgeRow(
                  icon:      Icons.schedule_rounded,
                  color:     violet,
                  bgColor:   _purpleLight,
                  label:     '${p.commonAvailabilities.length} créneau(x) commun(s)',
                  chips:     _grouped(p.commonAvailabilities),
                  chipColor: violet),

              if (p.commonInterests.isEmpty &&
                  p.commonAvailabilities.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Text('🔍',
                      style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    Text('Des points communs à découvrir',
                      style: TextStyle(
                        fontSize: 12,
                        color: _muted.withOpacity(0.8),
                        fontWeight: FontWeight.w500)),
                  ])),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Footer ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _scoreColor(p.score).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _scoreColor(p.score).withOpacity(0.25))),
                child: Text(_scoreLabel(p.score),
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: _scoreColor(p.score)))),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [rose, violet],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight),
                    borderRadius: BorderRadius.circular(14)),
                  child: const Row(mainAxisSize: MainAxisSize.min,
                    children: [
                    Icon(Icons.person_add_outlined,
                      color: Colors.white, size: 15),
                    SizedBox(width: 6),
                    Text('Contacter',
                      style: TextStyle(
                        color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w700)),
                  ]))),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BADGE ROW
// ═══════════════════════════════════════════════════════════════════════════
class _BadgeRow extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final Color        bgColor;
  final String       label;
  final List<String> chips;
  final Color        chipColor;
  const _BadgeRow({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.label,
    required this.chips,
    required this.chipColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 12, color: color)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: chips.map((c) =>
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: chipColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: chipColor.withOpacity(0.25))),
          child: Text(c, style: TextStyle(
            fontSize: 11, color: chipColor,
            fontWeight: FontWeight.w600)),
        )).toList()),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANNEAU DE SCORE
// ═══════════════════════════════════════════════════════════════════════════
class _ScoreRing extends StatefulWidget {
  final int   score;
  final Color rose;
  final Color violet;
  const _ScoreRing({required this.score, required this.rose, required this.violet});
  @override
  State<_ScoreRing> createState() => _ScoreRingState();
}

class _ScoreRingState extends State<_ScoreRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween(begin: 0.0, end: widget.score / 100.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        width: 62, height: 62,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(
            size: const Size(62, 62),
            painter: _RingPainter(
              progress: _anim.value,
              rose:     widget.rose,
              violet:   widget.violet)),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              '${(widget.score * _anim.value).round()}%',
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800,
                color: _ink)),
          ]),
        ]),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color  rose;
  final Color  violet;
  const _RingPainter({
    required this.progress,
    required this.rose,
    required this.violet,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final r  = size.width  / 2 - 5;

    canvas.drawCircle(Offset(cx, cy), r,
      Paint()
        ..color       = const Color(0xFFF0E6F8)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 5);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..shader = LinearGradient(colors: [rose, violet])
            .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap   = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
    old.progress != progress || old.rose != rose || old.violet != violet;
}

// ═══════════════════════════════════════════════════════════════════════════
// AVATAR
// ═══════════════════════════════════════════════════════════════════════════
class _AvatarWidget extends StatelessWidget {
  final String username;
  final double size;
  final Color  rose;
  final Color  violet;
  const _AvatarWidget({
    required this.username,
    required this.size,
    required this.rose,
    required this.violet,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [rose, violet],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(size * 0.35),
      boxShadow: [BoxShadow(
        color: rose.withOpacity(0.25),
        blurRadius: 10, offset: const Offset(0, 4))]),
    child: Center(child: Text(
      username.isNotEmpty ? username[0].toUpperCase() : 'U',
      style: TextStyle(
        color: Colors.white,
        fontSize: size * 0.38,
        fontWeight: FontWeight.w800))));
}

// ═══════════════════════════════════════════════════════════════════════════
// ÉTAT VIDE
// ═══════════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final bool         hasFilters;
  final VoidCallback onReset;
  final VoidCallback onProfile;
  final Color        rose;
  final Color        violet;
  const _EmptyState({
    required this.hasFilters,
    required this.onReset,
    required this.onProfile,
    required this.rose,
    required this.violet,
  });

  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: _pinkLight, shape: BoxShape.circle),
        child: Center(child: Text(
          hasFilters ? '🔍' : '👥',
          style: const TextStyle(fontSize: 34)))),
      const SizedBox(height: 20),
      Text(
        hasFilters
          ? 'Aucun résultat'
          : 'Aucune suggestion pour l\'instant',
        style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.w800, color: _ink),
        textAlign: TextAlign.center),
      const SizedBox(height: 10),
      Text(
        hasFilters
          ? 'Élargissez vos critères de filtrage.'
          : 'Enrichissez votre profil pour apparaître dans les suggestions.',
        style: TextStyle(
          fontSize: 13, color: _muted.withOpacity(0.8), height: 1.6),
        textAlign: TextAlign.center),
      const SizedBox(height: 28),
      hasFilters
        ? GestureDetector(
            onTap: onReset,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 13),
              decoration: BoxDecoration(
                color: _pinkLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: rose.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.refresh_rounded, color: rose, size: 16),
                const SizedBox(width: 8),
                Text('Réinitialiser les filtres',
                  style: TextStyle(
                    color: rose, fontSize: 13,
                    fontWeight: FontWeight.w700)),
              ])))
        : GestureDetector(
            onTap: onProfile,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [rose, violet]),
                borderRadius: BorderRadius.circular(18)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit_rounded,
                  color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('💜  Compléter mon profil',
                  style: TextStyle(
                    color: Colors.white, fontSize: 13,
                    fontWeight: FontWeight.w700)),
              ]))),
    ]),
  ));
}

// ═══════════════════════════════════════════════════════════════════════════
// ÉTAT ERREUR
// ═══════════════════════════════════════════════════════════════════════════
class _ErrorState extends StatelessWidget {
  final String       message;
  final VoidCallback onAction;
  final Color        rose;
  final Color        violet;
  const _ErrorState({
    required this.message,
    required this.onAction,
    required this.rose,
    required this.violet,
  });

  @override
  Widget build(BuildContext context) {
    final isIncomplete = message.toLowerCase().contains('profil') ||
                         message.toLowerCase().contains('complet');
    return Center(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: _purpleLight, shape: BoxShape.circle),
          child: const Center(
            child: Text('🔒', style: TextStyle(fontSize: 34)))),
        const SizedBox(height: 20),
        const Text('Profil incomplet',
          style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w800, color: _ink),
          textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(
          isIncomplete
            ? 'Renseignez vos intérêts, disponibilités et localisation '
              'pour accéder aux suggestions.'
            : message,
          style: TextStyle(
            fontSize: 13, color: _muted.withOpacity(0.8), height: 1.6),
          textAlign: TextAlign.center),
        const SizedBox(height: 16),
        if (isIncomplete) ...[
          ...[
            ('✨', 'Intérêts sélectionnés'),
            ('🎂', 'Année de naissance'),
            ('📅', 'Disponibilités'),
            ('📍', 'Localisation GPS'),
          ].map(((String, String) item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _divider)),
            child: Row(children: [
              Text(item.$1, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 10),
              Text(item.$2, style: TextStyle(
                fontSize: 13, color: _muted.withOpacity(0.8),
                fontWeight: FontWeight.w500)),
              const Spacer(),
              Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  color: _pinkLight,
                  borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.close_rounded,
                  color: rose, size: 11)),
            ]))),
          const SizedBox(height: 16),
        ],
        GestureDetector(
          onTap: onAction,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [rose, violet]),
              borderRadius: BorderRadius.circular(18)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Icon(Icons.edit_rounded,
                color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('💜  Compléter mon profil',
                style: TextStyle(
                  color: Colors.white, fontSize: 14,
                  fontWeight: FontWeight.w700)),
            ]))),
      ]),
    ));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SKELETON SHIMMER
// ═══════════════════════════════════════════════════════════════════════════
class _ShimmerCard extends StatelessWidget {
  final AnimationController ctrl;
  const _ShimmerCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = (math.sin(ctrl.value * math.pi)).abs();
        final color = Color.lerp(
          const Color(0xFFF0E6F8),
          const Color(0xFFFDF4FB), t)!;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _divider, width: 1.2),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12, offset: const Offset(0, 4))]),
          child: Column(children: [
            Row(children: [
              _box(52, 52, color, r: 18),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                _box(14, 130, color),
                const SizedBox(height: 8),
                Row(children: [
                  _box(24, 70, color, r: 10),
                  const SizedBox(width: 6),
                  _box(24, 80, color, r: 10),
                ]),
              ])),
              _box(62, 62, color, r: 31),
            ]),
            const SizedBox(height: 14),
            _box(11, double.infinity, color),
            const SizedBox(height: 8),
            Row(children: [
              _box(28, 95, color, r: 14),
              const SizedBox(width: 8),
              _box(28, 115, color, r: 14),
              const SizedBox(width: 8),
              _box(28, 80, color, r: 14),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _box(32, 140, color, r: 10),
              const Spacer(),
              _box(38, 110, color, r: 14),
            ]),
          ]),
        );
      },
    );
  }

  Widget _box(double h, double w, Color c, {double r = 6}) => Container(
    height: h,
    width: w == double.infinity ? double.infinity : w,
    decoration: BoxDecoration(
      color: c, borderRadius: BorderRadius.circular(r)));
}