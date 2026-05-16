import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Truth or dare screen..dart';
import 'home_screen.dart';
import 'memorypage.dart';
import 'quiz_screen.dart';
import 'would_you_rather_screen.dart';
import 'package:wejoy/screens/service/socket_service.dart';

class GamesHub extends StatefulWidget {
  const GamesHub({super.key});
  @override
  State<GamesHub> createState() => _GamesHubState();
}

class _GamesHubState extends State<GamesHub> {
  static const _bg        = Color(0xFFFDF6FF);
  static const _card      = Color(0xFFFFFFFF);
  static const _cardTint  = Color(0xFFF8F0FF);
  static const _pink      = Color(0xFFEC4899);
  static const _violet    = Color(0xFF8B5CF6);
  static const _textDark  = Color(0xFF1E1B2E);
  static const _textMid   = Color(0xFF6B7280);
  static const _textLight = Color(0xFFB0A8C0);
  static const _amber     = Color(0xFFF59E0B);
  static const _teal      = Color(0xFF0D9488);
  static const _coral     = Color(0xFFF43F5E);

  String _playerName = 'Joueur';

  @override
  void initState() {
    super.initState();
    _loadPlayerName();
    SocketService().connect();
  }

  Future<void> _loadPlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _playerName = prefs.getString('username') ?? 'Joueur');
  }

  // ─────────────────────────────────────────────────────────
  //  _openLobby — FIX : on écoute lobby_update en premier
  //  et on le transmet via initialPlayers à l'écran cible
  // ─────────────────────────────────────────────────────────
  void _openLobby(
    String game,
    String title,
    Color color,
    Widget Function(String roomId, bool isHost, List<dynamic> initialPlayers) builder,
  ) {
    final codeCtrl = TextEditingController();
    bool creating  = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: _textLight.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: _textDark)),
            const SizedBox(height: 6),
            const Text('Joue avec tes amis en temps réel',
              style: TextStyle(fontSize: 13, color: _textMid)),
            const SizedBox(height: 28),

            // ── Créer une partie ──────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: creating ? null : () {
                  setModal(() => creating = true);
                  Navigator.pop(ctx); // ferme le bottom sheet

                  final socket = SocketService();

                  // ✅ FIX : on prépare une liste qui sera
                  // remplie par lobby_update AVANT la navigation
                  final List<dynamic> initialPlayers = [];

                  // Écoute lobby_update en premier (il arrive
                  // juste après game_room_created côté backend)
                  void lobbyHandler(dynamic data) {
                    final players = data['players'] ?? [];
                    initialPlayers
                      ..clear()
                      ..addAll(players);
                  }
                  socket.on('lobby_update', lobbyHandler);

                  // Écoute game_room_created pour naviguer
                  void roomHandler(dynamic data) {
                    socket.off('game_room_created');
                    // On enlève notre handler temporaire —
                    // l'écran cible va re-écouter lobby_update
                    socket.off('lobby_update');

                    final roomId = data['roomId']?.toString() ?? '';
                    if (!mounted) return;

                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => builder(roomId, true, initialPlayers)));
                  }
                  socket.on('game_room_created', roomHandler);

                  // Émet la création (déclenche lobby_update
                  // puis game_room_created côté serveur)
                  socket.createGameRoom(game, _playerName);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                  elevation: 0),
                child: const Text('Créer une partie',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),

            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Divider(color: _textLight.withOpacity(0.3))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text('ou rejoindre',
                  style: TextStyle(color: _textLight, fontSize: 12))),
              Expanded(child: Divider(color: _textLight.withOpacity(0.3))),
            ]),
            const SizedBox(height: 16),

            // ── Rejoindre ─────────────────────────────────
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700,
                letterSpacing: 5, color: _textDark),
              decoration: InputDecoration(
                hintText: 'CODE',
                hintStyle: const TextStyle(
                  fontSize: 16, letterSpacing: 3, color: _textLight),
                filled: true, fillColor: _cardTint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: color.withOpacity(0.6), width: 1.5)),
                contentPadding:
                  const EdgeInsets.symmetric(vertical: 18)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  final code = codeCtrl.text.trim().toUpperCase();
                  if (code.isEmpty) return;
                  Navigator.pop(ctx);

                  final socket = SocketService();

                  void handler(dynamic data) {
                    socket.off('game_room_joined');
                    socket.off('error');
                    final roomId = data['roomId']?.toString() ?? '';
                    if (!mounted) return;
                    // Pour rejoindre, initialPlayers = []
                    // → lobby_update arrivera dans l'écran cible
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => builder(roomId, false, [])));
                  }
                  void errHandler(dynamic data) {
                    socket.off('game_room_joined');
                    socket.off('error');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(data['message'] ?? 'Erreur'),
                      backgroundColor: Colors.red.shade700));
                  }
                  socket.on('game_room_joined', handler);
                  socket.on('error', errHandler);
                  socket.joinGameRoom(code, _playerName);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: color.withOpacity(0.5), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
                child: const Text('Rejoindre',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _goToXO() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));

  void _goToMemory() => _openLobby(
    'memory', 'Memory 🃏', _violet,
    (r, h, init) => MemoryLobbyScreen(
      roomId: r, playerName: _playerName, isHost: h, initialPlayers: init));

  void _goToQuiz() => _openLobby(
    'quiz', 'Quiz 🧠', _teal,
    (r, h, init) => QuizScreen(
      roomId: r, playerName: _playerName, isHost: h, initialPlayers: init));

  void _goToWyr() => _openLobby(
    'wyr', 'Ce que je préfère 💬', _coral,
    (r, h, init) => WouldYouRatherScreen(
      roomId: r, playerName: _playerName, isHost: h, initialPlayers: init));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Header ──
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    ).createShader(b),
                    child: const Text('Défis', style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  const Text('🎮', style: TextStyle(fontSize: 22)),
                ]),
                const SizedBox(height: 3),
                const Text('Joue avec tes amis en temps réel',
                  style: TextStyle(fontSize: 13, color: _textMid)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _violet.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _violet.withOpacity(0.2)),
                ),
                child: Row(children: [
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('En ligne', style: TextStyle(
                    fontSize: 12, color: _violet, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),

            const SizedBox(height: 24),

            // ── Hero banner ──
            _HeroBanner(onTap: _goToMemory),

            const SizedBox(height: 24),

            // ── Section titre ──
            Row(children: [
              Container(width: 3, height: 14,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              const Text('TOUS LES JEUX', style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: _textLight, letterSpacing: 1.8)),
              const Spacer(),
              const Text('4 jeux', style: TextStyle(
                fontSize: 11, color: _textLight, fontWeight: FontWeight.w500)),
            ]),

            const SizedBox(height: 14),

            // ── Grille ──
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12, mainAxisSpacing: 12,
              childAspectRatio: 0.82,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _GameCard(
                  emoji: '✕', title: 'Jeu XO',
                  description: 'Morpion classique contre un ami en ligne.',
                  gradientColors: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  tag: '2 joueurs', tagIcon: '⚡', onTap: _goToXO,
                ),
                _GameCard(
                  emoji: '⚡', title: 'Action ou Vérité',
                  description: 'Défis et questions entre amis.',
                  gradientColors: const [Color(0xFFEC4899), Color(0xFFF97316)],
                  tag: '2–4 joueurs', tagIcon: '🔥',
                  onTap: () => _openLobby(
                    'tod', 'Action ou Vérité ⚡', _pink,
                    (r, h, init) => TruthOrDareScreen(
                      roomId: r, playerName: _playerName,
                      isHost: h, initialPlayers: init)),
                ),
                _GameCard(
                  emoji: '🧠', title: 'Quiz Bien-être',
                  description: 'Testez vos connaissances sur la santé et le bien-être !',
                  gradientColors: const [Color(0xFF0D9488), Color(0xFF06B6D4)],
                  tag: '2–4 joueurs', tagIcon: '🏆', onTap: _goToQuiz,
                ),
                _GameCard(
                  emoji: '💬', title: 'Ce que je préfère',
                  description: 'Vote et découvre ce que pensent tes amis.',
                  gradientColors: const [Color(0xFFF43F5E), Color(0xFFEC4899)],
                  tag: 'Nouveau', tagIcon: '✨', onTap: _goToWyr,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Streak bar ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _pink.withOpacity(0.12)),
                boxShadow: [BoxShadow(
                  color: _pink.withOpacity(0.06),
                  blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Row(children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _amber.withOpacity(0.2))),
                  alignment: Alignment.center,
                  child: const Text('🔥', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Streak actif', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _textDark)),
                  SizedBox(height: 2),
                  Text('Continue à jouer chaque jour !',
                    style: TextStyle(fontSize: 12, color: _textMid)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _amber.withOpacity(0.2))),
                  child: const Text('🏆', style: TextStyle(fontSize: 18)),
                ),
              ]),
            ),

            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  HERO BANNER
