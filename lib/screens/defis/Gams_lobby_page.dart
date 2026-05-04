import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:wejoy/screens/defis/action_verite_page.dart';
import 'package:wejoy/screens/defis/home_screen.dart';
import 'package:wejoy/screens/defis/quiz.dart';
import 'package:wejoy/theme/theme_provider.dart';

// ── Palette fixe (ne change PAS avec le thème) ─────────────────────────────
const _gold   = Color(0xFFFFC857);
const _snow   = Color(0xFFF8F1EA);
const _card   = Color(0xFFFFFFFF);
const _ink    = Color(0xFF1F1A24);
const _slate  = Color(0xFF6E6A78);
const _border = Color(0xFFF1E6DD);

// ════════════════════════════════════════════════════════════════
// MODÈLE — les couleurs primaire/secondaire viennent du thème
// ════════════════════════════════════════════════════════════════
class GameInfo {
  final String id, emoji, title, description, players, difficulty, badge;
  final bool isXO;
  const GameInfo({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.players,
    required this.difficulty,
    required this.badge,
    this.isXO = false,
  });
}

const _gamesData = [
  GameInfo(
    id: 'xo', emoji: '❌⭕', title: 'Jeu XO',
    description: 'Le grand classique en multijoueur temps réel. Aligne 3 symboles !',
    players: '2 joueurs', difficulty: 'Facile',
    badge: '⚡ Rapide', isXO: true,
  ),
  GameInfo(
    id: 'action_verite', emoji: '🎭', title: 'Action ou Vérité',
    description: 'Pioche une carte et relève le défi ! Actions folles ou vérités gênantes.',
    players: '2 joueurs', difficulty: 'Fun',
    badge: '😂 Fun',
  ),
  GameInfo(
    id: 'quiz', emoji: '🧠', title: 'Quiz Bien-être',
    description: 'Testez vos connaissances sur la santé et le bien-être !',
    players: '2 joueurs', difficulty: 'Moyen',
    badge: '💡 Culture',
  ),
];

// ════════════════════════════════════════════════════════════════
// PAGE PRINCIPALE
// ════════════════════════════════════════════════════════════════
class GamesLobbyPage extends StatefulWidget {
  const GamesLobbyPage({super.key});
  @override
  State<GamesLobbyPage> createState() => _GamesLobbyPageState();
}

