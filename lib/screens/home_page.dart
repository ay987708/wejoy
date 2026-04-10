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

const _rose = Color(0xFFE84C88);
const _violet = Color(0xFF7C4DFF);
const _gold = Color(0xFFFFC857);
const _peach = Color(0xFFFFE8D9);
const _cream = Color(0xFFFAF4EE);
const _snow = Color(0xFFF8F1EA);
const _card = Color(0xFFFFFFFF);
const _ink = Color(0xFF1F1A24);
const _slate = Color(0xFF6E6A78);
const _border = Color(0xFFF1E6DD);

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
    {'icon': Icons.home_rounded, 'label': 'Accueil'},
    {'icon': Icons.explore_rounded, 'label': 'Explorer'},
    {'icon': Icons.emoji_events_rounded, 'label': 'Défis'},
    {'icon': Icons.chat_rounded, 'label': 'Communauté'},
    {'icon': Icons.checklist_rounded, 'label': 'Tâches'},
    {'icon': Icons.person_rounded, 'label': 'Profil'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
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
        _loadUser(),
        _loadRecommended(),
        _loadAllActivities(),
        _loadNotifications(),
        _loadCommunityFeed(),
        _loadDailyChallenge(),
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
        setState(() {
          _notificationCount = n.where((x) => x['lu'] == false).length;
        });
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

  Future<void> _filterActivities() async {
    setState(() => _loadingAll = true);
    try {
      final a = await _api.getAllActivities(
        category: _selectedCategory == 'Tous' ? null : _selectedCategory,
        search: _searchQuery,
      );
      if (mounted) setState(() => _allActivities = a);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingAll = false);
    }
  }

  Future<void> _onMoodSelected(Mood mood) async {
    setState(() => _selectedMood = mood);
    await Future.delayed(const Duration(milliseconds: 120));
    try {
      await _api.saveMood(mood.name);
      await Future.wait([
        _loadRecommended(),
        _loadDailyChallenge(),
      ]);
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
      _snackSuccess('Défi commencé ! +${_dailyChallenge!['points']} points 🎉');
      await _loadUser();
      await _loadDailyChallenge();
    } catch (e) {
      _snackError('Erreur: ${e.toString()}');
    }
  }

  void _snackSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _snackError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showNotifications() async {
    List notifs = [];
    try {
      notifs = await _api.getNotifications();
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: 420,
          constraints: const BoxConstraints(maxHeight: 560),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: _ink.withOpacity(0.08),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_rose, _violet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    const Text(
                      'Notifications',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    if (_notificationCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_notificationCount non lues',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                            color: Colors.white24, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: notifs.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: _rose.withOpacity(0.06),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.notifications_off_outlined,
                                  size: 40, color: _rose.withOpacity(0.4)),
                            ),
                            const SizedBox(height: 16),
                            Text('Aucune notification',
                                style: TextStyle(
                                    color: _slate,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            Text('Vous êtes à jour !',
                                style: TextStyle(
                                    color: _slate.withOpacity(0.6),
                                    fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: notifs.length,
                        separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: _border,
                            indent: 16,
                            endIndent: 16),
                        itemBuilder: (_, i) {
                          final n = notifs[i];
                          final bool lu = n['lu'] == true;
                          final String type = n['type'] ?? 'info';
                          final Color typeColor = type == 'service'
                              ? const Color(0xFF10B981)
                              : type == 'activite'
                                  ? _violet
                                  : _rose;
                          final IconData typeIcon = type == 'service'
                              ? Icons.celebration_rounded
                              : type == 'activite'
                                  ? Icons.flash_on_rounded
                                  : Icons.campaign_rounded;

                          return Container(
                            color: lu
                                ? Colors.transparent
                                : _rose.withOpacity(0.025),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: typeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(typeIcon,
                                      color: typeColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              n['titre'] ?? '',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: lu
                                                    ? FontWeight.w400
                                                    : FontWeight.w600,
                                                color: _ink,
                                              ),
                                            ),
                                          ),
                                          if (!lu)
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: const BoxDecoration(
                                                  color: _rose,
                                                  shape: BoxShape.circle),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        n['message'] ?? '',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: _slate,
                                            height: 1.4),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        _formatDate(n['createdAt']),
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: _slate.withOpacity(0.5),
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              if (notifs.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: _border)),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(26)),
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
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(26)),
                      ),
                    ),
                    child: const Text('Tout marquer comme lu',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return 'À l\'instant';
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _user == null && !_loadingUser) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: _snow,
      body: Stack(
        children: [
          _buildPremiumBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildPremiumHeader(),
                  _buildPremiumNavBar(),
                  Expanded(child: _buildCurrentPage()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFAF4EE),
                Color(0xFFF8EFE7),
                Color(0xFFFDF8F3),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: -60,
          right: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _rose.withOpacity(0.10),
            ),
          ),
        ),
        Positioned(
          top: 120,
          left: -50,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _violet.withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          bottom: 80,
          right: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gold.withOpacity(0.10),
            ),
          ),
        ),
      ],
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
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Une seule WelcomeCard avec le logo animé ──
                _buildPremiumCard(
                  child: WelcomeCard(user: _user, loading: _loadingUser),
                ),
                const SizedBox(height: 16),

                _buildPremiumCard(
                  child: ProfileSection(
                    user: _user,
                    loading: _loadingUser,
                    onProfileUpdated: _loadUser,
                  ),
                ),
                const SizedBox(height: 18),

                _buildSectionTitle(
                  "Bien-être du moment",
                  "Choisis ton humeur et laisse WeJoy t'accompagner.",
                  Icons.favorite_rounded,
                  _rose,
                ),
                const SizedBox(height: 12),

                _buildMoodHeroCard(),
                const SizedBox(height: 18),

                _buildSectionTitle(
                  "Défi du jour",
                  "Un petit pas aujourd'hui, un vrai progrès demain.",
                  Icons.auto_awesome_rounded,
                  _violet,
                ),
                const SizedBox(height: 12),

                _buildPremiumCard(
                  child: DailyChallengeCard(
                    challenge: _dailyChallenge,
                    loading: _loadingChallenge,
                    onJoin: _startDailyChallenge,
                  ),
                ),
                const SizedBox(height: 18),

                _buildSectionTitle(
                  "Recommandé pour toi",
                  "Des activités choisies selon ton énergie et tes envies.",
                  Icons.local_fire_department_rounded,
                  _gold,
                ),
                const SizedBox(height: 12),

                _buildPremiumCard(
                  child: RecommendedSection(
                    activities: _recommended,
                    loading: _loadingRecommended,
                    onJoin: _joinActivity,
                    onSeeAll: () => setState(() => _selectedNav = 1),
                  ),
                ),
                const SizedBox(height: 18),

                _buildSectionTitle(
                  "Communauté",
                  "Découvre ce que les autres partagent et accomplissent.",
                  Icons.groups_rounded,
                  _violet,
                ),
                const SizedBox(height: 12),

                _buildPremiumCard(
                  child: CommunityFeedSection(
                    feed: _communityFeed,
                    loading: _loadingFeed,
                  ),
                ),
                const SizedBox(height: 18),

                _buildSectionTitle(
                  "Explorer",
                  "Recherche une activité qui te ressemble aujourd'hui.",
                  Icons.explore_rounded,
                  _rose,
                ),
                const SizedBox(height: 12),

                _buildPremiumCard(
                  child: ActivitiesSection(
                    activities: _allActivities,
                    loading: _loadingAll,
                    categories: _categories,
                    selectedCategory: _selectedCategory,
                    searchController: _searchController,
                    onSearchChanged: (q) {
                      _searchQuery = q;
                      _filterActivities();
                    },
                    onCategorySelected: (cat) {
                      setState(() => _selectedCategory = cat);
                      _filterActivities();
                    },
                    onJoin: _joinActivity,
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        );

      case 1:
        return const ActivitiePage();
      case 2:
        return const DefisPage();
      case 3:
        return const ChatPage();
      case 4:
        return const TachesPage();
      case 5:
        return const ProfilePage();
      default:
        return const SizedBox();
    }
  }

  Widget _buildMoodHeroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFFF7F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _peach,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: _rose, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Ton bien-être compte aujourd'hui ❤️",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Prends un moment pour te reconnecter à toi-même.",
              style: TextStyle(fontSize: 13, color: _slate, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: MoodSelector(
              key: ValueKey(_selectedMood),
              selectedMood: _selectedMood,
              onMoodSelected: _onMoodSelected,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      String title, String subtitle, IconData icon, Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: accent, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _ink)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12.5, color: _slate, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(color: Colors.white, child: child),
      ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_rose, _violet],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _rose.withOpacity(0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Text('WJ',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.4)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_rose, _violet],
                  ).createShader(bounds),
                  child: const Text('WeJoy',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.4)),
                ),
                Text("Une pause bien-être dans ta journée",
                    style: TextStyle(
                        fontSize: 12,
                        color: _slate,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Stack(
            children: [
              _premiumHeaderBtn(
                  icon: Icons.notifications_rounded,
                  onTap: _showNotifications),
              if (_notificationCount > 0)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _rose,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text('$_notificationCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          _premiumHeaderBtn(
            icon: Icons.logout_rounded,
            onTap: () async {
              await _api.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _premiumHeaderBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Icon(icon, color: _slate, size: 20),
      ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  gradient: sel
                      ? LinearGradient(colors: [
                          _rose.withOpacity(0.12),
                          _violet.withOpacity(0.10),
                        ])
                      : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _navItems[i]['icon'] as IconData,
                      size: 20,
                      color: sel ? _rose : _slate.withOpacity(0.75),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _navItems[i]['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight:
                            sel ? FontWeight.w800 : FontWeight.w500,
                        color: sel ? _rose : _slate.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off_rounded,
                    size: 48, color: Color(0xFFEF4444)),
              ),
              const SizedBox(height: 24),
              Text('Connexion impossible',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _ink)),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Impossible de charger les données',
                textAlign: TextAlign.center,
                style: TextStyle(color: _slate, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _error = null);
                    _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _rose,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Réessayer',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on UserProfile? {
  get fullName => null;
}

extension _FirstOrNullExtension<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}