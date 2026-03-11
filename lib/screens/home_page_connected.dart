import 'package:flutter/material.dart';
import 'package:wejoy/screens/service/api_service.dart';
import 'package:wejoy/screens/activitie_page.dart';

// ════════════════════════════════════════════════════════════════════════════
// HOME PAGE — avec navigation vers ActivitiePage
// ════════════════════════════════════════════════════════════════════════════

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

  bool _loadingUser = true;
  bool _loadingActivities = true;
  String? _error;

  int _selectedNav = 0; // ← index de la navbar
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

  final Map<String, ImageProvider> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
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
      await Future.wait([_loadUser(), _loadActivities(), _loadNotifications()]);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _loadUser() async {
    try {
      setState(() => _loadingUser = true);
      final user = await _api.getMyProfile();
      if (mounted) setState(() { _user = user; _loadingUser = false; });
    } on ApiException catch (e) {
      if (e.statusCode == 401 && mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      } else if (mounted) {
        setState(() { _loadingUser = false; _error = e.message; });
      }
    } catch (e) {
      if (mounted) setState(() { _loadingUser = false; _error = e.toString(); });
    }
  }

  Future<void> _loadActivities() async {
    try {
      setState(() => _loadingActivities = true);
      final recommended = await _api.getRecommendedActivities();
      final allActivities = await _api.getAllActivities();
      if (mounted) setState(() { _recommended = recommended; _allActivities = allActivities; _loadingActivities = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingActivities = false);
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final notifs = await _api.getNotifications();
      if (mounted) setState(() => _notificationCount = notifs.length);
    } catch (_) {}
  }

  Future<void> _filterActivities() async {
    setState(() => _loadingActivities = true);
    try {
      final activities = await _api.getAllActivities(category: _selectedCategory == 'Tous' ? null : _selectedCategory, search: _searchQuery);
      if (mounted) setState(() { _allActivities = activities; _loadingActivities = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingActivities = false);
    }
  }

  Future<void> _onMoodSelected(Mood mood) async {
    setState(() => _selectedMood = mood);
    try {
      await _api.saveMood(mood.name);
      final reco = await _api.getRecommendedActivities();
      if (mounted) setState(() => _recommended = reco);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Erreur lors de l'enregistrement de l'humeur"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _joinActivity(Activity activity) async {
    try {
      await _api.joinActivity(activity.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [const Icon(Icons.check_circle_rounded, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text('Vous avez rejoint "${activity.title}" !', style: const TextStyle(fontWeight: FontWeight.w500)))]),
        backgroundColor: const Color(0xFF22C55E), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), duration: const Duration(seconds: 3),
      ));
      _loadActivities();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_error != null && _user == null && !_loadingUser) return _buildErrorScreen();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(children: [
            _buildHeader(),
            _buildNavBar(),
            // ── Contenu selon l'onglet sélectionné ──────────────────
            Expanded(child: _buildCurrentPage()),
          ]),
        ),
      ),
    );
  }

  // ── Page selon l'onglet ──────────────────────────────────────────────────
  Widget _buildCurrentPage() {
    switch (_selectedNav) {
      case 0: // Accueil
        return RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFFD63FBF),
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 16),
                _buildWelcomeCard(),
                const SizedBox(height: 20),
                _buildProfileSection(),
                const SizedBox(height: 24),
                _buildMoodSection(),
                const SizedBox(height: 24),
                _buildRecommendedSection(),
                const SizedBox(height: 24),
                _buildActivitiesSection(),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        );

      case 1: // ✅ Explorer → ActivitiePage
        return const ActivitiePage();

      case 2: // Défis (placeholder)
        return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.emoji_events_rounded, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text('Défis — Bientôt disponible', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ]));

      case 3: // Communauté (placeholder)
        return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.people_rounded, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text('Communauté — Bientôt disponible', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ]));

      case 4: // Profil
        return RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFFD63FBF),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: _buildProfileSection(),
          ),
        );

      default:
        return const SizedBox();
    }
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFD63FBF), Color(0xFF9C27B0)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(12)),
          child: const Center(child: Text('WJ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
        const SizedBox(width: 12),
        const Text('WeJoy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFD63FBF), letterSpacing: -0.5)),
        const Spacer(),
        Stack(children: [
          IconButton(icon: const Icon(Icons.notifications_outlined), color: Colors.grey[700], onPressed: () {}),
          if (_notificationCount > 0) Positioned(top: 8, right: 8, child: Container(width: 18, height: 18,
            decoration: const BoxDecoration(color: Color(0xFFD63FBF), shape: BoxShape.circle),
            child: Center(child: Text('$_notificationCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))))),
        ]),
        const SizedBox(width: 4),
        IconButton(icon: const Icon(Icons.logout_rounded), color: Colors.grey[600], onPressed: () async {
          await _api.logout();
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        }),
      ]),
    );
  }

  // ─── NavBar ────────────────────────────────────────────────────────────────
  Widget _buildNavBar() {
    return Container(
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_navItems.length, (i) {
          final isSelected = _selectedNav == i;
          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _selectedNav = i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isSelected ? const Color(0xFFD63FBF) : Colors.transparent, width: 2.5))),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(_navItems[i]['icon'] as IconData, size: 22, color: isSelected ? const Color(0xFFD63FBF) : Colors.grey[500]),
                const SizedBox(height: 4),
                Text(_navItems[i]['label'] as String, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? const Color(0xFFD63FBF) : Colors.grey[600])),
              ]),
            ),
          ));
        }),
      ),
    );
  }

  // ─── Welcome Card ──────────────────────────────────────────────────────────
  Widget _buildWelcomeCard() {
    final name = _loadingUser ? '...' : (_user?.username.split('@')[0] ?? '');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFD63FBF), Color(0xFF9C27B0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFFD63FBF).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bienvenue, $name !', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          const Text('Connectez-vous, partagez et épanouissez-vous avec votre communauté.', style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4)),
        ])),
        const Text('👋', style: TextStyle(fontSize: 40)),
      ]),
    );
  }

  // ─── Profile Section ───────────────────────────────────────────────────────
  Widget _buildProfileSection() {
    if (_loadingUser) return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Center(child: CircularProgressIndicator(color: Color(0xFFD63FBF))));
    if (_user == null) return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Center(child: Text('Profil non disponible')));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))]),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Icon(Icons.person_outline_rounded, size: 18, color: Colors.grey[600]), const SizedBox(width: 8), const Text('Mon Profil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]),
          TextButton(onPressed: () {}, style: TextButton.styleFrom(foregroundColor: const Color(0xFFD63FBF), minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 12)), child: const Text('Modifier')),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Container(width: 70, height: 70,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFFD63FBF), Color(0xFF9C27B0)]), boxShadow: [BoxShadow(color: const Color(0xFFD63FBF).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Center(child: _user!.avatarUrl != null && _user!.avatarUrl!.isNotEmpty
              ? ClipOval(child: Image.network(_user!.avatarUrl!, fit: BoxFit.cover, width: 66, height: 66, errorBuilder: (_, __, ___) => const Text('👤', style: TextStyle(fontSize: 30))))
              : const Text('👤', style: TextStyle(fontSize: 30)))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_user!.username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Membre depuis ${_user!.memberSince}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ])),
        ]),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: _user!.interests.map((interest) {
          const icons = {'Cuisine': '🍳', 'Lecture': '📚', 'Jardinage': '🌱', 'Yoga': '🧘'};
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFD63FBF).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(icons[interest] ?? '•', style: const TextStyle(fontSize: 12)), const SizedBox(width: 4),
              Text(interest, style: const TextStyle(fontSize: 12, color: Color(0xFFD63FBF), fontWeight: FontWeight.w500)),
            ]),
          );
        }).toList()),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('🏆', style: TextStyle(fontSize: 20)), const SizedBox(width: 8), Text('${_user!.points}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFEAB308)))])),
            Container(width: 1, height: 30, color: Colors.grey[300]),
            Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('⭐', style: TextStyle(fontSize: 20)), const SizedBox(width: 8), Text('${_user!.badges}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFD63FBF)))])),
          ]),
        ),
      ]),
    );
  }

  // ─── Mood Section ──────────────────────────────────────────────────────────
  Widget _buildMoodSection() {
    final moods = [
      {'label': 'Excellent', 'emoji': '🌟', 'color': const Color(0xFF22C55E), 'mood': Mood.excellent},
      {'label': 'Bien', 'emoji': '😊', 'color': const Color(0xFF3B82F6), 'mood': Mood.bien},
      {'label': 'Neutre', 'emoji': '😐', 'color': const Color(0xFFF59E0B), 'mood': Mood.neutre},
      {'label': 'Triste', 'emoji': '😟', 'color': const Color(0xFFEF4444), 'mood': Mood.triste},
      {'label': 'Besoin de\nsoutien', 'emoji': '🤍', 'color': const Color(0xFFD63FBF), 'mood': Mood.besoinSoutien},
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Comment vous sentez-vous aujourd'hui ?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Row(children: moods.map((m) {
          final isSelected = _selectedMood == m['mood'];
          return Expanded(child: GestureDetector(
            onTap: () => _onMoodSelected(m['mood'] as Mood),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? (m['color'] as Color).withOpacity(0.1) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? (m['color'] as Color) : Colors.grey[200]!, width: isSelected ? 2 : 1),
              ),
              child: Column(children: [
                Text(m['emoji'] as String, style: TextStyle(fontSize: isSelected ? 24 : 20)),
                const SizedBox(height: 4),
                Text(m['label'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? (m['color'] as Color) : Colors.grey[600], height: 1.2)),
              ]),
            ),
          ));
        }).toList()),
      ]),
    );
  }

  // ─── Recommended Section ───────────────────────────────────────────────────
  Widget _buildRecommendedSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Activités recommandées', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        TextButton(
          onPressed: () => setState(() => _selectedNav = 1), // ← va vers Explorer
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFD63FBF)),
          child: const Text('Voir tout', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ]),
      Text('Activités recommandées pour vous', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      const SizedBox(height: 12),
      _loadingActivities
          ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFFD63FBF))))
          : _recommended.isEmpty
              ? _buildEmptyState('Aucune activité recommandée pour le moment')
              : SizedBox(
                  height: 280,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _recommended.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _buildRecommendedCard(_recommended[i]),
                  ),
                ),
    ]);
  }

  Widget _buildRecommendedCard(Activity activity) {
    return GestureDetector(
      onTap: () => setState(() => _selectedNav = 1), // ← tap sur carte → Explorer
      child: Container(
        width: 200,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(height: 100, width: double.infinity, color: Colors.grey[100],
                child: activity.imageUrl.isNotEmpty
                    ? Image.network(activity.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFFD63FBF).withOpacity(0.1), child: const Center(child: Icon(Icons.image_rounded, size: 30, color: Color(0xFFD63FBF)))))
                    : Container(color: const Color(0xFFD63FBF).withOpacity(0.1), child: const Center(child: Icon(Icons.image_rounded, size: 30, color: Color(0xFFD63FBF))))),
            ),
            Positioned(top: 8, right: 8, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
              child: Text(activity.isIndividual ? 'Individuel' : 'Collectif', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            )),
          ]),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(activity.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () => _joinActivity(activity),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Text(activity.isIndividual ? 'Commencer' : 'Rejoindre', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  // ─── Activities Section ────────────────────────────────────────────────────
  Widget _buildActivitiesSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Toutes les activités', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
        child: TextField(
          controller: _searchController,
          onChanged: (v) { _searchQuery = v; _filterActivities(); },
          decoration: InputDecoration(hintText: 'Rechercher une activité...', hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]), prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 20), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        ),
      ),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () { setState(() => _selectedCategory = cat); _filterActivities(); },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: isSelected ? const Color(0xFFD63FBF).withOpacity(0.1) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? const Color(0xFFD63FBF) : Colors.grey[300]!)),
              child: Text(cat, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? const Color(0xFFD63FBF) : Colors.grey[600])),
            ),
          );
        }).toList()),
      ),
      const SizedBox(height: 12),
      _loadingActivities
          ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFFD63FBF))))
          : _allActivities.isEmpty
              ? _buildEmptyState('Aucune activité trouvée')
              : ListView.separated(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  itemCount: _allActivities.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _buildActivityListItem(_allActivities[i]),
                ),
    ]);
  }

  Widget _buildActivityListItem(Activity activity) {
    return GestureDetector(
      onTap: () => setState(() => _selectedNav = 1),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: Container(width: 60, height: 60, color: const Color(0xFFD63FBF).withOpacity(0.1),
            child: activity.imageUrl.isNotEmpty ? Image.network(activity.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_rounded, color: Color(0xFFD63FBF))) : const Icon(Icons.image_rounded, color: Color(0xFFD63FBF)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(activity.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(activity.description, style: TextStyle(fontSize: 11, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Container(margin: const EdgeInsets.only(left: 8), child: ElevatedButton(
            onPressed: () => _joinActivity(activity),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text(activity.isIndividual ? 'Commencer' : 'Rejoindre', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          )),
        ]),
      ),
    );
  }

  Widget _buildEmptyState(String message) => Container(padding: const EdgeInsets.all(32), child: Column(children: [Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]), const SizedBox(height: 12), Text(message, style: TextStyle(color: Colors.grey[400], fontSize: 14))]));

  Widget _buildErrorScreen() => Scaffold(backgroundColor: Colors.white, body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle), child: const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red)),
    const SizedBox(height: 24),
    const Text('Oups ! Une erreur est survenue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    Text(_error ?? 'Impossible de charger les données', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
    const SizedBox(height: 24),
    ElevatedButton(onPressed: () { setState(() => _error = null); _loadData(); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD63FBF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Réessayer')),
  ]))));
}

enum Mood { excellent, bien, neutre, triste, besoinSoutien }