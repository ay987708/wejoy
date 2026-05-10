import 'dart:core';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wejoy/screens/chat_page.dart';
import 'package:wejoy/screens/defis/Gams_lobby_page.dart';
import 'package:wejoy/screens/service/api_service.dart';
import 'package:wejoy/screens/activitie_page.dart';
import 'package:wejoy/screens/profile_page.dart';
import 'package:wejoy/screens/taches_page.dart';
import 'package:wejoy/widgets/home/welcome_card.dart';
import 'package:wejoy/widgets/home/mood_selector.dart';
import 'package:wejoy/widgets/home/recommended_section.dart';
import 'package:wejoy/theme/theme_provider.dart';
import 'package:wejoy/screens/journal/journal_timeline_page.dart';
import 'package:wejoy/screens/journal/journal_stats_page.dart';
import 'package:wejoy/models/mood_option.dart';

// ── Palette fixe (non thématique) ────────────────────────────────────────
const _gold   = Color(0xFFFFC857);
const _peach  = Color(0xFFFFE8D9);
const _snow   = Color(0xFFF8F1EA);
const _card   = Color(0xFFFFFFFF);
const _ink    = Color(0xFF1F1A24);
const _slate  = Color(0xFF6E6A78);
const _border = Color(0xFFF1E6DD);

const _moodStickers = [
  'assets/images/moods/mood_1_mal.png',
  'assets/images/moods/mood_2_pas_bien.png',
  'assets/images/moods/mood_3_pas_mal.png',
  'assets/images/moods/mood_4_bien.png',
  'assets/images/moods/mood_5_tres_bien.png',
];

const _moodStickerLabels = [
  'Mal', 'Pas bien', 'Pas mal', 'Bien', 'Très bien',
];

