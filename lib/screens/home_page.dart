import 'package:flutter/material.dart';
import 'package:wejoy/screens/service/api_service.dart';
import 'package:wejoy/screens/activitie_page.dart';
import 'package:wejoy/screens/activity_detail_page.dart';
import 'package:wejoy/widgets/home/welcome_card.dart';
import 'package:wejoy/widgets/home/profile_section.dart';
import 'package:wejoy/widgets/home/mood_selector.dart';
import 'package:wejoy/widgets/home/daily_challenge_card.dart';
import 'package:wejoy/widgets/home/recommended_section.dart';
import 'package:wejoy/widgets/home/community_feed_section.dart';
import 'package:wejoy/widgets/home/activities_section.dart';

// ──────────────────────────────────────────────────────────────────────────────
// L'enum Mood est défini dans mood_selector.dart
// ──────────────────────────────────────────────────────────────────────────────

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
  final _navItems = [
    {'icon': Icons.home_rounded, 'label': 'Accueil'},
    {'icon': Icons.explore_rounded, 'label': 'Explorer'},
    {'icon': Icons.emoji_events_rounded, 'label': 'Défis'},
    {'icon': Icons.people_rounded, 'label': 'Communauté'},
    {'icon': Icons.person_rounded, 'label': 'Profil'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
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
      } else if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _loadRecommended() async {
    try {
      setState(() => _loadingRecommended = true);
      final recommended = await _api.getRecommendedActivities();
      if (mounted) setState(() => _recommended = recommended);
    } catch (e) {
      // silence
    } finally {
      if (mounted) setState(() => _loadingRecommended = false);
    }
  }

  Future<void> _loadAllActivities() async {
    try {
      setState(() => _loadingAll = true);
      final all = await _api.getAllActivities();
      if (mounted) setState(() => _allActivities = all);
    } catch (e) {
      // silence
    } finally {
      if (mounted) setState(() => _loadingAll = false);
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final notifs = await _api.getNotifications();
      if (mounted) setState(() => _notificationCount = notifs.length);
    } catch (_) {}
  }

  Future<void> _loadCommunityFeed() async {
    setState(() => _loadingFeed = true);
    try {
      final feed = await _api.getCommunityFeed();
      if (mounted) setState(() => _communityFeed = feed);
    } catch (e) {
      // silencieux
    } finally {
      if (mounted) setState(() => _loadingFeed = false);
    }
  }

  Future<void> _loadDailyChallenge() async {
    setState(() => _loadingChallenge = true);
    try {
      final challenge = await _api.getDailyChallenge(moodName: _selectedMood?.name);
      if (mounted) setState(() => _dailyChallenge = challenge);
    } catch (e) {
      // silencieux
    } finally {
      if (mounted) setState(() => _loadingChallenge = false);
    }
  }

  Future<void> _filterActivities() async {
    setState(() => _loadingAll = true);
    try {
      final activities = await _api.getAllActivities(
        category: _selectedCategory == 'Tous' ? null : _selectedCategory,
        search: _searchQuery,
      );
      if (mounted) setState(() => _allActivities = activities);
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingAll = false);
    }
  }

  Future<void> _onMoodSelected(Mood mood) async {
    setState(() => _selectedMood = mood);
    try {
      await _api.saveMood(mood.name);
      await Future.wait([
        _loadRecommended(),
        _loadDailyChallenge(),
      ]);
    } catch (e) {
      if (mounted) _showErrorSnackBar("Erreur lors de l'enregistrement de l'humeur");
    }
  }

  Future<void> _joinActivity(Activity activity) async {
    try {
      await _api.joinActivity(activity.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vous avez rejoint "${activity.title}" ! +10 points 🎉',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      _loadRecommended();
      _loadAllActivities();
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
    }
  }

  Future<void> _startDailyChallenge() async {
    if (_dailyChallenge == null) return;
    try {
      await _api.startChallenge(_dailyChallenge!['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Défi commencé ! +${_dailyChallenge!['points']} points 🎉'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadUser();
      await _loadDailyChallenge();
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ======================== BUILD ========================
  @override
  Widget build(BuildContext context) {
    if (_error != null && _user == null && !_loadingUser) return _buildErrorScreen();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              _buildNavBar(),
              Expanded(child: _buildCurrentPage()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedNav) {
      case 0:
        return RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFFD63FBF),
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WelcomeCard(user: _user, loading: _loadingUser),
                const SizedBox(height: 24),
                ProfileSection(user: _user, loading: _loadingUser),
                const SizedBox(height: 24),
                MoodSelector(
                  selectedMood: _selectedMood,
                  onMoodSelected: _onMoodSelected,
                ),
                const SizedBox(height: 24),
                DailyChallengeCard(
                  challenge: _dailyChallenge,
                  loading: _loadingChallenge,
                  onJoin: _startDailyChallenge,
                ),
                const SizedBox(height: 24),
                RecommendedSection(
                  activities: _recommended,
                  loading: _loadingRecommended,
                  onJoin: _joinActivity,
                  onSeeAll: () => setState(() => _selectedNav = 1),
                ),
                const SizedBox(height: 24),
                CommunityFeedSection(
                  feed: _communityFeed,
                  loading: _loadingFeed,
                ),
                const SizedBox(height: 24),
                ActivitiesSection(
                  activities: _allActivities,
                  loading: _loadingAll,
                  categories: _categories,
                  selectedCategory: _selectedCategory,
                  searchController: _searchController,
                  onSearchChanged: (query) {
                    _searchQuery = query;
                    _filterActivities();
                  },
                  onCategorySelected: (cat) {
                    setState(() => _selectedCategory = cat);
                    _filterActivities();
                  },
                  onJoin: _joinActivity,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      case 1:
        return const ActivitiePage();
      case 2:
        return _buildPlaceholder('Défis — Bientôt disponible', Icons.emoji_events_rounded);
      case 3:
        return _buildPlaceholder('Communauté — Bientôt disponible', Icons.people_rounded);
      case 4:
        return RefreshIndicator(
          onRefresh: _loadUser,
          color: const Color(0xFFD63FBF),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ProfileSection(user: _user, loading: _loadingUser, detailed: true),
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildPlaceholder(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD63FBF), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('WJ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
          ),
          const SizedBox(width: 12),
          const Text(
            'WeJoy',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFD63FBF), letterSpacing: -0.5),
          ),
          const Spacer(),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: Colors.grey[700],
                onPressed: () {},
              ),
              if (_notificationCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(color: Color(0xFFD63FBF), shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        '$_notificationCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            color: Colors.grey[600],
            onPressed: () async {
              await _api.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_navItems.length, (i) {
          final isSelected = _selectedNav == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedNav = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? const Color(0xFFD63FBF) : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _navItems[i]['icon'] as IconData,
                      size: 22,
                      color: isSelected ? const Color(0xFFD63FBF) : Colors.grey[500],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _navItems[i]['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? const Color(0xFFD63FBF) : Colors.grey[600],
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
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red),
              ),
              const SizedBox(height: 24),
              const Text('Oups ! Une erreur est survenue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Impossible de charger les données',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() => _error = null);
                  _loadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD63FBF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
