import 'package:wejoy/screens/edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wejoy/screens/service/api_service.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const _rose = Color(0xFFD63FBF);
const _violet = Color(0xFF7C3AED);
const _ink = Color(0xFF0F0F1A);
const _slate = Color(0xFF64748B);
const _snow = Color(0xFFF8FAFC);
const _card = Color(0xFFFFFFFF);
const _border = Color(0xFFEEEEF5);
const _gold = Color(0xFFF59E0B);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  final _api = ApiService();
  UserProfile? _user;
  List<Activity> _myActivities = [];
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;

  late AnimationController _headerCtrl;
  late Animation<double> _headerAnim;

  final _usernameCtrl = TextEditingController();
  final List<String> _allInterests = [
    'Cuisine',
    'Lecture',
    'Jardinage',
    'Yoga',
    'Sport',
    'Autre',
  ];
  List<String> _selectedInterests = [];

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerAnim = CurvedAnimation(
      parent: _headerCtrl,
      curve: Curves.easeOutCubic,
    );
    _load();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await _api.getMyProfile();
      final activities = await _api.getAllActivities();
      if (mounted) {
        setState(() {
          _user = user;
          _myActivities =
              activities.where((a) => a.currentParticipants > 0).toList();
          _usernameCtrl.text = user?.username ?? '';
          _selectedInterests = List.from(user?.interests ?? []);
        });
        _headerCtrl.forward(from: 0);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await _api.updateProfile({
        'username': _usernameCtrl.text.trim(),
        'interests': _selectedInterests,
      });
      await _load();
      setState(() => _editing = false);
      if (mounted) _snack('Profil mis à jour ✅');
    } catch (e) {
      if (mounted) _snack('Erreur: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openEditProfilePage() async {
    if (_user == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          user: _user!,
          onProfileUpdated: _load,
        ),
      ),
    );
  }

  bool _isNetworkImage(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.startsWith('http://') || value.startsWith('https://');
  }

  Widget _buildAvatarContent() {
    final avatar = _user?.avatarUrl;

    if (_isNetworkImage(avatar)) {
      return CachedNetworkImage(
        imageUrl: avatar!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _avatarFallback(),
      );
    }

    if (avatar != null && avatar.isNotEmpty) {
      return Container(
        color: _rose.withOpacity(0.15),
        child: Center(
          child: Text(
            avatar,
            style: const TextStyle(fontSize: 38),
          ),
        ),
      );
    }

    return _avatarFallback();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        backgroundColor:
            error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton();

    return Scaffold(
      backgroundColor: _snow,
      body: RefreshIndicator(
        onRefresh: _load,
        color: _rose,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: _card,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: AnimatedBuilder(
                  animation: _headerAnim,
                  builder: (_, __) => FadeTransition(
                    opacity: _headerAnim,
                    child: _buildHeroHeader(),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0),
                child: Container(
                  height: 1,
                  color: _border,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStats(),
                    const SizedBox(height: 20),
                    _buildInterests(),
                    const SizedBox(height: 20),
                    _buildMyActivities(),
                    const SizedBox(height: 20),
                    _buildSettings(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_rose, _violet],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -30,
          right: -30,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -20,
          left: -20,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _buildAvatarContent(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _openEditProfilePage,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _editing
                              ? const Color(0xFF10B981)
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          _editing ? Icons.check_rounded : Icons.edit_rounded,
                          size: 14,
                          color: _editing ? Colors.white : _rose,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_editing)
                Container(
                  width: 200,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: TextField(
                    controller: _usernameCtrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: 'Nom d\'utilisateur',
                      hintStyle: TextStyle(color: Colors.white60),
                    ),
                  ),
                )
              else
                Text(
                  _user?.username ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'Membre depuis ${_user?.memberSince ?? ''}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatarFallback() {
    final name = _user?.username ?? '?';
    return Container(
      color: _rose.withOpacity(0.3),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Points',
            '${_user?.points ?? 0}',
            Icons.emoji_events_rounded,
            _gold,
            '🏆',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            'Badges',
            '${_user?.badges ?? 0}',
            Icons.star_rounded,
            _rose,
            '⭐',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            'Activités',
            '${_myActivities.length}',
            Icons.local_fire_department_rounded,
            _violet,
            '🔥',
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String emoji,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _slate,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterests() {
    return _sectionCard(
      title: 'Centres d\'intérêt',
      icon: Icons.favorite_border_rounded,
      iconColor: _rose,
      trailing: _editing
          ? GestureDetector(
              onTap: _saving ? null : _saveProfile,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_rose, _violet]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Sauvegarder',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            )
          : null,
      child: _editing
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allInterests.map((interest) {
                final sel = _selectedInterests.contains(interest);
                return GestureDetector(
                  onTap: () => setState(() {
                    sel
                        ? _selectedInterests.remove(interest)
                        : _selectedInterests.add(interest);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _rose : _snow,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: sel ? _rose : _border,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _interestEmoji(interest),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          interest,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : _slate,
                          ),
                        ),
                        if (sel) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            )
          : _selectedInterests.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: _slate.withOpacity(0.5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aucun centre d\'intérêt — appuyez sur Modifier',
                        style: TextStyle(
                          color: _slate.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedInterests
                      .map(
                        (i) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _rose.withOpacity(0.1),
                                _violet.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border:
                                Border.all(color: _rose.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _interestEmoji(i),
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                i,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _rose,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
    );
  }

  String _interestEmoji(String i) {
    const m = {
      'Cuisine': '🍳',
      'Lecture': '📚',
      'Jardinage': '🌱',
      'Yoga': '🧘',
      'Sport': '⚽',
      'Autre': '✨',
    };
    return m[i] ?? '•';
  }

  Widget _buildMyActivities() {
    return _sectionCard(
      title: 'Mes activités',
      icon: Icons.calendar_today_rounded,
      iconColor: _violet,
      child: _myActivities.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.explore_outlined,
                    size: 16,
                    color: _slate.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Vous n\'avez rejoint aucune activité',
                    style: TextStyle(
                      color: _slate.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: _myActivities.take(4).map((a) => _activityRow(a)).toList(),
            ),
    );
  }

  Widget _activityRow(Activity a) {
    const catColors = {
      'Cuisine': Color(0xFFFF6B6B),
      'Lecture': Color(0xFF4ECDC4),
      'Yoga': Color(0xFF96CEB4),
      'Sport': _violet,
      'Jardinage': Color(0xFF45B7D1),
      'Autre': _slate,
    };
    final color = catColors[a.category] ?? _slate;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _categoryEmoji(a.category),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  a.category,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Rejoint',
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryEmoji(String c) {
    const m = {
      'Cuisine': '🍳',
      'Lecture': '📚',
      'Jardinage': '🌱',
      'Yoga': '🧘',
      'Sport': '⚽',
      'Autre': '✨',
    };
    return m[c] ?? '•';
  }

  Widget _buildSettings() {
    return _sectionCard(
      title: 'Compte',
      icon: Icons.settings_outlined,
      iconColor: _slate,
      child: Column(
        children: [
          _settingRow(
            Icons.edit_outlined,
            'Modifier le profil',
            _rose,
            _openEditProfilePage,
          ),
          _divider(),
          _settingRow(
            Icons.lock_outline_rounded,
            'Changer le mot de passe',
            _violet,
            () {},
          ),
          _divider(),
          _settingRow(
            Icons.notifications_outlined,
            'Notifications',
            _slate,
            () {},
          ),
          _divider(),
          _settingRow(
            Icons.logout_rounded,
            'Se déconnecter',
            const Color(0xFFEF4444),
            () async {
              await _api.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _settingRow(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _ink,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: _slate.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: _border, indent: 48);

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Scaffold(
      backgroundColor: _snow,
      body: Column(
        children: [
          Container(
            height: 240,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_rose, _violet],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _skeletonBox(height: 100, radius: 20),
                const SizedBox(height: 16),
                _skeletonBox(height: 120, radius: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonBox({required double height, double radius = 12}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}