class _GamesLobbyPageState extends State<GamesLobbyPage>
    with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late AnimationController _cardsCtrl;
  late Animation<double>   _headerAnim;

  // ── Raccourcis ThemeProvider ──────────────────────────────────
  Color get _rose   => context.read<ThemeProvider>().color1;
  Color get _violet => context.read<ThemeProvider>().color2;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _cardsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();
    _headerAnim =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _cardsCtrl.dispose();
    super.dispose();
  }

  void _openGame(GameInfo game) {
    HapticFeedback.lightImpact();
    if (game.isXO) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (game.id == 'action_verite') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ActionVeritePage()));
    } else {
      // Capturer les couleurs avant le showModalBottomSheet (async gap)
      final rose   = _rose;
      final violet = _violet;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DefiBottomSheet(
          game: game,
          rose: rose,
          violet: violet,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ← Rebuild automatique quand le thème change
    context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: _snow,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _headerAnim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, -0.3), end: Offset.zero)
                          .animate(_headerAnim),
                      child: _buildHeader(),
                    ),
                  ),
                ),

                // Carte vedette
                SliverToBoxAdapter(
                  child: _AnimatedCard(
                    delay: 100,
                    controller: _cardsCtrl,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _FeaturedCard(
                        game: _gamesData[0],
                        primaryColor: _rose,
                        secondaryColor: _violet,
                        onTap: () => _openGame(_gamesData[0]),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Titre section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_rose, _violet],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('Tous les jeux',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _ink)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _rose.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${_gamesData.length} jeux',
                            style: TextStyle(
                                fontSize: 11,
                                color: _rose,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // Grille de jeux
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _AnimatedCard(
                        delay: 150 + i * 80,
                        controller: _cardsCtrl,
                        child: _GameGridCard(
                          game: _gamesData[i],
                          primaryColor: i % 2 == 0 ? _rose : _violet,
                          secondaryColor: i % 2 == 0 ? _violet : _rose,
                          onTap: () => _openGame(_gamesData[i]),
                        ),
                      ),
                      childCount: _gamesData.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(child: _buildStatsBar()),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFAF4EE), Color(0xFFF8EFE7), Color(0xFFFDF8F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      Positioned(
        top: -60, right: -40,
        child: Container(
          width: 180, height: 180,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: _rose.withOpacity(0.10)),
        ),
      ),
      Positioned(
        top: 120, left: -50,
        child: Container(
          width: 140, height: 140,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: _violet.withOpacity(0.08)),
        ),
      ),
      Positioned(
        bottom: 80, right: -30,
        child: Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: _gold.withOpacity(0.10)),
        ),
      ),
    ]);
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_rose, _violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: _rose.withOpacity(0.30),
              blurRadius: 24,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(children: [
        Positioned(
          right: -10, top: -10,
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08)),
          ),
        ),
        Positioned(
          right: 30, bottom: -20,
          child: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05)),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('🎮', style: TextStyle(fontSize: 13)),
              SizedBox(width: 6),
              Text('Jeux collaboratifs',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 14),
          const Text('Joue avec\ntes amis 🔥',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.15,
                letterSpacing: -0.5,
              )),
          const SizedBox(height: 8),
          Text('Choisis un jeu et défie tes proches en temps réel.',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.80),
                  height: 1.4)),
        ]),
      ]),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(children: [
        _StatItem('4',  'Jeux',    _rose),
        _wDivider(),
        _StatItem('2',  'Joueurs', _violet),
        _wDivider(),
        _StatItem('∞',  'Parties', _gold),
        _wDivider(),
        _StatItem('🔥', 'Fun',     _rose),
      ]),
    );
  }

  Widget _wDivider() => Container(
      width: 1,
      height: 32,
      color: _border,
      margin: const EdgeInsets.symmetric(horizontal: 8));
}

// ════════════════════════════════════════════════════════════════
// BOTTOM SHEET
// ════════════════════════════════════════════════════════════════
class _DefiBottomSheet extends StatefulWidget {
  final GameInfo game;
  final Color rose;
  final Color violet;
  const _DefiBottomSheet({
    required this.game,
    required this.rose,
    required this.violet,
  });
  @override
  State<_DefiBottomSheet> createState() => _DefiBottomSheetState();
}

class _DefiBottomSheetState extends State<_DefiBottomSheet>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  bool _isCreating = true;
  late AnimationController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roomCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty || _roomCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Remplis tous les champs !'),
        backgroundColor: widget.rose,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
      return;
    }
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DefiLobbyPage(
          roomId: _roomCtrl.text.trim().toUpperCase(),
          playerName: _nameCtrl.text.trim(),
          gameType: widget.game.id,
          game: widget.game,
          rose: widget.rose,
          violet: widget.violet,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
              child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: _border, borderRadius: BorderRadius.circular(2)),
          )),

          // En-tête jeu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [widget.rose, widget.violet]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: widget.rose.withOpacity(0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                alignment: Alignment.center,
                child: Text(widget.game.emoji,
                    style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                Text(widget.game.title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
                Text('${widget.game.players} · ${widget.game.difficulty}',
                    style: const TextStyle(fontSize: 12, color: _slate)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),

          // Onglets Créer / Rejoindre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: _snow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border)),
              child: Row(children: [
                _TabBtn('✨ Créer', _isCreating, widget.rose,
                    () => setState(() => _isCreating = true)),
                _TabBtn('🔑 Rejoindre', !_isCreating, widget.violet,
                    () => setState(() => _isCreating = false)),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // Champs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              _WejoyInputField(
                  controller: _nameCtrl,
                  hint: 'Ton prénom',
                  icon: Icons.person_outline_rounded,
                  rose: widget.rose),
              const SizedBox(height: 12),
              _WejoyInputField(
                controller: _roomCtrl,
                hint: _isCreating
                    ? 'Crée un code (ex: WEJOY)'
                    : 'Code de la room',
                icon: Icons.tag_rounded,
                caps: true,
                rose: widget.rose,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: widget.rose.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: widget.rose.withOpacity(0.12))),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: widget.rose.withOpacity(0.7)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                    _isCreating
                        ? 'Inventez un code et partagez-le avec votre ami'
                        : 'Entrez le code que votre ami vous a partagé',
                    style: TextStyle(
                        fontSize: 11,
                        color: _slate.withOpacity(0.8)),
                  )),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Bouton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [widget.rose, widget.violet]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: widget.rose.withOpacity(0.30),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      _isCreating ? 'Créer la partie' : 'Rejoindre',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );
}