// ═══════════════════════════════════════════════════════════

class _HeroBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _HeroBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFFEC4899), Color(0xFFFF6B9D)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.35),
            blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20)),
            child: const Text('🎮 Jeux collaboratifs', style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(height: 16),
          const Text('Joue avec\ntes amis 🔥', style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w900,
            color: Colors.white, height: 1.2)),
          const SizedBox(height: 8),
          Text('Choisis un jeu et défie tes proches en temps réel.',
            style: TextStyle(
              fontSize: 13, color: Colors.white.withOpacity(0.85), height: 1.4)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('🃏', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text('Jouer au Memory', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: Color(0xFF7C3AED))),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  GAME CARD
// ═══════════════════════════════════════════════════════════

class _GameCard extends StatelessWidget {
  final String emoji, title, description, tag, tagIcon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _GameCard({
    required this.emoji, required this.title, required this.description,
    required this.gradientColors, required this.tag, required this.tagIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Stack(children: [
          Positioned(top: -20, right: -20,
            child: Container(width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08)))),
          Positioned(top: 10, right: 10,
            child: Container(width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08)))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Expanded(child: Text(description, style: TextStyle(
                fontSize: 11, color: Colors.white.withOpacity(0.8), height: 1.4))),
              const SizedBox(height: 10),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text('$tagIcon $tag', style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
                const Spacer(),
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 18),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  MEMORY LOBBY — avec initialPlayers
// ═══════════════════════════════════════════════════════════

class MemoryLobbyScreen extends StatefulWidget {
  final String roomId, playerName;
  final bool isHost;
  final List<dynamic> initialPlayers;   // ✅ AJOUT

  const MemoryLobbyScreen({
    super.key, required this.roomId, required this.playerName,
    required this.isHost, this.initialPlayers = const [],
  });
  @override
  State<MemoryLobbyScreen> createState() => _MemoryLobbyScreenState();
}

class _MemoryLobbyScreenState extends State<MemoryLobbyScreen> {
  final SocketService _socket = SocketService();
  late List<dynamic> _players;  // ✅ initialisé depuis widget

  static const _bg        = Color(0xFFFDF6FF);
  static const _card      = Color(0xFFFFFFFF);
  static const _violet    = Color(0xFF8B5CF6);
  static const _pink      = Color(0xFFEC4899);
  static const _textDark  = Color(0xFF1E1B2E);
  static const _textMid   = Color(0xFF6B7280);
  static const _textLight = Color(0xFFB0A8C0);

  @override
  void initState() {
    super.initState();
    // ✅ On part avec les players déjà capturés dans GamesHub
    _players = List<dynamic>.from(widget.initialPlayers);

    _socket.on('lobby_update', (data) {
      if (!mounted) return;
      setState(() => _players = data['players'] ?? []);
    });
    _socket.on('game_start', (data) {
      if (!mounted) return;
      final room = {'id': widget.roomId, 'players': _players, 'state': data['state']};
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => MemoryPage(
          socket: _socket.socket!, room: room, playerName: widget.playerName)));
    });
  }

  @override
  void dispose() {
    _socket.off('lobby_update');
    _socket.off('game_start');
    super.dispose();
  }

  void _startGame() =>
      _socket.socket?.emit('memory_start', {'roomId': widget.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _textMid, size: 16),
          onPressed: () {
            _socket.leaveGameRoom(widget.roomId);
            Navigator.pop(context);
          },
        ),
        title: const Text('Memory 🃏', style: TextStyle(
          color: _textDark, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _violet.withOpacity(0.15)),
              boxShadow: [BoxShadow(
                color: _violet.withOpacity(0.07),
                blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Column(children: [
              const Text('Code de la salle',
                style: TextStyle(fontSize: 13, color: _textMid)),
              const SizedBox(height: 8),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [_violet, _pink]).createShader(b),
                child: Text(widget.roomId, style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.w800,
                  color: Colors.white, letterSpacing: 6)),
              ),
              const SizedBox(height: 4),
              const Text('Partage ce code avec tes amis',
                style: TextStyle(fontSize: 12, color: _textLight)),
            ]),
          ),

          const SizedBox(height: 20),
          const Text('JOUEURS', style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: _textLight, letterSpacing: 1.5)),
          const SizedBox(height: 12),

          ..._players.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _violet.withOpacity(0.1)),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_violet, _pink]),
                  borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text((p['name'] ?? '?')[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(p['name'] ?? '',
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: _textDark))),
              if (p['name'] == widget.playerName)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _violet.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _violet.withOpacity(0.2))),
                  child: const Text('Toi', style: TextStyle(
                    fontSize: 10, color: _violet, fontWeight: FontWeight.w700))),
            ]),
          )),

          const Spacer(),

          if (widget.isHost) ...[
            if (_players.length < 2)
              const Text('En attente d\'un adversaire...',
                style: TextStyle(fontSize: 13, color: _textMid)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _players.length >= 2 ? _startGame : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  disabledBackgroundColor: const Color(0xFFE5E7EB)),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: _players.length >= 2
                        ? const LinearGradient(colors: [_violet, _pink])
                        : null,
                    color: _players.length < 2
                        ? const Color(0xFFE5E7EB) : null,
                    borderRadius: BorderRadius.circular(14)),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('Lancer la partie', style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: _players.length >= 2 ? Colors.white : _textMid)),
                  ),
                ),
              ),
            ),
          ] else
            const Text('En attente que l\'hôte lance la partie...',
              style: TextStyle(fontSize: 13, color: _textMid)),
        ]),
      ),
    );
  }
}