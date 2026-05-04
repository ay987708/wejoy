// lib/pages/profile_matching_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wejoy/screens/service/location_service.dart';
import 'dart:convert';
import 'dart:math' as math;

import 'package:wejoy/theme/theme_provider.dart';

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
const Color _errCol      = Color(0xFFE74C3C);

// ── Classe utilitaire pour les intérêts ───────────────────────────────────
class _InterestOption {
  final String label;
  final String emoji;
  final Color  color;
  const _InterestOption(this.label, this.emoji, this.color);
}

// ═══════════════════════════════════════════════════════════════════════════
class ProfileMatchingPage extends StatefulWidget {
  const ProfileMatchingPage({super.key});
  @override
  State<ProfileMatchingPage> createState() => _ProfileMatchingPageState();
}

class _ProfileMatchingPageState extends State<ProfileMatchingPage>
    with TickerProviderStateMixin {

  // ── Accesseurs thème dynamique ─────────────────────────────────────────
  Color get _rose   => context.read<ThemeProvider>().color1;
  Color get _violet => context.read<ThemeProvider>().color2;

  final List<String> _interests      = [];
  final List<String> _availabilities = [];
  int    _birthYear      = DateTime.now().year - 30;
  double _searchRadius   = 10;
  bool   _loading        = false;
  bool   _saving         = false;
  bool   _locationSynced = false;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  static const _daysF  = ['Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi','Dimanche'];
  static const _daysS  = ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'];
  static const _slots  = ['matin', 'après-midi', 'soir'];
  static const _slotsL = ['Matin', 'Aprèm', 'Soir'];

  static final _interestOptions = [
    _InterestOption('Cuisine',      '🍳', const Color(0xFFFF6B6B)),
    _InterestOption('Lecture',      '📚', const Color(0xFF74B9FF)),
    _InterestOption('Jardinage',    '🌱', const Color(0xFF55EFC4)),
    _InterestOption('Yoga',         '🧘', const Color(0xFFA29BFE)),
    _InterestOption('Sport',        '⚽', const Color(0xFF6C5CE7)),
    _InterestOption('Photographie', '📷', const Color(0xFFFDCB6E)),
    _InterestOption('Musique',      '🎵', const Color(0xFFE84393)),
    _InterestOption('Voyage',       '✈️', const Color(0xFF00CEC9)),
    _InterestOption('Art',          '🎨', const Color(0xFFFF7675)),
    _InterestOption('Autre',        '✨', const Color(0xFF9B59B6)),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _loadExistingProfile();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Future<String?> _tok() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('auth_token');
  }

  Future<void> _loadExistingProfile() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/users/me'),
        headers: {'Authorization': 'Bearer ${await _tok()}'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          if (data['interests'] != null)
            _interests..clear()..addAll(List<String>.from(data['interests']));
          if (data['availabilities'] != null)
            _availabilities..clear()..addAll(List<String>.from(data['availabilities']));
          if (data['birthYear'] != null)
            _birthYear = (data['birthYear'] as num).toInt();
          if (data['searchRadius'] != null)
            _searchRadius = (data['searchRadius'] as num).toDouble();
          final coords = data['location']?['coordinates'];
          if (coords is List && coords.length == 2 && coords[0] != 0)
            _locationSynced = true;
        });
      }
    } catch (e) { debugPrint('$e'); }
    finally { setState(() => _loading = false); }
  }

  Future<void> _save() async {
    if (_interests.isEmpty) {
      _toast('Sélectionnez au moins un intérêt 💜', false); return;
    }
    if (_availabilities.isEmpty) {
      _toast('Sélectionnez au moins une disponibilité 🌸', false); return;
    }
    setState(() => _saving = true);
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/api/users/profile/matching'),
        headers: {
          'Authorization': 'Bearer ${await _tok()}',
          'Content-Type':  'application/json',
        },
        body: jsonEncode({
          'interests':      _interests,
          'availabilities': _availabilities,
          'birthYear':      _birthYear,
          'searchRadius':   _searchRadius.round(),
        }),
      );
      if (res.statusCode == 200 && mounted) {
        _toast('Profil mis à jour ! 🎉', true);
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) Navigator.pop(context, true);
      } else {
        final err = jsonDecode(res.body);
        _toast(err['message'] ?? 'Erreur serveur', false);
      }
    } catch (_) {
      _toast('Connexion impossible', false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Text(ok ? '✅' : '❌', style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(child: Text(msg,
          style: const TextStyle(
            fontWeight: FontWeight.w600, color: Colors.white))),
      ]),
      backgroundColor: ok ? _success : _errCol,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ));
  }

  void _pickBirthYear() {
    const minYear = 1924;
    final maxYear = DateTime.now().year - 13;
    int tmp = _birthYear;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 14),
          Container(width: 40, height: 4,
            decoration: BoxDecoration(
              color: _divider, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(children: [
              const Text('🎂  Année de naissance',
                style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() => _birthYear = tmp);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_rose, _violet]),
                    borderRadius: BorderRadius.circular(24)),
                  child: const Text('Valider',
                    style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 13)))),
            ])),
          SizedBox(
            height: 200,
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(
                initialItem: _birthYear - minYear),
              itemExtent: 44,
              selectionOverlay: Container(
                margin: const EdgeInsets.symmetric(horizontal: 48),
                decoration: BoxDecoration(
                  color: _rose.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12))),
              onSelectedItemChanged: (i) => tmp = minYear + i,
              children: List.generate(maxYear - minYear + 1, (i) =>
                Center(child: Text('${minYear + i}',
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: _ink)))))),
          const SizedBox(height: 30),
        ])));
  }

  void _toggleSlot(String key) => setState(() =>
    _availabilities.contains(key)
      ? _availabilities.remove(key)
      : _availabilities.add(key));

  void _toggleDay(String day) {
    final all = _slots.map((s) => '$day $s').toList();
    final hasAll = all.every(_availabilities.contains);
    setState(() {
      if (hasAll) _availabilities.removeWhere(all.contains);
      else for (final s in all)
        if (!_availabilities.contains(s)) _availabilities.add(s);
    });
  }

  int get _completedSteps {
    int s = 0;
    if (_interests.isNotEmpty)      s++;
    if (_birthYear > 1924)          s++;
    if (_availabilities.isNotEmpty) s++;
    s++;
    if (_locationSynced)            s++;
    return s;
  }

  // ════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // On écoute les changements de thème pour rebuilder
    final rose   = context.watch<ThemeProvider>().color1;
    final violet = context.watch<ThemeProvider>().color2;

    if (_loading) return const Scaffold(
      backgroundColor: _bg,
      body: Center(child: CircularProgressIndicator(
        color: _pinkLight, strokeWidth: 2.5)));

    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(slivers: [

          // ── AppBar WeJoy ──────────────────────────────────────────
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
            flexibleSpace: FlexibleSpaceBar(
              background: _WejoyAppBar(
                completed: _completedSteps,
                total: 5,
                rose: rose,
                violet: violet,
              )),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
            sliver: SliverList(delegate: SliverChildListDelegate([

              // ── Bannière encouragement ───────────────────────────
              _WelcomeBanner(
                completedSteps: _completedSteps,
                rose: rose),
              const SizedBox(height: 22),

              // 01 — Intérêts ──────────────────────────────────────
              _WejoyStepLabel(
                num: '01', emoji: '⭐',
                title: 'Mes centres d\'intérêt',
                info: _interests.isEmpty
                  ? 'Aucun sélectionné'
                  : '${_interests.length} choisi(s)',
                rose: rose,
                violet: violet),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDeco(rose),
                child: Wrap(spacing: 8, runSpacing: 8,
                  children: _interestOptions.map((opt) {
                    final sel = _interests.contains(opt.label);
                    return GestureDetector(
                      onTap: () => setState(() => sel
                        ? _interests.remove(opt.label)
                        : _interests.add(opt.label)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                            ? opt.color.withOpacity(0.13)
                            : _bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel
                              ? opt.color.withOpacity(0.55)
                              : _divider,
                            width: sel ? 1.5 : 1)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(opt.emoji,
                            style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 6),
                          Text(opt.label, style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: sel ? opt.color : _ink)),
                          if (sel) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.favorite_rounded,
                              size: 11, color: opt.color),
                          ],
                        ])));
                  }).toList())),

              const SizedBox(height: 22),

              // 02 — Année de naissance ────────────────────────────
              _WejoyStepLabel(
                num: '02', emoji: '🎂',
                title: 'Mon année de naissance',
                info: '${DateTime.now().year - _birthYear} ans',
                rose: rose,
                violet: violet),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickBirthYear,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _cardDeco(rose),
                  child: Row(children: [
                    _AgeRing(
                      age: DateTime.now().year - _birthYear,
                      rose: rose,
                      violet: violet),
                    const SizedBox(width: 18),
                    Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text('$_birthYear',
                        style: const TextStyle(
                          fontSize: 34, fontWeight: FontWeight.w800,
                          color: _ink, letterSpacing: -1)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _pinkLight,
                          borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          '${DateTime.now().year - _birthYear} ans 🌸',
                          style: TextStyle(
                            fontSize: 12, color: rose,
                            fontWeight: FontWeight.w600))),
                    ]),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _pinkLight,
                        borderRadius: BorderRadius.circular(16)),
                      child: Row(mainAxisSize: MainAxisSize.min,
                        children: [
                        Icon(Icons.edit_rounded, color: rose, size: 14),
                        const SizedBox(width: 6),
                        Text('Modifier',
                          style: TextStyle(color: rose,
                            fontSize: 12, fontWeight: FontWeight.w700)),
                      ])),
                  ]))),

              const SizedBox(height: 22),

              // 03 — Disponibilités ────────────────────────────────
              _WejoyStepLabel(
                num: '03', emoji: '📅',
                title: 'Mes disponibilités',
                info: _availabilities.isEmpty
                  ? 'Aucun créneau'
                  : '${_availabilities.length} créneau(x)',
                rose: rose,
                violet: violet),
              const SizedBox(height: 12),
              Container(
                decoration: _cardDeco(rose),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(children: [
                      const SizedBox(width: 54),
                      ..._slotsL.map((s) => Expanded(child: Center(
                        child: Text(s, style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: _muted, letterSpacing: 0.5))))),
                    ])),
                  Divider(height: 1, color: _divider),
                  ...List.generate(_daysF.length, (di) {
                    final day    = _daysF[di];
                    final dayS   = _daysS[di];
                    final isLast = di == _daysF.length - 1;
                    final allKeys = _slots.map((s) => '$day $s').toList();
                    final hasAll = allKeys.every(_availabilities.contains);
                    final hasAny = allKeys.any(_availabilities.contains);
                    return Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                        child: Row(children: [
                          GestureDetector(
                            onTap: () => _toggleDay(day),
                            child: SizedBox(width: 54, child: Row(children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 9, height: 9,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: hasAll
                                    ? rose
                                    : hasAny
                                      ? rose.withOpacity(0.35)
                                      : _divider)),
                              const SizedBox(width: 6),
                              Text(dayS, style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: hasAny ? _ink : _muted)),
                            ]))),
                          ...List.generate(3, (si) {
                            final key = '$day ${_slots[si]}';
                            final sel = _availabilities.contains(key);
                            return Expanded(child: GestureDetector(
                              onTap: () => _toggleSlot(key),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3),
                                height: 34,
                                decoration: BoxDecoration(
                                  color: sel ? rose : _bg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: sel ? rose : _divider)),
                                child: sel
                                  ? const Icon(Icons.favorite_rounded,
                                      color: Colors.white, size: 13)
                                  : null)));
                          }),
                        ])),
                      if (!isLast) Divider(height: 1, color: _divider),
                    ]);
                  }),
                  const SizedBox(height: 6),
                ])),

              const SizedBox(height: 22),

              // 04 — Rayon de recherche ────────────────────────────
              _WejoyStepLabel(
                num: '04', emoji: '📍',
                title: 'Rayon de recherche',
                info: _radiusLabel(_searchRadius),
                rose: rose,
                violet: violet),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                decoration: _cardDeco(rose),
                child: Column(children: [
                  Row(children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: _purpleLight,
                        borderRadius: BorderRadius.circular(14)),
                      child: const Center(
                        child: Text('🗺️',
                          style: TextStyle(fontSize: 22)))),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text('${_searchRadius.round()} km',
                        style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w800,
                          color: _ink, letterSpacing: -0.5)),
                      Text(_radiusLabel(_searchRadius),
                        style: const TextStyle(
                          fontSize: 12, color: _muted,
                          fontWeight: FontWeight.w500)),
                    ]),
                    const Spacer(),
                    Row(children: [5, 15, 30, 50].map((km) {
                      final on = _searchRadius.round() >= km;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: on ? 9 : 7,
                        height: on ? 9 : 7,
                        margin: const EdgeInsets.only(left: 5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: on ? rose : _divider));
                    }).toList()),
                  ]),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor:   rose,
                      inactiveTrackColor: _divider,
                      thumbColor:         rose,
                      overlayColor:       rose.withOpacity(0.1),
                      trackHeight:        3.5,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 9)),
                    child: Slider(
                      value: _searchRadius, min: 1, max: 50, divisions: 49,
                      onChanged: (v) => setState(() => _searchRadius = v))),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    Text('1 km', style: TextStyle(
                      fontSize: 10, color: _muted.withOpacity(0.6))),
                    Text('50 km', style: TextStyle(
                      fontSize: 10, color: _muted.withOpacity(0.6))),
                  ]),
                ])),

              const SizedBox(height: 22),

              // 05 — GPS ───────────────────────────────────────────
              _WejoyStepLabel(
                num: '05', emoji: '🌍',
                title: 'Ma position',
                info: _locationSynced ? 'Synchronisée 💜' : 'Non renseignée',
                rose: rose,
                violet: violet),
              const SizedBox(height: 12),
              GpsLocationWidget(
                onLocationSynced: (lat, lng) =>
                  setState(() => _locationSynced = true)),

              const SizedBox(height: 36),

              // ── Bouton Enregistrer ───────────────────────────────
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor:     Colors.transparent,
                    padding:         EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22))),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: _saving ? null
                        : LinearGradient(
                            colors: [rose, violet],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight),
                      color: _saving ? _divider : null,
                      borderRadius: BorderRadius.circular(22)),
                    child: Container(
                      alignment: Alignment.center,
                      child: _saving
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            Text('💜  Enregistrer mon profil',
                              style: TextStyle(
                                color: Colors.white, fontSize: 15,
                                fontWeight: FontWeight.w700)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 18),
                          ])))),
              ),

              const SizedBox(height: 14),
              Center(child: Text(
                '🔒  Vos données restent privées et sécurisées.',
                style: TextStyle(
                  fontSize: 11, color: _muted.withOpacity(0.7)))),
              const SizedBox(height: 16),
            ])),
          ),
        ]),
      ),
    );
  }

  BoxDecoration _cardDeco(Color rose) => BoxDecoration(
    color: _surface,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: _divider, width: 1.2),
    boxShadow: [BoxShadow(
      color: rose.withOpacity(0.06),
      blurRadius: 16, offset: const Offset(0, 6))]);

  String _radiusLabel(double km) {
    if (km <= 5)  return 'Mon quartier 🏘️';
    if (km <= 15) return 'Ma ville 🏙️';
    if (km <= 30) return 'Mon agglomération 🌆';
    return 'Grande région 🗺️';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WEJOY APP BAR
// ═══════════════════════════════════════════════════════════════════════════
class _WejoyAppBar extends StatelessWidget {
  final int   completed;
  final int   total;
  final Color rose;
  final Color violet;
  const _WejoyAppBar({
    required this.completed,
    required this.total,
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
          child: Text('✨', style: TextStyle(fontSize: 18))),
        const Positioned(right: 90, top: 30,
          child: Text('💜', style: TextStyle(fontSize: 12))),
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
                Text('WeJoy · Matching',
                  style: TextStyle(
                    color: rose, fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 0.4)),
              ])),
            const SizedBox(height: 10),
            const Text('Mon profil\nde compatibilité 🌸',
              style: TextStyle(
                color: _ink, fontSize: 24,
                fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 16),
            Row(children: List.generate(total, (i) {
              final done = i < completed;
              return Expanded(child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 5,
                margin: EdgeInsets.only(right: i < total - 1 ? 5 : 0),
                decoration: BoxDecoration(
                  color: done ? rose : _divider,
                  borderRadius: BorderRadius.circular(3))));
            })),
            const SizedBox(height: 8),
            Row(children: [
              Text('$completed / $total étapes complétées',
                style: const TextStyle(
                  color: _muted, fontSize: 11, fontWeight: FontWeight.w500)),
              const Spacer(),
              if (completed == total)
                Text('🎉 Parfait !',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: rose)),
            ]),
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
// BANNIÈRE ENCOURAGEMENT
// ═══════════════════════════════════════════════════════════════════════════
class _WelcomeBanner extends StatelessWidget {
  final int   completedSteps;
  final Color rose;
  const _WelcomeBanner({required this.completedSteps, required this.rose});