// ════════════════════════════════════════════════════════════════
// LOBBY D'ATTENTE
// ════════════════════════════════════════════════════════════════
class _DefiLobbyPage extends StatefulWidget {
  final String roomId, playerName, gameType;
  final GameInfo game;
  final Color rose;
  final Color violet;
  const _DefiLobbyPage({
    required this.roomId,
    required this.playerName,
    required this.gameType,
    required this.game,
    required this.rose,
    required this.violet,
  });
  @override
  State<_DefiLobbyPage> createState() => _DefiLobbyPageState();
}

class _DefiLobbyPageState extends State<_DefiLobbyPage>
    with SingleTickerProviderStateMixin {
  late IO.Socket socket;
  Map<String, dynamic>? room;
  String? error;
  late AnimationController _pulseCtrl;

  static const _serverUrl = 'http://localhost:5000';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _connect();
  }

  void _connect() {
    socket = IO.io(
        _serverUrl,
        IO.OptionBuilder()
            .setTransports(['polling', 'websocket'])
            .disableAutoConnect()
            .enableReconnection()
            .build());
    socket.connect();

    socket.onConnect((_) {
      socket.emit('join_room', {
        'roomId':     widget.roomId,
        'playerName': widget.playerName,
        'gameType':   widget.gameType,
      });
    });

    socket.on('room_update', (data) {
      if (!mounted) return;
      setState(() {
        room  = Map<String, dynamic>.from(data);
        error = null;
      });
    });

    socket.on('room_full',
        (data) { if (mounted) setState(() => error = data['message']); });
    socket.on('player_left',
        (_) { if (mounted) setState(() => room = null); });
    socket.onConnectError((_) {
      if (mounted) setState(() => error = 'Impossible de se connecter au serveur');
    });

    socket.on('game_start', (data) {
      if (!mounted) return;
      final r = Map<String, dynamic>.from(data);
      setState(() => room = r);

      if (widget.gameType == 'action_verite') {
        socket.emit('av_ready', {
          'roomId':     widget.roomId,
          'playerName': widget.playerName,
        });
      } else if (widget.gameType == 'quiz') {
        socket.emit('quiz_ready', {
          'roomId':     widget.roomId,
          'playerName': widget.playerName,
        });
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _navigateToGame(r);
      });
    });
  }

  void _navigateToGame(Map<String, dynamic> r) {
    Widget page;
    switch (widget.gameType) {
      case 'action_verite':
        page = ActionVeritePage();
        break;
      case 'quiz':
      default:
        page = QuizPage(
            socket: socket, room: r, playerName: widget.playerName);
    }
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final players = (room?['players'] as List?) ?? [];
    final ready   = players.length >= 2;
    final rose    = widget.rose;
    final violet  = widget.violet;

    return Scaffold(
      backgroundColor: _snow,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _slate, size: 18),
          onPressed: () {
            socket.disconnect();
            Navigator.pop(context);
          },
        ),
        title: ShaderMask(
          shaderCallback: (b) =>
              LinearGradient(colors: [rose, violet]).createShader(b),
          child: Text(widget.game.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: Stack(children: [
        Positioned(
          top: -40, right: -30,
          child: Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: rose.withOpacity(0.07)),
          ),
        ),
        Positioned(
          bottom: 60, left: -30,
          child: Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: violet.withOpacity(0.06)),
          ),
        ),

        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Bannière jeu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [rose, violet],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: rose.withOpacity(0.30),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Row(children: [
                Text(widget.game.emoji,
                    style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                  Text(widget.game.title,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Partagez le code pour inviter un ami',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.80))),
                ])),
              ]),
            ),
            const SizedBox(height: 16),

            // Erreur
            if (error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.20)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFFEF4444), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(error!,
                          style: const TextStyle(
                              color: Color(0xFFEF4444), fontSize: 13))),
                ]),
              ),

            // Code room
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Column(children: [
                const Text('Code de la room',
                    style: TextStyle(
                        fontSize: 12,
                        color: _slate,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, child) => Transform.scale(
                      scale: ready
                          ? 1
                          : 0.97 + _pulseCtrl.value * 0.03,
                      child: child),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        rose.withOpacity(0.10),
                        violet.withOpacity(0.08),
                      ]),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: rose.withOpacity(0.25)),
                    ),
                    child: ShaderMask(
                      shaderCallback: (b) =>
                          LinearGradient(colors: [rose, violet])
                              .createShader(b),
                      child: Text(widget.roomId,
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 6)),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),

            // Joueurs
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Column(children: [
                Row(children: [
                  const Text('Joueurs',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: _ink)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: rose.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${players.length} / 2',
                        style: TextStyle(
                            color: rose,
                            fontWeight: FontWeight.w800,
                            fontSize: 12)),
                  ),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: _PlayerSlotWidget(
                    name: players.isNotEmpty ? players[0]['name'] : null,
                    symbol: 'X',
                    color: rose,
                    isMe: players.isNotEmpty
                        ? players[0]['name'] == widget.playerName
                        : false,
                  )),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10),
                    child: ShaderMask(
                      shaderCallback: (b) =>
                          LinearGradient(colors: [rose, violet])
                              .createShader(b),
                      child: const Text('VS',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontSize: 18)),
                    ),
                  ),
                  Expanded(
                      child: _PlayerSlotWidget(
                    name: players.length > 1
                        ? players[1]['name']
                        : null,
                    symbol: 'O',
                    color: violet,
                    isMe: players.length > 1
                        ? players[1]['name'] == widget.playerName
                        : false,
                  )),
                ]),
              ]),
            ),
            const SizedBox(height: 14),

            // Statut
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ready
                    ? const Color(0xFF10B981).withOpacity(0.07)
                    : rose.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: ready
                      ? const Color(0xFF10B981).withOpacity(0.20)
                      : rose.withOpacity(0.12),
                ),
              ),
              child: ready
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Color(0xFF10B981), size: 20),
                        SizedBox(width: 10),
                        Text('Tous les joueurs sont là !',
                            style: TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ])
                  : Column(children: [
                      SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: rose),
                      ),
                      const SizedBox(height: 10),
                      Text('En attente d\'un adversaire...',
                          style: TextStyle(
                              color: rose,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                          'La partie démarre dès que 2 joueurs sont présents.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _slate.withOpacity(0.7),
                              fontSize: 11)),
                    ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// WIDGETS UTILITAIRES
