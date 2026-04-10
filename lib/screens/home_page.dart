import 'package:flutter/material.dart';
import 'package:wejoy/screens/chat_page.dart';
import 'package:wejoy/screens/service/api_service.dart';
import 'package:wejoy/screens/activitie_page.dart';
import 'package:wejoy/screens/profile_page.dart';
import 'package:wejoy/screens/defis_page.dart';
import 'package:wejoy/screens/taches_page.dart';
import 'package:wejoy/widgets/home/welcome_card.dart';
import 'package:wejoy/widgets/home/profile_section.dart';
import 'package:wejoy/widgets/home/mood_selector.dart';
import 'package:wejoy/widgets/home/daily_challenge_card.dart';
import 'package:wejoy/widgets/home/recommended_section.dart';
import 'package:wejoy/widgets/home/community_feed_section.dart';
import 'package:wejoy/widgets/home/activities_section.dart';

// ── Palette premium ────────────────────────────────────────────────────────
const _rose   = Color(0xFFD63FBF);
const _violet = Color(0xFF7C3AED);
const _ink    = Color(0xFF0F0F1A);
const _slate  = Color(0xFF64748B);
const _snow   = Color(0xFFFAFAFC);
const _card   = Color(0xFFFFFFFF);
const _border = Color(0xFFEEEEF5);

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _api = ApiService();

  UserProfile? _user;
  List<Activity> _recommended = [];
  List<Activity> _allActivities = [];
  List<Map<String, dynamic>> _communityFeed = [];
  Map<String, dynamic>? _dailyChallenge;

  bool _loadingUser = true;
  bool _loadingRecommended = true;
  bool _loadingAll = true;
  bool _loadingFeed = true;
  bool _loadingChallenge = true;
  String? _error;

  int _selectedNav = 0;
  String _selectedCategory = 'Tous';
  String _searchQuery = '';
  Mood? _selectedMood;
  int _notificationCount = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final _searchController = TextEditingController();

  final _categories = ['Tous', 'Cuisine', 'Lecture', 'Jardinage', 'Yoga'];

  static const _navItems = [
    {'icon': Icons.home_rounded,         'label': 'Accueil'},
    {'icon': Icons.explore_rounded,      'label': 'Explorer'},
    {'icon': Icons.emoji_events_rounded, 'label': 'Defis'},
    {'icon': Icons.chat_rounded,       'label': 'communautaire'},
    {'icon': Icons.checklist_rounded,     'label': 'Taches'},
    {'icon': Icons.person_rounded,       'label': 'Profil'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 700), vsync: this);
    _fadeAnimation  = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _fadeController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

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
      if (mounted) setState(() => _user = user);
    } on ApiException catch (e) {
      if (e.statusCode == 401 && mounted) Navigator.pushReplacementNamed(context, '/login');
      else if (mounted) setState(() => _error = e.message);
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
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingRecommended = false);
    }
  }

  Future<void> _loadAllActivities() async {
    try {
      setState(() => _loadingAll = true);
      final a = await _api.getAllActivities();
      if (mounted) setState(() => _allActivities = a);
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingAll = false);
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final n = await _api.getNotifications();
      if (mounted) setState(() => _notificationCount = n.where((x) => x['lu'] == false).length);
    } catch (_) {}
  }

  Future<void> _loadCommunityFeed() async {
    setState(() => _loadingFeed = true);
    try {
      final f = await _api.getCommunityFeed();
      if (mounted) setState(() => _communityFeed = f);
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingFeed = false);
    }
  }

  Future<void> _loadDailyChallenge() async {
    setState(() => _loadingChallenge = true);
    try {
      final c = await _api.getDailyChallenge(moodName: _selectedMood?.name);
      if (mounted) setState(() => _dailyChallenge = c);
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingChallenge = false);
    }
  }

  Future<void> _filterActivities() async {
    setState(() => _loadingAll = true);
    try {
      final a = await _api.getAllActivities(
        category: _selectedCategory == 'Tous' ? null : _selectedCategory,
        search: _searchQuery,
      );
      if (mounted) setState(() => _allActivities = a);
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingAll = false);
    }
  }

  Future<void> _onMoodSelected(Mood mood) async {
    setState(() => _selectedMood = mood);
    try {
      await _api.saveMood(mood.name);
      await Future.wait([_loadRecommended(), _loadDailyChallenge()]);
    } catch (_) {
      if (mounted) _snackError("Erreur lors de l'enregistrement de l'humeur");
    }
  }

  Future<void> _joinActivity(Activity activity) async {
    try {
      await _api.joinActivity(activity.id);
      if (!mounted) return;
      _snackSuccess('Vous avez rejoint "${activity.title}" ! +50 points 🎉');
      _loadRecommended();
      _loadAllActivities();
      _loadUser();
    } catch (e) {
      _snackError('Erreur: ${e.toString()}');
    }
  }

  Future<void> _startDailyChallenge() async {
    if (_dailyChallenge == null) return;
    try {
      await _api.startChallenge(_dailyChallenge!['id']);
      if (!mounted) return;
      _snackSuccess('Defi commence ! +${_dailyChallenge!['points']} points 🎉');
      await _loadUser();
      await _loadDailyChallenge();
    } catch (e) {
      _snackError('Erreur: ${e.toString()}');
    }
  }

  void _snackSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Container(padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 16)),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
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

  // ── Panneau notifications ─────────────────────────────────────────────────
  void _showNotifications() async {
    List notifs = [];
    try { notifs = await _api.getNotifications(); } catch (_) {}
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: 420,
          constraints: const BoxConstraints(maxHeight: 560),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: _ink.withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 16)),
            ],
          ),
          child: Column(children: [
            // ── Header gradient ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_rose, _violet], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(children: [
                const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (_notificationCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    child: Text('$_notificationCount non lues',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ]),
            ),
            // ── Liste ────────────────────────────────────────────────────────
            Expanded(
              child: notifs.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _rose.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications_off_outlined, size: 40, color: _rose.withOpacity(0.4)),
                      ),
                      const SizedBox(height: 16),
                      Text('Aucune notification', style: TextStyle(
                        color: _slate, fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Text('Vous etes a jour !', style: TextStyle(color: _slate.withOpacity(0.6), fontSize: 13)),
                    ]),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notifs.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: _border, indent: 16, endIndent: 16),
                    itemBuilder: (_, i) {
                      final n = notifs[i];
                      final bool lu = n['lu'] == true;
                      final String type = n['type'] ?? 'info';
                      final Color typeColor = type == 'service' ? const Color(0xFF10B981)
                          : type == 'activite' ? _violet : _rose;
                      final IconData typeIcon = type == 'service' ? Icons.celebration_rounded
                          : type == 'activite' ? Icons.flash_on_rounded : Icons.campaign_rounded;

                      return Container(
                        color: lu ? Colors.transparent : _rose.withOpacity(0.025),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(typeIcon, color: typeColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(n['titre'] ?? '', style: TextStyle(
                                fontSize: 13,
                                fontWeight: lu ? FontWeight.w400 : FontWeight.w600,
                                color: _ink,
                              ))),
                              if (!lu) Container(
                                width: 7, height: 7,
                                decoration: const BoxDecoration(color: _rose, shape: BoxShape.circle),
                              ),
                            ]),
                            const SizedBox(height: 3),
                            Text(n['message'] ?? '',
                              style: TextStyle(fontSize: 12, color: _slate, height: 1.4),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 5),
                            Text(_formatDate(n['createdAt']),
                              style: TextStyle(fontSize: 10, color: _slate.withOpacity(0.5),
                                fontWeight: FontWeight.w500)),
                          ])),
                        ]),
                      );
                    },
                  ),
            ),
            // ── Footer ───────────────────────────────────────────────────────
            if (notifs.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: _border)),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: TextButton(
                  onPressed: () async {
                    await _api.markAllNotificationsRead();
                    if (mounted) {
                      setState(() => _notificationCount = 0);
                      Navigator.pop(context);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _rose,
                    minimumSize: const Size(double.infinity, 48),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
                  ),
                  child: const Text('Tout marquer comme lu',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
      final d = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return 'A l\'instant';
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return ''; }
  }

  // ======================== BUILD ========================
  @override
  Widget build(BuildContext context) {
    if (_error != null && _user == null && !_loadingUser) return _buildErrorScreen();
    return Scaffold(
      backgroundColor: _snow,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(children: [
            _buildHeader(),
            _buildNavBar(),
            Expanded(child: _buildCurrentPage()),
          ]),
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedNav) {
      case 0:
        return RefreshIndicator(
          onRefresh: _loadData,
          color: _rose,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              WelcomeCard(user: _user, loading: _loadingUser),
              const SizedBox(height: 20),
              ProfileSection(user: _user,loading: _loadingUser,onProfileUpdated: _loadUser,),
              const SizedBox(height: 20),
              MoodSelector(selectedMood: _selectedMood, onMoodSelected: _onMoodSelected),
              const SizedBox(height: 20),
              DailyChallengeCard(challenge: _dailyChallenge, loading: _loadingChallenge, onJoin: _startDailyChallenge),
              const SizedBox(height: 20),
              RecommendedSection(
                activities: _recommended, loading: _loadingRecommended,
                onJoin: _joinActivity, onSeeAll: () => setState(() => _selectedNav = 1),
              ),
              const SizedBox(height: 20),
              CommunityFeedSection(feed: _communityFeed, loading: _loadingFeed),
              const SizedBox(height: 20),
              ActivitiesSection(
                activities: _allActivities, loading: _loadingAll,
                categories: _categories, selectedCategory: _selectedCategory,
                searchController: _searchController,
                onSearchChanged: (q) { _searchQuery = q; _filterActivities(); },
                onCategorySelected: (cat) { setState(() => _selectedCategory = cat); _filterActivities(); },
                onJoin: _joinActivity,
              ),
              const SizedBox(height: 24),
            ]),
          ),
        );
      case 1: return const ActivitiePage();
      case 2: return const DefisPage();
      case 3: return const ChatPage();
      case 4: return const TachesPage();
      case 5: return const ProfilePage();
      default: return const SizedBox();
    }
  }

  Widget _buildPlaceholder(String text, IconData icon, Color color) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 48, color: color.withOpacity(0.5)),
      ),
      const SizedBox(height: 16),
      Text(text, style: TextStyle(color: _slate, fontSize: 15, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      Text('Disponible prochainement', style: TextStyle(color: _slate.withOpacity(0.5), fontSize: 13)),
    ]));
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
        boxShadow: [
          BoxShadow(color: _ink.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        // Logo
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_rose, _violet],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(11),
            boxShadow: [BoxShadow(color: _rose.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: const Center(child: Text('WJ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5))),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(colors: [_rose, _violet]).createShader(b),
          child: const Text('WeJoy', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w800,
            color: Colors.white, letterSpacing: -0.5,
          )),
        ),
        const Spacer(),
        // Cloche
        Stack(children: [
          _headerBtn(Icons.notifications_outlined, () => _showNotifications()),
          if (_notificationCount > 0)
            Positioned(
              top: 6, right: 6,
              child: Container(
                width: 16, height: 16,
                decoration: BoxDecoration(
                  color: _rose,
                  shape: BoxShape.circle,
                  border: Border.all(color: _card, width: 1.5),
                ),
                child: Center(child: Text('$_notificationCount',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
              ),
            ),
        ]),
        const SizedBox(width: 4),
        // Logout
        _headerBtn(Icons.logout_rounded, () async {
          await _api.logout();
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        }),
      ]),
    );
  }

  Widget _headerBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: _snow,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _border),
        ),
        child: Icon(icon, size: 18, color: _slate),
      ),
    );
  }

  // ── NavBar ────────────────────────────────────────────────────────────────
  Widget _buildNavBar() {
    return Container(
      color: _card,
      child: Row(
        children: List.generate(_navItems.length, (i) {
          final sel = _selectedNav == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedNav = i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(
                    color: sel ? _rose : Colors.transparent, width: 2,
                  )),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(sel ? 6 : 0),
                    decoration: BoxDecoration(
                      color: sel ? _rose.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _navItems[i]['icon'] as IconData, size: 20,
                      color: sel ? _rose : _slate.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(_navItems[i]['label'] as String, style: TextStyle(
                    fontSize: 10,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                    color: sel ? _rose : _slate.withOpacity(0.6),
                    letterSpacing: sel ? 0.3 : 0,
                  )),
                ]),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Error screen ─────────────────────────────────────────────────────────
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
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFEF4444)),
          ),
          const SizedBox(height: 24),
          Text('Connexion impossible', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 8),
          Text(_error ?? 'Impossible de charger les donnees',
            textAlign: TextAlign.center,
            style: TextStyle(color: _slate, fontSize: 13, height: 1.5)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { setState(() => _error = null); _loadData(); },
              style: ElevatedButton.styleFrom(
                backgroundColor: _rose, foregroundColor: Colors.white,
                elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Reessayer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ]),
      )),
    );
  }
}