  @override
  Widget build(BuildContext context) {
    final pct = completedSteps / 5;
    String msg;
    if (pct == 0)       msg = 'Commençons à te connaître ! 😊';
    else if (pct < 0.5) msg = 'Continue, tu es sur la bonne voie ! 🌟';
    else if (pct < 1)   msg = 'Presque terminé, encore un effort ! 💪';
    else                msg = 'Profil complet, bravo ! 🎉';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _pinkLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: rose.withOpacity(0.2))),
      child: Row(children: [
        const Text('🐣', style: TextStyle(fontSize: 30)),
        const SizedBox(width: 12),
        Expanded(child: Text(msg,
          style: TextStyle(
            color: rose, fontSize: 13, fontWeight: FontWeight.w600))),
      ]));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STEP LABEL WEJOY
// ═══════════════════════════════════════════════════════════════════════════
class _WejoyStepLabel extends StatelessWidget {
  final String num;
  final String emoji;
  final String title;
  final String info;
  final Color  rose;
  final Color  violet;
  const _WejoyStepLabel({
    required this.num,
    required this.emoji,
    required this.title,
    required this.info,
    required this.rose,
    required this.violet,
  });

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: _pinkLight,
          borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(emoji,
          style: const TextStyle(fontSize: 18)))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(title, style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
        Text(info, style: const TextStyle(
          fontSize: 12, color: _muted, fontWeight: FontWeight.w500)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _purpleLight,
          borderRadius: BorderRadius.circular(12)),
        child: Text(num,
          style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w800,
            color: violet, letterSpacing: 0.5))),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANNEAU ÂGE
// ═══════════════════════════════════════════════════════════════════════════
class _AgeRing extends StatelessWidget {
  final int   age;
  final Color rose;
  final Color violet;
  const _AgeRing({required this.age, required this.rose, required this.violet});

  @override
  Widget build(BuildContext context) {
    final pct = (age / 90).clamp(0.0, 1.0);
    return SizedBox(
      width: 56, height: 56,
      child: CustomPaint(
        painter: _RingPainter(progress: pct, rose: rose, violet: violet),
        child: Center(child: Text('$age',
          style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800, color: _ink)))));
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
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 5;
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = _divider ..style = PaintingStyle.stroke ..strokeWidth = 5);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2, 2 * math.pi * progress, false,
      Paint()
        ..shader = LinearGradient(colors: [rose, violet])
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
    old.progress != progress || old.rose != rose || old.violet != violet;
}