// ════════════════════════════════════════════════════════════════

class _FeaturedCard extends StatefulWidget {
  final GameInfo game;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback onTap;
  const _FeaturedCard({
    required this.game,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onTap,
  });
  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.primaryColor, widget.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: widget.primaryColor.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10))
              ],
            ),
            child: Stack(children: [
              Positioned(
                  right: -20,
                  top: -20,
                  child: _DecorCircle(80, widget.secondaryColor)),
              Positioned(
                  right: 40,
                  bottom: -30,
                  child: _DecorCircle(60, widget.primaryColor)),
              Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('⭐ Jeu vedette',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                      const Spacer(),
                      Text(widget.game.emoji,
                          style: const TextStyle(fontSize: 32)),
                    ]),
                    const Spacer(),
                    Text(widget.game.title,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Flexible(
                          child: Text(widget.game.description,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.80)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 16)),
                    ]),
                  ])),
            ]),
          ),
        ),
      );
}

class _GameGridCard extends StatefulWidget {
  final GameInfo game;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback onTap;
  const _GameGridCard({
    required this.game,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onTap,
  });
  @override
  State<_GameGridCard> createState() => _GameGridCardState();
}

class _GameGridCardState extends State<_GameGridCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 130),
          child: Container(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 6))
              ],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Container(
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.primaryColor.withOpacity(0.85),
                      widget.secondaryColor.withOpacity(0.70)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Stack(children: [
                  Positioned(
                      right: -10,
                      top: -10,
                      child: _DecorCircle(50, widget.secondaryColor)),
                  Center(
                      child: Text(widget.game.emoji,
                          style: const TextStyle(fontSize: 38))),
                ]),
              ),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                  Text(widget.game.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                  const SizedBox(height: 3),
                  Text(widget.game.description,
                      style: const TextStyle(
                          fontSize: 10, color: _slate, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(widget.game.badge,
                          style: TextStyle(
                              fontSize: 9,
                              color: widget.primaryColor,
                              fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            widget.primaryColor,
                            widget.secondaryColor
                          ]),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 13)),
                  ]),
                ]),
              )),
            ]),
          ),
        ),
      );
}