const _moodThemes = [
  {
    'color':       Color(0xFF3B82F6),
    'bg':          Color(0xFFEFF6FF),
    'border':      Color(0xFFBFDBFE),
    'hint':        'Prends ton temps, je suis là 💙',
    'thought':     'Chaque larme est une preuve de ta force.',
    'placeholder': 'Qu\'est-ce qui pèse sur ton cœur ?',
  },
  {
    'color':       Color(0xFF8B5CF6),
    'bg':          Color(0xFFF5F3FF),
    'border':      Color(0xFFDDD6FE),
    'hint':        'Je t\'écoute, tu n\'es pas seul(e) 💜',
    'thought':     'L\'anxiété est juste une vague, elle passe.',
    'placeholder': 'Qu\'est-ce qui t\'inquiète en ce moment ?',
  },
  {
    'color':       Color(0xFF6B7280),
    'bg':          Color(0xFFF9FAFB),
    'border':      Color(0xFFE5E7EB),
    'hint':        'Un moment neutre, c\'est aussi ok 🌫️',
    'thought':     'Même les jours calmes ont leur beauté.',
    'placeholder': 'Décris ta journée en quelques mots…',
  },
  {
    'color':       Color(0xFF10B981),
    'bg':          Color(0xFFF0FDF4),
    'border':      Color(0xFFBBF7D0),
    'hint':        'Super ! Qu\'est-ce qui va bien ? 🌿',
    'thought':     'Ta bonne énergie est contagieuse.',
    'placeholder': 'Qu\'est-ce qui te rend heureux(se) ?',
  },
  {
    'color':       Color(0xFFF59E0B),
    'bg':          Color(0xFFFFFBEB),
    'border':      Color(0xFFFDE68A),
    'hint':        'Qu\'est-ce qui a rendu ce moment spécial ? ✨',
    'thought':     'L\'euphorie mérite d\'être capturée !',
    'placeholder': 'Raconte ce moment extraordinaire…',
  },
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _api = ApiService();

  // ── Raccourcis ThemeProvider ──────────────────────────────────────────
  Color get _rose   => context.read<ThemeProvider>().color1;
  Color get _violet => context.read<ThemeProvider>().color2;

  UserProfile? _user;
  List<Activity> _recommended   = [];
  List<Activity> _allActivities = [];
  List<Map<String, dynamic>> _communityFeed = [];
  Map<String, dynamic>? _dailyChallenge;

  bool _loadingUser        = true;
  bool _loadingRecommended = true;
  bool _loadingAll         = true;
  bool _loadingFeed        = true;
  bool _loadingChallenge   = true;
  String? _error;

  int    _selectedNav       = 0;
  String _selectedCategory  = 'Tous';
  String _searchQuery       = '';
  Mood?  _selectedMood;
  int    _notificationCount = 0;

  bool _showProfileBanner = false;
  late AnimationController _bannerController;
  late Animation<double>   _bannerAnim;

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnimation;
  final _searchController = TextEditingController();

  int _journalMoodIndex = -1;
  final TextEditingController _journalController = TextEditingController();
  bool _journalSaving = false;
  Map<String, dynamic>? _lastJournalEntry;

  late List<AnimationController> _stickerControllers;
  late List<Animation<double>>   _stickerScales;
  late List<Animation<double>>   _stickerFloats;
  late List<AnimationController> _shakeControllers;
  late List<Animation<double>>   _shakeAnims;

  static const _navItems = [
    {'icon': Icons.home_rounded,          'label': 'Accueil'},
    {'icon': Icons.explore_rounded,       'label': 'Activités'},
    {'icon': Icons.emoji_events_rounded,  'label': 'Défis'},
    {'icon': Icons.checklist_rounded,     'label': 'Tâches'},
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    _fadeAnimation = CurvedAnimation(
        parent: _fadeController, curve: Curves.easeOutCubic);
    _fadeController.forward();

    _bannerController = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _bannerAnim = CurvedAnimation(
        parent: _bannerController, curve: Curves.easeOutCubic);

    _stickerControllers = List.generate(5, (_) => AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600)));
    _stickerFloats = _stickerControllers.map((c) =>
        Tween<double>(begin: 0, end: -7).animate(
            CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
    _stickerScales = _stickerControllers.map((c) =>
        Tween<double>(begin: 1.0, end: 1.06).animate(
            CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();

    _shakeControllers = List.generate(5, (_) => AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450)));
    _shakeAnims = _shakeControllers.map((c) =>
        Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(parent: c, curve: Curves.elasticOut))).toList();

    _loadData();
    _loadLastEntry();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bannerController.dispose();
    _searchController.dispose();
    _journalController.dispose();
    for (final c in _stickerControllers) c.dispose();
    for (final c in _shakeControllers)   c.dispose();
    super.dispose();
  }

  // ── Journal ───────────────────────────────────────────────────────────
  void _selectMoodSticker(int i) {
    if (_journalMoodIndex != -1 && _journalMoodIndex != i) {
      _stickerControllers[_journalMoodIndex].stop();
      _stickerControllers[_journalMoodIndex].reset();
    }
    setState(() => _journalMoodIndex = i);
    _shakeControllers[i].reset();
    _shakeControllers[i].forward();
    _stickerControllers[i].repeat(reverse: true);
  }

  Future<void> _loadLastEntry() async {
    try {
      final res     = await _api.getJournalEntries(limit: 1);
      final entries = res['entries'] as List<dynamic>? ?? [];
      if (entries.isNotEmpty && mounted) {
        setState(() => _lastJournalEntry = entries.first);
      }
    } catch (_) {}
  }

  Future<void> _saveJournalEntry() async {
    final text = _journalController.text.trim();
    if (text.isEmpty) return;
    if (_journalMoodIndex == -1) {
      _snackError('Choisis ton humeur d\'abord 😊');
      return;
    }
    setState(() => _journalSaving = true);
    try {
      await _api.createJournalEntry(
          content: text, moodValue: kMoods[_journalMoodIndex].value);
      _journalController.clear();
      _stickerControllers[_journalMoodIndex].stop();
      _stickerControllers[_journalMoodIndex].reset();
      setState(() => _journalMoodIndex = -1);
      await _loadLastEntry();
      _snackSuccess('Entrée enregistrée ! ✨');
    } catch (e) {
      _snackError('Erreur: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _journalSaving = false);
    }
  }

  // ── Bannière profil ───────────────────────────────────────────────────
  void _maybeShowProfileBanner(UserProfile? user) {
    if (user == null) return;
    final incomplete = (user.id == null || user.id!.isEmpty) ||
        (user.avatarUrl == null || user.avatarUrl!.isEmpty);
    if (!incomplete) return;
    setState(() => _showProfileBanner = true);
    _bannerController.forward();
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      _bannerController.reverse().then((_) {
        if (mounted) setState(() => _showProfileBanner = false);
      });
    });
  }

  // ── Chargement données ────────────────────────────────────────────────
  Future<void> _loadData() async {
    try {
      await Future.wait([
        _loadUser(), _loadRecommended(), _loadAllActivities(),
        _loadNotifications(), _loadCommunityFeed(), _loadDailyChallenge(),
      ]);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _loadUser() async {
    try {
      setState(() => _loadingUser = true);
      final user = await _api.getMyProfile();
      if (mounted) {
        setState(() => _user = user);
        _maybeShowProfileBanner(user);
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 && mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      } else if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _loadRecommended() async {
    try {
      setState(() => _loadingRecommended = true);
      final r = await _api.getRecommendedActivities();
      if (mounted) setState(() => _recommended = r);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingRecommended = false);
    }
  }

  Future<void> _loadAllActivities() async {
    try {
      setState(() => _loadingAll = true);
      final a = await _api.getAllActivities();
      if (mounted) setState(() => _allActivities = a);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingAll = false);
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final n = await _api.getNotifications();
      if (mounted) {
        setState(() => _notificationCount =
            n.where((x) => x['lu'] == false).length);
      }
    } catch (_) {}
  }

  Future<void> _loadCommunityFeed() async {
    setState(() => _loadingFeed = true);
    try {
      final f = await _api.getCommunityFeed();
      if (mounted) setState(() => _communityFeed = f);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingFeed = false);
    }
  }

  Future<void> _loadDailyChallenge() async {
    setState(() => _loadingChallenge = true);
    try {
      final c = await _api.getDailyChallenge(moodName: _selectedMood?.name);
      if (mounted) setState(() => _dailyChallenge = c);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingChallenge = false);
    }
  }

  Future<void> _onMoodSelected(Mood mood) async {
    setState(() { _selectedMood = mood; _loadingRecommended = true; });
    try {
      await _api.saveMood(mood.name);
      await Future.wait([_loadRecommended(), _loadDailyChallenge()]);
    } catch (_) {
      if (mounted) _snackError("Erreur lors de l'enregistrement de l'humeur");
    } finally {
      if (mounted) setState(() => _loadingRecommended = false);
    }
  }

  Future<void> _joinActivity(Activity activity) async {
    try {
      await _api.joinActivity(activity.id);
      if (!mounted) return;
      _snackSuccess('Vous avez rejoint "${activity.title}" ! +50 points 🎉');
      _loadRecommended(); _loadAllActivities(); _loadUser();
    } catch (e) { _snackError('Erreur: ${e.toString()}'); }
  }

  // ── Snackbars ─────────────────────────────────────────────────────────
  void _snackSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
              color: Colors.white24, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 16)),
        const SizedBox(width: 10),
        Expanded(child: Text(msg,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
      ]),
      backgroundColor: const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 3),
    ));
  }

  void _snackError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 13)),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  // ── Notifications ─────────────────────────────────────────────────────
  void _showNotifications() async {
    final rose   = _rose;
    final violet = _violet;

    List notifs = [];
    try { notifs = await _api.getNotifications(); } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        elevation: 0, backgroundColor: Colors.transparent,
        child: Container(
          width: 420,
          constraints: const BoxConstraints(maxHeight: 560),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [BoxShadow(
                color: _ink.withOpacity(0.08),
                blurRadius: 40, offset: const Offset(0, 16))],
          ),
          child: Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [rose, violet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(26)),
              ),
              child: Row(children: [
                const Icon(Icons.notifications_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Text('Notifications', style: TextStyle(
                    color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w700)),
                const Spacer(),
                if (_notificationCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('$_notificationCount non lues',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 11, fontWeight: FontWeight.w600))),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                        color: Colors.white24, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 16)),
                ),
              ]),
            ),

            // Body
            Expanded(
              child: notifs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: rose.withOpacity(0.06),
                              shape: BoxShape.circle),
                          child: Icon(Icons.notifications_off_outlined,
                              size: 40, color: rose.withOpacity(0.4))),
                        const SizedBox(height: 16),
                        const Text('Aucune notification',
                            style: TextStyle(color: _slate, fontSize: 15,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text('Vous êtes à jour !',
                            style: TextStyle(
                                color: _slate.withOpacity(0.6), fontSize: 13)),
                      ]))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: notifs.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1, color: _border, indent: 16, endIndent: 16),
                      itemBuilder: (_, i) {
                        final n = notifs[i];
                        final bool lu = n['lu'] == true;
                        final String type = n['type'] ?? 'info';
                        final Color typeColor = type == 'service'
                            ? const Color(0xFF10B981)
                            : type == 'activite' ? violet : rose;
                        final IconData typeIcon = type == 'service'
                            ? Icons.celebration_rounded
                            : type == 'activite'
                                ? Icons.flash_on_rounded
                                : Icons.campaign_rounded;

                        return Container(
                          color: lu
                              ? Colors.transparent
                              : rose.withOpacity(0.025),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                    color: typeColor.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                child: Icon(typeIcon,
                                    color: typeColor, size: 20)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(child: Text(n['titre'] ?? '',
                                        style: TextStyle(fontSize: 13,
                                            fontWeight: lu
                                                ? FontWeight.w400
                                                : FontWeight.w600,
                                            color: _ink))),
                                    if (!lu)
                                      Container(
                                          width: 7, height: 7,
                                          decoration: BoxDecoration(
                                              color: rose,
                                              shape: BoxShape.circle)),
                                  ]),
                                  const SizedBox(height: 3),
                                  Text(n['message'] ?? '',
                                      style: const TextStyle(fontSize: 12,
                                          color: _slate, height: 1.4),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 5),
                                  Text(_formatDate(n['createdAt']),
                                      style: TextStyle(fontSize: 10,
                                          color: _slate.withOpacity(0.5),
                                          fontWeight: FontWeight.w500)),
                                ],
                              )),
                            ],
                          ),
                        );
                      }),
            ),

            // Footer
            if (notifs.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: _border)),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(26))),
                child: TextButton(
                  onPressed: () async {
                    await _api.markAllNotificationsRead();
                    if (mounted) {
                      setState(() => _notificationCount = 0);
                      Navigator.pop(context);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: rose,
                    minimumSize: const Size(double.infinity, 48),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(26)))),
                  child: const Text('Tout marquer comme lu',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d    = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1)  return 'À l\'instant';
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24)   return 'Il y a ${diff.inHours}h';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return ''; }
  }

  // ══════════════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();

    if (_error != null && _user == null && !_loadingUser) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: _snow,
      body: Stack(children: [
        _buildPremiumBackground(),
        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(children: [
              _buildPremiumHeader(),
              _buildPremiumNavBar(),
              Expanded(child: _buildCurrentPage()),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildPremiumBackground() {
    return Stack(children: [
      Container(decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFAF4EE), Color(0xFFF8EFE7), Color(0xFFFDF8F3)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter))),
      Positioned(top: -60, right: -40, child: Container(width: 180, height: 180,
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: _rose.withOpacity(0.10)))),
      Positioned(top: 120, left: -50, child: Container(width: 140, height: 140,
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: _violet.withOpacity(0.08)))),
      Positioned(bottom: 80, right: -30, child: Container(width: 120, height: 120,
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: _gold.withOpacity(0.10)))),
    ]);
  }

  Widget _buildCurrentPage() {
    switch (_selectedNav) {
      case 0: return _buildHomePage();
      case 1: return const ActivitiePage();
      case 2: return const GamesLobbyPage();
      case 3: return const TachesPage();
      case 4: return const ProfilePage();
      default: return const SizedBox();
    }
  }

  Widget _buildHomePage() {
    return Stack(children: [
      RefreshIndicator(
        onRefresh: _loadData, color: _rose, backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildPremiumCard(
                child: WelcomeCard(user: _user, loading: _loadingUser)),
            const SizedBox(height: 18),
            _buildSectionTitle(
              "Bien-être du moment",
              "Choisis ton humeur et laisse WeJoy t'accompagner.",
              Icons.favorite_rounded, _rose),
            const SizedBox(height: 12),
            _buildInlineJournalCard(),
            const SizedBox(height: 18),
            _buildSectionTitle(
              "Recommandé pour toi",
              "Des activités choisies selon ton énergie et tes envies.",
              Icons.local_fire_department_rounded, _gold),
            const SizedBox(height: 12),
            _buildPremiumCard(child: RecommendedSection(
                activities: _recommended,
                loading: _loadingRecommended,
                onJoin: _joinActivity,
                onSeeAll: () => setState(() => _selectedNav = 1))),
            const SizedBox(height: 18),
          ]),
        ),
      ),

      // Bannière profil
      if (_showProfileBanner)
        Positioned(top: 12, left: 16, right: 16,
          child: FadeTransition(
            opacity: _bannerAnim,
            child: SlideTransition(
              position: Tween<Offset>(
                  begin: const Offset(0, -0.5), end: Offset.zero)
                  .animate(_bannerAnim),
              child: GestureDetector(
                onTap: () {
                  _bannerController.reverse().then((_) {
                    if (mounted) setState(() => _showProfileBanner = false);
                  });
                  setState(() => _selectedNav = 5);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [_rose, _violet],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: _rose.withOpacity(0.30),
                        blurRadius: 16, offset: const Offset(0, 6))]),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 16)),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Améliorez votre profil',
                        style: TextStyle(color: Colors.white,
                            fontSize: 13, fontWeight: FontWeight.w700))),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white, size: 13),
                  ]),
                ),
              ),
            ),
          )),

      // Bouton chat IA
      Positioned(
        right: 20, bottom: 20,
        child: GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ChatPage())),
          child: Container(
            width: 150, height: 150,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(child: Image.asset(
                'assets/images/joyaai.png', fit: BoxFit.cover)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildInlineJournalCard() {
    final hasTheme    = _journalMoodIndex != -1;
    final theme       = hasTheme ? _moodThemes[_journalMoodIndex] : null;
    final accentColor = hasTheme ? theme!['color']       as Color  : _rose;
    final bgColor     = hasTheme ? theme!['bg']          as Color  : Colors.white;
    final borderColor = hasTheme ? theme!['border']      as Color  : const Color(0xFFF0E6FF);
    final hint        = hasTheme ? theme!['hint']        as String : 'Sélectionne ton humeur pour commencer ✨';
    final thought     = hasTheme ? theme!['thought']     as String : 'Même les petits élans comptent.';
    final placeholder = hasTheme ? theme!['placeholder'] as String : 'Je suis là, écris ce que tu ressens…';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 24, offset: const Offset(0, 10))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Pensée du moment
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: accentColor, width: 3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PENSÉE DU MOMENT', style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w800,
                letterSpacing: 0.8, color: accentColor)),
            const SizedBox(height: 3),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(thought, key: ValueKey(thought),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: accentColor, fontStyle: FontStyle.italic, height: 1.4)),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        const Text('Comment tu te sens ?',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 12),

        // Stickers
        LayoutBuilder(builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          const gap        = 8.0;
          final itemWidth  = ((totalWidth - gap * 4) / 5).floorToDouble();
          const cardHeight = 190.0;
          const imgSize    = cardHeight - 40.0;

          return SizedBox(
            height: cardHeight,
            child: Row(children: List.generate(5, (i) {
              final sel    = _journalMoodIndex == i;
              final mColor = _moodThemes[i]['color'] as Color;

              return GestureDetector(
                onTap: () => _selectMoodSticker(i),
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _stickerControllers[i], _shakeControllers[i]]),
                  builder: (_, child) {
                    final shakeVal = _shakeAnims[i].value;
                    final shakeX = sel
                        ? math.sin(shakeVal * math.pi * 4) * 5 * (1 - shakeVal)
                        : 0.0;
                    final floatY = sel ? _stickerFloats[i].value : 0.0;
                    final scale  = sel ? _stickerScales[i].value : 1.0;
                    return Transform.translate(
                      offset: Offset(shakeX, floatY),
                      child: Transform.scale(scale: scale, child: child));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutBack,
                    width: itemWidth, height: cardHeight,
                    margin: EdgeInsets.only(right: i < 4 ? gap : 0),
                    decoration: BoxDecoration(
                      color: sel ? mColor.withOpacity(0.12) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? mColor : const Color(0xFFEEEEEE),
                          width: sel ? 2.5 : 1.5),
                      boxShadow: sel
                          ? [BoxShadow(color: mColor.withOpacity(0.25),
                              blurRadius: 18, offset: const Offset(0, 6))]
                          : [BoxShadow(color: Colors.black.withOpacity(0.05),
                              blurRadius: 8, offset: const Offset(0, 3))]),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: imgSize, height: imgSize,
                          child: Image.asset(_moodStickers[i],
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(kMoods[i].emoji,
                                  style: const TextStyle(fontSize: 44))))),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: sel ? mColor : _slate),
                          child: Text(_moodStickerLabels[i],
                              textAlign: TextAlign.center)),
                        const SizedBox(height: 5),
                        Container(width: 6, height: 6,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sel ? mColor : Colors.transparent)),
                      ]),
                  ),
                ),
              );
            })),
          );
        }),
        const SizedBox(height: 14),

        // Hint
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: accentColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Text('✦', style: TextStyle(fontSize: 12, color: accentColor)),
            const SizedBox(width: 8),
            Expanded(child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(hint, key: ValueKey(hint),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: accentColor, height: 1.4)),
            )),
          ]),
        ),
        const SizedBox(height: 12),

        // Textarea
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 1.5)),
          child: Column(children: [
            TextField(
              controller: _journalController,
              maxLines: 4, minLines: 3,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14, color: _ink, height: 1.6),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(
                    color: _slate.withOpacity(0.5), fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${_journalController.text.length} / 500',
                    style: TextStyle(
                        fontSize: 11, color: _slate.withOpacity(0.5))),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),

        // Bouton enregistrer
        GestureDetector(
          onTap: _journalSaving ? null : _saveJournalEntry,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _journalController.text.trim().isNotEmpty &&
                _journalMoodIndex != -1 ? 1.0 : 0.45,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [accentColor, accentColor.withOpacity(0.75)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(
                    color: accentColor.withOpacity(0.30),
                    blurRadius: 14, offset: const Offset(0, 6))]),
              child: Center(child: _journalSaving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Enregistrer mon moment ✨',
                      style: TextStyle(color: Colors.white,
                          fontSize: 14, fontWeight: FontWeight.w800,
                          letterSpacing: 0.2))),
            ),
          ),
        ),

        // Dernière entrée
        if (_lastJournalEntry != null) ...[
          const SizedBox(height: 16),
          Divider(color: borderColor),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.history_rounded, size: 14, color: accentColor),
            const SizedBox(width: 6),
            Text('Dernière entrée', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: accentColor)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const JournalTimelinePage())),
              child: Text('Voir tout →', style: TextStyle(
                  fontSize: 11, color: accentColor, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_lastJournalEntry!['content'] ?? '',
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: _ink, height: 1.4)),
              const SizedBox(height: 6),
              Text(_formatDate(_lastJournalEntry!['createdAt']),
                style: TextStyle(fontSize: 10, color: _slate.withOpacity(0.6))),
            ]),
          ),
        ],

        // Bouton statistiques
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const JournalStatsPage())),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentColor.withOpacity(0.25))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.bar_chart_rounded, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text('Voir mes statistiques', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: accentColor)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle,
      IconData icon, Color accent) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 42, height: 42,
        decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: accent, size: 21)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(
            fontSize: 12.5, color: _slate, height: 1.35)),
      ])),
    ]);
  }

  Widget _buildPremiumCard({required Widget child}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.8)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 22, offset: const Offset(0, 10))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(color: Colors.white, child: child)),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.7)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24, offset: const Offset(0, 10))]),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/logowejoy.png',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            ),
            ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                LinearGradient(colors: [_rose, _violet]).createShader(bounds),
            child: const Text('WeJoy', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900,
                color: Colors.white, letterSpacing: -0.4))),
          const Text("Une pause bien-être dans ta journée",
              style: TextStyle(fontSize: 12, color: _slate,
                  fontWeight: FontWeight.w500)),
        ])),
        _premiumHeaderBtn(icon: Icons.person_rounded,
            onTap: () => setState(() => _selectedNav = 5)),
        const SizedBox(width: 8),
        Stack(children: [
          _premiumHeaderBtn(icon: Icons.notifications_rounded,
              onTap: _showNotifications),
          if (_notificationCount > 0)
            Positioned(top: 2, right: 2,
              child: Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                    color: _rose, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
                child: Center(child: Text('$_notificationCount',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 9, fontWeight: FontWeight.w800))))),
        ]),
        const SizedBox(width: 8),
        _premiumHeaderBtn(icon: Icons.logout_rounded, onTap: () async {
          await _api.logout();
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        }),
      ]),
    );
  }

  Widget _premiumHeaderBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
            color: const Color(0xFFFFFBF7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border)),
        child: Icon(icon, color: _slate, size: 20)),
    );
  }

  Widget _buildPremiumNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.7)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20, offset: const Offset(0, 8))]),
      child: Row(
        children: List.generate(_navItems.length, (i) {
          final sel = _selectedNav == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedNav = i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  gradient: sel ? LinearGradient(colors: [
                    _rose.withOpacity(0.12),
                    _violet.withOpacity(0.10)]) : null,
                  borderRadius: BorderRadius.circular(16)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_navItems[i]['icon'] as IconData, size: 20,
                      color: sel ? _rose : _slate.withOpacity(0.75)),
                  const SizedBox(height: 4),
                  Text(_navItems[i]['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9.5,
                          fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                          color: sel ? _rose : _slate.withOpacity(0.75))),
                ]),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: _snow,
      body: Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.08),
                shape: BoxShape.circle),
            child: const Icon(Icons.wifi_off_rounded,
                size: 48, color: Color(0xFFEF4444))),
          const SizedBox(height: 24),
          const Text('Connexion impossible', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 8),
          Text(_error ?? 'Impossible de charger les données',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _slate, fontSize: 13, height: 1.5)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { setState(() => _error = null); _loadData(); },
              style: ElevatedButton.styleFrom(
                backgroundColor: _rose, foregroundColor: Colors.white,
                elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
              child: const Text('Réessayer',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
          ),
        ]),
      )),
    );
  }
}

extension on UserProfile? {
  get fullName => null;
}