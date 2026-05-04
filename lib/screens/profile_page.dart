import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wejoy/screens/edit_profile_page.dart';
import 'package:wejoy/screens/service/api_service.dart';
import 'package:wejoy/theme/theme_provider.dart'; // adapte le chemin si besoin

// ── Palette fixe ───────────────────────────────────────────────────────────
const _ink    = Color(0xFF0F0F1A);
const _slate  = Color(0xFF64748B);
const _snow   = Color(0xFFF8FAFC);
const _card   = Color(0xFFFFFFFF);
const _border = Color(0xFFEEEEF5);
const _gold   = Color(0xFFF59E0B);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  final _api = ApiService();
  UserProfile? _user;
  bool _loading = true;
  bool _editing = false;
  bool _saving  = false;

  late AnimationController _headerCtrl;
  late Animation<double>   _headerAnim;

  final _usernameCtrl = TextEditingController();
  final List<String> _allInterests = [
    'Cuisine', 'Lecture', 'Jardinage', 'Yoga', 'Sport', 'Autre',
  ];
  List<String> _selectedInterests = [];

  // ── Raccourcis vers le provider ────────────────────────────────────────
  ThemeProvider get _tp => context.read<ThemeProvider>();
  Color get _c1 => context.watch<ThemeProvider>().color1;
  Color get _c2 => context.watch<ThemeProvider>().color2;
  bool  get _dark => context.watch<ThemeProvider>().isDark;

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
      if (mounted) {
        setState(() {
          _user = user;
          _usernameCtrl.text  = user?.username ?? '';
          _selectedInterests  = List.from(user?.interests ?? []);
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
        'username':  _usernameCtrl.text.trim(),
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
        builder: (_) => EditProfilePage(user: _user!, onProfileUpdated: _load),
      ),
    );
  }

  bool _isNetworkImage(String? v) =>
      v != null && (v.startsWith('http://') || v.startsWith('https://'));

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
        color: _c1.withOpacity(0.15),
        child: Center(child: Text(avatar, style: const TextStyle(fontSize: 38))),
      );
    }
    return _avatarFallback();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      backgroundColor: error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Sélecteur de thème
  // ══════════════════════════════════════════════════════════════════════════
  void _showThemePicker() {
    int  selectedIdx = _tp.themeIdx;
    bool darkMode    = _tp.isDark;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          final previewC1 = kThemes[selectedIdx]['c1'] as Color;
          final previewC2 = kThemes[selectedIdx]['c2'] as Color;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              width: 380,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── En-tête ─────────────────────────────────────────────
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [previewC1, previewC2]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.palette_outlined,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Thème de l\'application',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _ink),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Grille couleurs ─────────────────────────────────────
                  const Text('COULEUR PRINCIPALE',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _slate,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(kThemes.length, (i) {
                      final t  = kThemes[i];
                      final ok = selectedIdx == i;
                      return GestureDetector(
                        onTap: () => setS(() => selectedIdx = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                                colors: [t['c1'] as Color, t['c2'] as Color]),
                            border: Border.all(
                                color: ok ? _ink : Colors.transparent,
                                width: 3),
                            boxShadow: ok
                                ? [BoxShadow(
                                    color: (t['c1'] as Color).withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3))]
                                : [],
                          ),
                          child: ok
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),

                  // ── Mode clair / sombre ─────────────────────────────────
                  const Text('MODE D\'AFFICHAGE',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _slate,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _modeBtnWidget(
                      label: '☀️  Clair',
                      active: !darkMode,
                      onTap: () => setS(() => darkMode = false),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _modeBtnWidget(
                      label: '🌙  Sombre',
                      active: darkMode,
                      onTap: () => setS(() => darkMode = true),
                    )),
                  ]),
                  const SizedBox(height: 20),

                  // ── Prévisualisation ────────────────────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [previewC1, previewC2]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          darkMode
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${kThemes[selectedIdx]['name']}  •  '
                          '${darkMode ? 'Sombre' : 'Clair'}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Boutons ─────────────────────────────────────────────
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _slate,
                        side: const BorderSide(color: _border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Annuler',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: previewC1,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        // ← Applique globalement via le provider
                        _tp.applyTheme(selectedIdx, darkMode);
                        Navigator.pop(ctx);
                        _snack('Thème appliqué ✅');
                      },
                      child: const Text('Appliquer',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    )),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _modeBtnWidget({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? _snow : _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? _slate : _border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? _ink : _slate,
            )),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Contacter l'admin
  // ══════════════════════════════════════════════════════════════════════════
  void _showContactAdmin() {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String selectedType = 'Problème technique';
    final types = [
      'Problème technique', 'Signaler un utilisateur',
      'Suggestion', 'Question générale', 'Autre',
    ];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_c1, _c2]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.support_agent_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contacter l\'administrateur',
                            style: TextStyle(fontSize: 16,
                                fontWeight: FontWeight.w700, color: _ink)),
                        SizedBox(height: 2),
                        Text('Nous répondons sous 24h',
                            style: TextStyle(fontSize: 11, color: _slate)),
                      ],
                    )),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  const Text('Type de demande',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600, color: _ink)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _snow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedType,
                        isExpanded: true,
                        style: const TextStyle(fontSize: 13, color: _ink),
                        items: types.map((t) =>
                            DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setS(() => selectedType = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: subjectCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: _fieldDeco('Sujet', Icons.subject_rounded),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: messageCtrl,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13),
                    decoration: _fieldDeco('Votre message', Icons.message_outlined),
                  ),
                  const SizedBox(height: 20),

                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _slate,
                        side: const BorderSide(color: _border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Annuler',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _c1,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (subjectCtrl.text.trim().isEmpty ||
                            messageCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text('Veuillez remplir tous les champs'),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        }
                        Navigator.pop(ctx);
                        try {
                          await _api.contactAdmin(
                            sujet: '$selectedType : ${subjectCtrl.text.trim()}',
                            message: messageCtrl.text.trim(),
                          );
                          if (mounted) _snack('Message envoyé ✅');
                        } catch (e) {
                          if (mounted) _snack('Erreur: $e', error: true);
                        }
                      },
                      child: const Text('Envoyer',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    )),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDeco(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: _slate.withOpacity(0.7), fontSize: 13),
    prefixIcon: Icon(icon, size: 18, color: _slate.withOpacity(0.5)),
    filled: true,
    fillColor: _snow,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _c1, width: 2)),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Build principal
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // context.watch déclenche le rebuild quand le thème change
    context.watch<ThemeProvider>();

    if (_loading) {
      return CustomScrollView(
        slivers: [SliverToBoxAdapter(child: _buildSkeleton())],
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: _c1,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: _dark ? const Color(0xFF1A1A2E) : _card,
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
              child: Container(height: 1, color: _border),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStats(),
                  const SizedBox(height: 30),
                  _buildInterests(),
                  const SizedBox(height: 30),
                  _buildSettings(),
                  const SizedBox(height: 42),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Header ───────────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_c1, _c2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(top: -30, right: -30, child: Container(
          width: 160, height: 160,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
        )),
        Positioned(bottom: -20, left: -20, child: Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            shape: BoxShape.circle,
          ),
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )],
                  ),
                  child: ClipOval(child: _buildAvatarContent()),
                ),
                Positioned(bottom: 0, right: 0, child: GestureDetector(
                  onTap: _openEditProfilePage,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: _editing ? const Color(0xFF10B981) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                      )],
                    ),
                    child: Icon(
                      _editing ? Icons.check_rounded : Icons.edit_rounded,
                      size: 14,
                      color: _editing ? Colors.white : _c1,
                    ),
                  ),
                )),
              ]),
              const SizedBox(height: 12),
              if (_editing)
                Container(
                  width: 200, height: 38,
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
                        fontSize: 16),
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
                      letterSpacing: -0.5),
                ),
              const SizedBox(height: 4),
              Text(
                'Membre depuis ${_user?.memberSince ?? ''}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
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
      color: _c1.withOpacity(0.3),
      child: Center(child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
      )),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────
  Widget _buildStats() {
    return Row(children: [
      Expanded(child: _statCard('Points',  '${_user?.points ?? 0}',
          Icons.emoji_events_rounded, _gold,  '🏆')),
      const SizedBox(width: 12),
      Expanded(child: _statCard('Badges',  '${_user?.badges ?? 0}',
          Icons.star_rounded,         _c1,    '⭐')),
      const SizedBox(width: 12),
      Expanded(child: _statCard('Niveau',  '${_user?.badges ?? 1}',
          Icons.local_fire_department_rounded, _c2, '🔥')),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon,
      Color color, String emoji) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: _dark ? const Color(0xFF1A1A2E) : _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(
          color: color.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        )],
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(
            fontSize: 11, color: _slate, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ── Intérêts ──────────────────────────────────────────────────────────────
  Widget _buildInterests() {
    return _sectionCard(
      title: 'Centres d\'intérêt',
      icon: Icons.favorite_border_rounded,
      iconColor: _c1,
      trailing: _editing
          ? GestureDetector(
              onTap: _saving ? null : _saveProfile,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_c1, _c2]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Sauvegarder',
                        style: TextStyle(color: Colors.white,
                            fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            )
          : null,
      child: _editing
          ? Wrap(
              spacing: 8, runSpacing: 8,
              children: _allInterests.map((interest) {
                final sel = _selectedInterests.contains(interest);
                return GestureDetector(
                  onTap: () => setState(() {
                    sel ? _selectedInterests.remove(interest)
                        : _selectedInterests.add(interest);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _c1 : _snow,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: sel ? _c1 : _border, width: 1.5),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_interestEmoji(interest),
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text(interest, style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : _slate)),
                      if (sel) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white),
                      ],
                    ]),
                  ),
                );
              }).toList(),
            )
          : _selectedInterests.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: _slate.withOpacity(0.5)),
                    const SizedBox(width: 8),
                    Text('Aucun centre d\'intérêt',
                        style: TextStyle(
                            color: _slate.withOpacity(0.6), fontSize: 13)),
                  ]),
                )
              : Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _selectedInterests.map((i) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        _c1.withOpacity(0.1),
                        _c2.withOpacity(0.08),
                      ]),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _c1.withOpacity(0.2)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_interestEmoji(i),
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 5),
                      Text(i, style: TextStyle(
                          fontSize: 12, color: _c1,
                          fontWeight: FontWeight.w600)),
                    ]),
                  )).toList(),
                ),
    );
  }

  String _interestEmoji(String i) {
    const m = {
      'Cuisine': '🍳', 'Lecture': '📚', 'Jardinage': '🌱',
      'Yoga': '🧘', 'Sport': '⚽', 'Autre': '✨',
    };
    return m[i] ?? '•';
  }

  // ── Paramètres ────────────────────────────────────────────────────────────
  Widget _buildSettings() {
    return _sectionCard(
      title: 'Compte',
      icon: Icons.settings_outlined,
      iconColor: _slate,
      child: Column(children: [
        _settingRow(
          Icons.palette_outlined,
          'Thème de l\'application',
          _c2,
          _showThemePicker,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [_c1, _c2]),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              _dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 14, color: _slate,
            ),
            const SizedBox(width: 4),
          ]),
        ),
        _divider(),
        _settingRow(
          Icons.support_agent_rounded,
          'Contacter l\'administrateur',
          _c1,
          _showContactAdmin,
        ),
      ]),
    );
  }

  Widget _settingRow(
    IconData icon, String label, Color color, VoidCallback onTap,
    {Widget? trailing}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, color: _ink))),
          if (trailing != null) trailing,
          Icon(Icons.chevron_right_rounded,
              size: 18, color: _slate.withOpacity(0.4)),
        ]),
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
        color: _dark ? const Color(0xFF1A1A2E) : _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(
          color: _ink.withOpacity(0.03),
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
          const Spacer(),
          if (trailing != null) trailing,
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }

  // ── Skeleton ──────────────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return SingleChildScrollView(
      child: Column(children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_c1, _c2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            _skeletonBox(height: 100, radius: 20),
            const SizedBox(height: 16),
            _skeletonBox(height: 120, radius: 20),
          ]),
        ),
      ]),
    );
  }

  Widget _skeletonBox({required double height, double radius = 12}) {
    return Container(
      height: height, width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}