class _AnimatedCard extends StatelessWidget {
  final Widget child;
  final int delay;
  final AnimationController controller;
  const _AnimatedCard(
      {required this.child,
      required this.delay,
      required this.controller});
  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(delay / 1000, math.min(1.0, (delay + 400) / 1000),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, ch) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
            offset: Offset(0, 30 * (1 - anim.value)), child: ch),
      ),
      child: child,
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _DecorCircle(this.size, this.color);
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: color.withOpacity(0.15)),
      );
}

class _StatItem extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatItem(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) =>
      Expanded(child: Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: _slate)),
      ]));
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _TabBtn(this.label, this.active, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color:
                  active ? color.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: active
                      ? color.withOpacity(0.25)
                      : Colors.transparent),
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? color : _slate)),
          ),
        ),
      );
}

class _WejoyInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool caps;
  final Color rose;
  const _WejoyInputField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.rose,
    this.caps = false,
  });
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        textCapitalization:
            caps ? TextCapitalization.characters : TextCapitalization.words,
        style: const TextStyle(color: _ink, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: _slate.withOpacity(0.5), fontSize: 13),
          prefixIcon:
              Icon(icon, size: 18, color: _slate.withOpacity(0.6)),
          filled: true,
          fillColor: _snow,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: rose, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
}

class _PlayerSlotWidget extends StatelessWidget {
  final String? name;
  final String symbol;
  final Color color;
  final bool isMe;
  const _PlayerSlotWidget(
      {this.name,
      required this.symbol,
      required this.color,
      required this.isMe});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: name != null ? color.withOpacity(0.07) : _snow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: name != null ? color.withOpacity(0.22) : _border),
        ),
        child: Column(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: name != null
                  ? color.withOpacity(0.12)
                  : _border.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(symbol,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: name != null
                        ? color
                        : _slate.withOpacity(0.3))),
          ),
          const SizedBox(height: 8),
          Text(name ?? 'En attente...',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    name != null ? FontWeight.w700 : FontWeight.w400,
                color: name != null ? _ink : _slate.withOpacity(0.5),
              )),
          if (isMe && name != null) ...[
            const SizedBox(height: 4),
            Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('Toi',
                    style: TextStyle(
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.w700))),
          ],
        ]),
      );
}