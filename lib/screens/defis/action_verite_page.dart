import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:wejoy/screens/service/socket_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
class C {
  static const bg       = Color(0xFF0D0620);
  static const bgDeep   = Color(0xFF130830);
  static const violet   = Color(0xFF7C3AED);
  static const purple   = Color(0xFF9D1FCE);
  static const pink     = Color(0xFFEC4899);
  static const rose     = Color(0xFFF472B6);
  static const blue     = Color(0xFF3B82F6);
  static const cyan     = Color(0xFF06B6D4);
  static const gold     = Color(0xFFFBBF24);
  static const success  = Color(0xFF10B981);
  static const sub      = Color(0xFFB39DCA);
  static const card     = Color(0xFF1E0F38);
  static const cardBord = Color(0xFF3D1F6B);
}
// ══════════════════════════════════════════════════════════════════════════════
// ENTRY POINT
// ══════════════════════════════════════════════════════════════════════════════
class ActionVeritePage extends StatelessWidget {
  const ActionVeritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider()..init(),
      child: const GameRouter(),
    );
  }
}
class GameRouter extends StatelessWidget {
  const GameRouter({super.key});
  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    return switch (game.state) {
      GameState.idle            => const Home(),
      GameState.lobby           => const LobbyScreen(),
      GameState.choosingType || GameState.showingQuestion || GameState.playing => const GameScreen(),
      GameState.gameOver        => const ResultScreen(),
    };
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PROVIDER
// ══════════════════════════════════════════════════════════════════════════════
enum GameState { idle, lobby, playing, choosingType, showingQuestion, gameOver }

class Player {
  final String id, name;
  int score;
  Player({required this.id, required this.name, this.score = 0});
  factory Player.fromMap(Map<String, dynamic> m) =>
      Player(id: m['id'] ?? '', name: m['name'] ?? '', score: m['score'] ?? 0);
}

class GameProvider extends ChangeNotifier {
  final _socket = SocketService();
  GameState _state = GameState.idle;
  String _roomCode = '', _myId = '', _myName = '';
  List<Player> _players = [];
  Player? _current;
  String _qType = '', _question = '', _error = '';
  bool _connected = false;
  Map<String, String> _answers = {};

  GameState get state     => _state;
  String get roomCode     => _roomCode;
  String get myPlayerId   => _myId;
  List<Player> get players => _players;
  Player? get currentPlayer => _current;
  String get questionType => _qType;
  String get question     => _question;
  String get errorMessage => _error;
  bool get isConnected    => _connected;
  bool get isMyTurn       => _current?.id == _myId;
  Map<String, String> get answers => _answers;

  void init() {
    _socket.connect();
    _socket.on('connect',    (_) { _connected = true;  notifyListeners(); });
    _socket.on('disconnect', (_) { _connected = false; notifyListeners(); });
    _socket.on('room_created',   (d) { _roomCode = d['code']; _myId = d['player']['id']; _state = GameState.lobby; notifyListeners(); });
    _socket.on('room_joined',    (d) { _roomCode = d['code']; _myId = d['player']['id']; _state = GameState.lobby; notifyListeners(); });
    _socket.on('player_joined',  (d) { _players = _pl(d['players']); notifyListeners(); });
    _socket.on('game_started',   (d) { _players = _pl(d['players']); _current = Player.fromMap(d['currentPlayer']); _answers = {}; _state = GameState.choosingType; notifyListeners(); });
    _socket.on('question_assigned', (d) { _current = Player.fromMap(d['currentPlayer']); _qType = d['type']; _question = d['question']; _answers = {}; _state = GameState.showingQuestion; notifyListeners(); });
    _socket.on('turn_changed',   (d) { _players = _pl(d['players']); _current = Player.fromMap(d['currentPlayer']); _answers = {}; _state = GameState.choosingType; notifyListeners(); });
    _socket.on('game_ended',     (d) { _players = _pl(d['players']); _state = GameState.gameOver; notifyListeners(); });
    _socket.on('player_left',    (d) { _players = _pl(d['players']); _current = Player.fromMap(d['currentPlayer']); notifyListeners(); });
    _socket.on('answer_received',(d) { _answers[d['playerId']] = d['answer']; notifyListeners(); });
    _socket.on('error',          (d) { _error = d['message'] ?? 'Erreur'; notifyListeners(); });
  }

  List<Player> _pl(List l) => l.map((p) => Player.fromMap(p)).toList();

  void createRoom(String n) { _myName = n; _socket.emit('create_room', {'playerName': n}); }
  void joinRoom(String c, String n) { _myName = n; _socket.emit('join_room', {'code': c, 'playerName': n}); }
  void startGame()  => _socket.emit('start_game',  {'code': _roomCode});
  void chooseType(String t) => _socket.emit('choose_type', {'code': _roomCode, 'type': t});
  void nextTurn({required bool completed}) => _socket.emit('next_turn', {'code': _roomCode, 'completed': completed});
  void endGame()    => _socket.emit('end_game',    {'code': _roomCode});
  void submitAnswer(String a) { _answers[_myId] = a; _socket.emit('submit_answer', {'code': _roomCode, 'playerId': _myId, 'playerName': _myName, 'answer': a}); notifyListeners(); }
  void clearError() { _error = ''; notifyListeners(); }
  void reset()      { _state = GameState.idle; _roomCode = ''; _players = []; _current = null; _question = ''; _answers = {}; notifyListeners(); }

  @override void dispose() { _socket.disconnect(); super.dispose(); }
}

// ══════════════════════════════════════════════════════════════════════════════
// ANIMATED BACKGROUND
// ══════════════════════════════════════════════════════════════════════════════
class AnimatedBg extends StatefulWidget {
  final Widget child;
  const AnimatedBg({super.key, required this.child});
  @override State<AnimatedBg> createState() => _AnimatedBgState();
}

class _AnimatedBgState extends State<AnimatedBg> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, child) => Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.lerp(Alignment.topLeft,    Alignment.topCenter,    _anim.value)!,
          end:   Alignment.lerp(Alignment.bottomRight, Alignment.bottomCenter, _anim.value)!,
          colors: const [Color(0xFF130828), Color(0xFF1A0540), Color(0xFF0D1547)],
          stops: const [0, 0.5, 1],
        ),
      ),
      child: Stack(children: [
        // Orbes flottantes
        _Orb(x: 0.15, y: 0.12, r: 160, color: C.violet,  anim: _anim, phase: 0),
        _Orb(x: 0.85, y: 0.25, r: 120, color: C.pink,    anim: _anim, phase: 0.4),
        _Orb(x: 0.5,  y: 0.72, r: 140, color: C.blue,    anim: _anim, phase: 0.7),
        _Orb(x: 0.1,  y: 0.80, r: 80,  color: C.purple,  anim: _anim, phase: 0.2),
        _Orb(x: 0.9,  y: 0.60, r: 90,  color: C.cyan,    anim: _anim, phase: 0.9),
        child!,
      ]),
    ),
    child: widget.child,
  );
}

class _Orb extends StatelessWidget {
  final double x, y, r, phase;
  final Color color;
  final Animation<double> anim;
  const _Orb({required this.x, required this.y, required this.r, required this.color, required this.anim, required this.phase});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dy = math.sin((anim.value + phase) * math.pi) * 20;
    return Positioned(
      left:  size.width  * x - r,
      top:   size.height * y - r + dy,
      child: Container(
        width: r * 2, height: r * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withOpacity(0.25), color.withOpacity(0)]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════════════════════════════════════
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? glow;
  const GlassCard({super.key, required this.child, this.padding, this.glow});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: (glow ?? Colors.white).withOpacity(0.15), width: 1.5),
      boxShadow: glow != null ? [BoxShadow(color: glow!.withOpacity(0.2), blurRadius: 24, spreadRadius: 2)] : [],
    ),
    child: child,
  );
}

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final List<Color> colors;
  final double height;
  final Widget? icon;
  const GradientButton({super.key, required this.label, this.onTap, required this.colors, this.height = 56, this.icon});

  @override State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) { if (widget.onTap != null) _ctrl.forward(); },
    onTapUp:     (_) { _ctrl.reverse(); widget.onTap?.call(); HapticFeedback.lightImpact(); },
    onTapCancel: ()  { _ctrl.reverse(); },
    child: ScaleTransition(
      scale: _scale,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          gradient: widget.onTap != null
            ? LinearGradient(colors: widget.colors)
            : null,
          color: widget.onTap == null ? Colors.white12 : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: widget.onTap != null ? [BoxShadow(color: widget.colors.first.withOpacity(0.45), blurRadius: 20, offset: const Offset(0, 6))] : [],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (widget.icon != null) ...[widget.icon!, const Gap(8)],
          Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ]),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// HOME SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class Home extends StatefulWidget {
  const Home({super.key});
  @override State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _isJoining = false;
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoScale, _logoGlow;

  @override
  void initState() {
    super.initState();
    _logoCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _logoScale = Tween(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeInOut));
    _logoGlow  = Tween(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeInOut));
  }

  @override void dispose() { _logoCtrl.dispose(); _nameCtrl.dispose(); _codeCtrl.dispose(); super.dispose(); }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: C.purple, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    if (game.errorMessage.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) { _err(game.errorMessage); game.clearError(); });
    }

    return Scaffold(
      body: AnimatedBg(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(children: [
                // Logo animé
                AnimatedBuilder(
                  animation: _logoCtrl,
                  builder: (_, __) => ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [C.violet, C.pink]),
                        boxShadow: [
                          BoxShadow(color: C.violet.withOpacity(_logoGlow.value), blurRadius: 40, spreadRadius: 6),
                          BoxShadow(color: C.pink.withOpacity(_logoGlow.value * 0.7), blurRadius: 60, spreadRadius: 2),
                        ],
                      ),
                      child: const Center(child: Text('🎭', style: TextStyle(fontSize: 52))),
                    ),
                  ),
                ),
                const Gap(22),
                Text('Action ou Vérité',
                  style: GoogleFonts.raleway(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white,
                    shadows: [Shadow(color: C.pink.withOpacity(0.8), blurRadius: 24), Shadow(color: C.violet.withOpacity(0.6), blurRadius: 48)])),
                const Gap(6),
                Text('Multijoueur en temps réel ✨', style: TextStyle(color: C.sub, fontSize: 14)),
                const Gap(36),

                GlassCard(
                  glow: C.violet,
                  child: Column(children: [
                    _Field(ctrl: _nameCtrl, hint: 'Ton prénom', icon: '👤'),
                    const Gap(14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SlideTransition(
                        position: Tween(begin: const Offset(0, 0.2), end: Offset.zero).animate(anim), child: child)),
                      child: !_isJoining
                        ? Column(key: const ValueKey('create'), children: [
                            SizedBox(width: double.infinity, child: GradientButton(label: '✨ Créer une salle', onTap: () {
                              final n = _nameCtrl.text.trim();
                              if (n.isEmpty) { _err('Entre ton prénom !'); return; }
                              context.read<GameProvider>().createRoom(n);
                            }, colors: const [C.violet, C.pink])),
                            const Gap(10),
                            TextButton(onPressed: () => setState(() => _isJoining = true),
                              child: Text('Rejoindre une salle →', style: TextStyle(color: C.rose))),
                          ])
                        : Column(key: const ValueKey('join'), children: [
                            _Field(ctrl: _codeCtrl, hint: 'Code de la salle', icon: '🔑', isCode: true, maxLen: 5),
                            const Gap(12),
                            SizedBox(width: double.infinity, child: GradientButton(label: '🚀 Rejoindre', onTap: () {
                              final n = _nameCtrl.text.trim(), c = _codeCtrl.text.trim().toUpperCase();
                              if (n.isEmpty || c.isEmpty) { _err('Prénom et code requis'); return; }
                              context.read<GameProvider>().joinRoom(c, n);
                            }, colors: const [C.blue, C.cyan])),
                            const Gap(10),
                            TextButton(onPressed: () => setState(() => _isJoining = false),
                              child: Text('← Créer une salle', style: TextStyle(color: C.sub))),
                          ]),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint, icon;
  final bool isCode;
  final int? maxLen;
  const _Field({required this.ctrl, required this.hint, required this.icon, this.isCode = false, this.maxLen});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl, maxLength: maxLen,
    style: TextStyle(color: Colors.white, letterSpacing: isCode ? 8 : 0, fontWeight: isCode ? FontWeight.bold : FontWeight.normal, fontSize: isCode ? 20 : 15),
    textCapitalization: isCode ? TextCapitalization.characters : TextCapitalization.words,
    decoration: InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: C.sub.withOpacity(0.6)),
      prefixIcon: Padding(padding: const EdgeInsets.only(left: 14, right: 8), child: Text(icon, style: const TextStyle(fontSize: 20))),
      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      counterText: '',
      filled: true, fillColor: Colors.white.withOpacity(0.07),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: C.violet.withOpacity(0.35))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: C.pink, width: 1.5)),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// LOBBY SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isHost = game.players.isNotEmpty && game.players.first.id == game.myPlayerId;

    return Scaffold(
      body: AnimatedBg(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _BackBtn(onTap: () => context.read<GameProvider>().reset()),
                const Spacer(),
                _ConnBadge(ok: game.isConnected),
              ]),
              const Gap(14),
              Text('Salle d\'attente', style: GoogleFonts.raleway(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
              const Gap(12),

              // Code cliquable
              GestureDetector(
                onTap: () { Clipboard.setData(ClipboardData(text: game.roomCode)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Code copié !'))); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [C.violet.withOpacity(0.4), C.pink.withOpacity(0.3)]),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: C.rose.withOpacity(0.6)),
                    boxShadow: [BoxShadow(color: C.violet.withOpacity(0.3), blurRadius: 20)],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('🔑 ', style: const TextStyle(fontSize: 18)),
                    Text('Code : ', style: TextStyle(color: C.sub, fontSize: 14)),
                    Text(game.roomCode, style: GoogleFonts.sourceCodePro(fontSize: 26, fontWeight: FontWeight.w900,
                      color: Colors.white, letterSpacing: 10,
                      shadows: [Shadow(color: C.pink.withOpacity(0.8), blurRadius: 12)])),
                    const Gap(10),
                    Icon(Icons.copy_rounded, color: C.sub, size: 16),
                  ]),
                ),
              ),
              const Gap(18),
              Text('Joueurs (${game.players.length}/8)', style: TextStyle(color: C.sub, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const Gap(10),

              Expanded(
                child: ListView.builder(
                  itemCount: game.players.length,
                  itemBuilder: (_, i) {
                    final p = game.players[i]; final isMe = p.id == game.myPlayerId;
                    return _PlayerTile(player: p, isMe: isMe, isHost: i == 0, index: i);
                  },
                ),
              ),

              SizedBox(width: double.infinity, child: isHost
                ? GradientButton(
                    label: game.players.length >= 2 ? '▶  Démarrer la partie' : '⏳ En attente…',
                    onTap: game.players.length >= 2 ? () => context.read<GameProvider>().startGame() : null,
                    colors: const [C.violet, C.pink])
                : GlassCard(child: Center(child: Text('⏳ L\'hôte va démarrer…', style: TextStyle(color: C.sub))))),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final Player player; final bool isMe, isHost; final int index;
  const _PlayerTile({required this.player, required this.isMe, required this.isHost, required this.index});

  static const _avatars = ['🦊','🐺','🐯','🦁','🐻','🦄','🐸','🐙'];
  static const _colors  = [C.violet, C.pink, C.blue, C.cyan, C.purple, Color(0xFFE85D30), Color(0xFF059669), Color(0xFFDC2626)];

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      gradient: isMe ? LinearGradient(colors: [C.violet.withOpacity(0.35), C.pink.withOpacity(0.2)]) : null,
      color: isMe ? null : Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isMe ? C.rose.withOpacity(0.6) : Colors.white.withOpacity(0.08), width: 1.5),
      boxShadow: isMe ? [BoxShadow(color: C.violet.withOpacity(0.25), blurRadius: 16)] : [],
    ),
    child: Row(children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle,
        color: _colors[index % _colors.length].withOpacity(0.3),
        border: Border.all(color: _colors[index % _colors.length].withOpacity(0.6))),
        child: Center(child: Text(_avatars[index % _avatars.length], style: const TextStyle(fontSize: 20)))),
      const Gap(12),
      Expanded(child: Text(player.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
      if (isHost) const Text('👑', style: TextStyle(fontSize: 18)),
      if (isMe) ...[const Gap(6), Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [C.violet, C.pink]), borderRadius: BorderRadius.circular(20)),
        child: const Text('Moi', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))],
    ]),
  );
}

class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 40, height: 40,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.15))),
      child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white54, size: 18)),
  );
}

class _ConnBadge extends StatelessWidget {
  final bool ok;
  const _ConnBadge({required this.ok});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: (ok ? C.success : Colors.red).withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: (ok ? C.success : Colors.red).withOpacity(0.4))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      CircleAvatar(radius: 4, backgroundColor: ok ? C.success : Colors.red),
      const Gap(6),
      Text(ok ? 'En ligne' : 'Hors ligne', style: TextStyle(color: ok ? C.success : Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// GAME SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    return Scaffold(
      body: AnimatedBg(
        child: SafeArea(
          child: Column(children: [
            _PlayersBar(players: game.players, myId: game.myPlayerId, currentId: game.currentPlayer?.id ?? ''),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) => FadeTransition(opacity: anim,
                  child: SlideTransition(position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(anim), child: child)),
                child: game.state == GameState.choosingType
                  ? _ChooseWheel(game: game, key: const ValueKey('wheel'))
                  : _QuestionCard(game: game, key: const ValueKey('question')),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Barre joueurs ────────────────────────────────────────────────────────────
class _PlayersBar extends StatelessWidget {
  final List<Player> players; final String myId, currentId;
  const _PlayersBar({required this.players, required this.myId, required this.currentId});

  static const _avatars = ['🦊','🐺','🐯','🦁','🐻','🦄','🐸','🐙'];
  static const _colors  = [C.violet, C.pink, C.blue, C.cyan, C.purple, Color(0xFFE85D30), Color(0xFF059669), Color(0xFFDC2626)];

  @override
  Widget build(BuildContext context) => Container(
    height: 70,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.25),
      border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.07))),
    ),
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: players.length,
      itemBuilder: (_, i) {
        final p = players[i];
        final isMe      = p.id == myId;
        final isCurrent = p.id == currentId;
        final col       = _colors[i % _colors.length];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Stack(alignment: Alignment.topRight, children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: col.withOpacity(isCurrent ? 0.4 : 0.15),
                  border: Border.all(color: isCurrent ? col : Colors.white.withOpacity(0.2), width: isCurrent ? 2.5 : 1.5),
                  boxShadow: isCurrent ? [BoxShadow(color: col.withOpacity(0.6), blurRadius: 14, spreadRadius: 2)] : [],
                ),
                child: Center(child: Text(_avatars[i % _avatars.length], style: TextStyle(fontSize: isCurrent ? 22 : 18))),
              ),
              if (isCurrent) Container(width: 12, height: 12,
                decoration: BoxDecoration(shape: BoxShape.circle, color: C.gold,
                  border: Border.all(color: C.bg, width: 1.5),
                  boxShadow: [BoxShadow(color: C.gold.withOpacity(0.6), blurRadius: 6)]),
                child: const Center(child: Text('', style: TextStyle(fontSize: 6)))),
            ]),
            const Gap(4),
            Text(p.name, style: TextStyle(color: isCurrent ? Colors.white : C.sub, fontSize: 10, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal)),
            Text('${p.score}⭐', style: TextStyle(color: isCurrent ? C.gold : C.sub.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold)),
          ]),
        );
      },
    ),
  );
}

// ─── Roue / Boutons Action–Vérité ─────────────────────────────────────────────
class _ChooseWheel extends StatefulWidget {
  final GameProvider game;
  const _ChooseWheel({super.key, required this.game});
  @override State<_ChooseWheel> createState() => _ChooseWheelState();
}

class _ChooseWheelState extends State<_ChooseWheel> with TickerProviderStateMixin {
  late final AnimationController _bounce, _glow;
  late final Animation<double> _bounceAnim, _glowAnim;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _bounceAnim = Tween(begin: 0.0, end: -10.0).animate(CurvedAnimation(parent: _bounce, curve: Curves.easeInOut));
    _glow = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowAnim = Tween(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _glow, curve: Curves.easeInOut));
  }
  @override void dispose() { _bounce.dispose(); _glow.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        // Indicateur tour
        AnimatedBuilder(
          animation: _bounceAnim,
          builder: (_, child) => Transform.translate(offset: Offset(0, _bounceAnim.value), child: child),
          child: Column(children: [
            Text(game.isMyTurn ? 'C\'est ton tour ! 🎉' : 'Tour de...', style: TextStyle(color: C.sub, fontSize: 15)),
            const Gap(6),
            Text(game.currentPlayer?.name ?? '',
              style: GoogleFonts.raleway(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white,
                shadows: [Shadow(color: C.pink.withOpacity(0.9), blurRadius: 20), Shadow(color: C.violet.withOpacity(0.6), blurRadius: 40)])),
          ]),
        ),
        const Gap(20),

        if (game.isMyTurn) ...[
          // Cercle central interactif
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [C.violet, C.pink]),
                boxShadow: [
                  BoxShadow(color: C.violet.withOpacity(_glowAnim.value * 0.6), blurRadius: 40, spreadRadius: 6),
                  BoxShadow(color: C.pink.withOpacity(_glowAnim.value * 0.4), blurRadius: 60),
                ],
              ),
              child: const Center(child: Text('🎯', style: TextStyle(fontSize: 54))),
            ),
          ),
          const Gap(10),
          Text('Choisis ton défi', style: TextStyle(color: C.sub, fontSize: 13)),
          const Gap(16),

          // Cartes Action / Vérité
          Row(children: [
            Expanded(child: _WheelCard(emoji: '🤔', label: 'Vérité', sub: 'Réponds honnêtement', colors: const [Color(0xFF4C1D95), C.violet],
              glow: C.violet, onTap: () { HapticFeedback.mediumImpact(); context.read<GameProvider>().chooseType('truth'); })),
            const Gap(14),
            Expanded(child: _WheelCard(emoji: '🎭', label: 'Action', sub: 'Relève le défi', colors: const [C.purple, C.pink],
              glow: C.pink, onTap: () { HapticFeedback.mediumImpact(); context.read<GameProvider>().chooseType('dare'); })),
          ]),
        ] else
          GlassCard(
            glow: C.violet,
            child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [
              const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(C.rose), strokeWidth: 2.5)),
              const Gap(14),
              Text('${game.currentPlayer?.name} réfléchit…', style: TextStyle(color: C.sub, fontSize: 15)),
            ])),
          ),

        const Gap(20),
        if (game.players.isNotEmpty && game.players.first.id == game.myPlayerId)
          TextButton(onPressed: () => context.read<GameProvider>().endGame(),
            child: Text('Terminer la partie', style: TextStyle(color: C.sub.withOpacity(0.5), fontSize: 12))),
      ]),
    );
  }
}

class _WheelCard extends StatefulWidget {
  final String emoji, label, sub;
  final List<Color> colors;
  final Color glow;
  final VoidCallback onTap;
  const _WheelCard({required this.emoji, required this.label, required this.sub, required this.colors, required this.glow, required this.onTap});
  @override State<_WheelCard> createState() => _WheelCardState();
}

class _WheelCardState extends State<_WheelCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 130));
    _scale = Tween(begin: 1.0, end: 0.93).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ctrl.forward(),
    onTapUp:   (_) { _ctrl.reverse(); widget.onTap(); },
    onTapCancel: () => _ctrl.reverse(),
    child: ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: widget.colors.map((c) => c.withOpacity(0.35)).toList()),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: widget.glow.withOpacity(0.6), width: 1.5),
          boxShadow: [BoxShadow(color: widget.glow.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Column(children: [
          Text(widget.emoji, style: const TextStyle(fontSize: 44)),
          const Gap(10),
          Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const Gap(4),
          Text(widget.sub, style: TextStyle(color: C.sub, fontSize: 11), textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}

// ─── Card Question + Réponse ──────────────────────────────────────────────────
class _QuestionCard extends StatefulWidget {
  final GameProvider game;
  const _QuestionCard({super.key, required this.game});
  @override State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> with SingleTickerProviderStateMixin {
  final _answerCtrl = TextEditingController();
  bool _submitted = false;
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutBack));
    _slideCtrl.forward();
  }
  @override void dispose() { _slideCtrl.dispose(); _answerCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final game   = widget.game;
    final isDare  = game.questionType == 'dare';
    final mainCol = isDare ? C.pink    : C.violet;
    final secCol  = isDare ? C.rose    : C.cyan;
    final emoji   = isDare ? '🎭'       : '🤔';
    final label   = isDare ? 'Action'  : 'Vérité';

    return SlideTransition(
      position: _slideAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Badge
          Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [mainCol.withOpacity(0.6), secCol.withOpacity(0.4)]),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: mainCol.withOpacity(0.8)),
              boxShadow: [BoxShadow(color: mainCol.withOpacity(0.45), blurRadius: 20)],
            ),
            child: Text('$emoji  $label', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5)),
          )),
          const Gap(12),
          Center(child: Text(game.currentPlayer?.name ?? '',
            style: GoogleFonts.raleway(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white,
              shadows: [Shadow(color: mainCol.withOpacity(0.8), blurRadius: 16)]))),
          const Gap(18),

          // Carte question animée
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [mainCol.withOpacity(0.22), secCol.withOpacity(0.10)]),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: mainCol.withOpacity(0.55), width: 1.5),
              boxShadow: [BoxShadow(color: mainCol.withOpacity(0.25), blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Column(children: [
              Text(isDare ? '⚡' : '💬', style: const TextStyle(fontSize: 32)),
              const Gap(10),
              Text(game.question,
                style: GoogleFonts.poppins(fontSize: 19, color: Colors.white, height: 1.55, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            ]),
          ),
          const Gap(22),

          // Champ réponse
          Text('💬  Ta réponse', style: TextStyle(color: C.sub, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const Gap(8),
          if (!_submitted)
            Column(children: [
              TextField(
                controller: _answerCtrl, maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: game.isMyTurn ? 'Décris ta réponse ou action…' : 'Commente la question…',
                  hintStyle: TextStyle(color: C.sub.withOpacity(0.5)),
                  filled: true, fillColor: Colors.white.withOpacity(0.07),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: mainCol.withOpacity(0.4))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: mainCol, width: 1.8)),
                ),
              ),
              const Gap(10),
              SizedBox(width: double.infinity, child: GradientButton(
                label: 'Envoyer ma réponse',
                colors: [mainCol, secCol],
                height: 50,
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                onTap: () {
                  final ans = _answerCtrl.text.trim();
                  if (ans.isEmpty) return;
                  context.read<GameProvider>().submitAnswer(ans);
                  setState(() => _submitted = true);
                  HapticFeedback.lightImpact();
                },
              )),
            ])
          else
            GlassCard(glow: C.success, child: Row(children: [
              const Icon(Icons.check_circle_rounded, color: C.success, size: 22),
              const Gap(6),
              Expanded(child: Text(_answerCtrl.text, style: const TextStyle(color: Colors.white, fontSize: 14))),
            ])),

          // Réponses des autres
          if (game.answers.isNotEmpty) ...[
            const Gap(18),
            Text('👥  Réponses', style: TextStyle(color: C.sub, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const Gap(8),
            ...game.answers.entries.map((e) {
              final pl = game.players.firstWhere((p) => p.id == e.key, orElse: () => Player(id: '', name: '?'));
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: mainCol.withOpacity(0.2)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('💬', style: const TextStyle(fontSize: 16)),
                  const Gap(10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(pl.name, style: TextStyle(color: mainCol, fontSize: 12, fontWeight: FontWeight.w700)),
                    const Gap(2),
                    Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ])),
                ]),
              );
            }),
          ],

          const Gap(18),
          if (game.isMyTurn)
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () { setState(() => _submitted = false); context.read<GameProvider>().nextTurn(completed: false); HapticFeedback.lightImpact(); },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2))),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.close_rounded, color: Colors.white54, size: 20), Gap(6),
                    Text('Passer', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600)),
                  ]),
                ),
              )),
              const Gap(12),
              Expanded(child: GradientButton(
                label: '✓  Réussi !', height: 52,
                colors: const [Color(0xFF065F46), C.success],
                onTap: () { setState(() => _submitted = false); context.read<GameProvider>().nextTurn(completed: true); HapticFeedback.mediumImpact(); },
              )),
            ])
          else
            Center(child: Text('👀  Regardez ${game.currentPlayer?.name} !',
              style: TextStyle(color: C.sub, fontSize: 15))),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// RESULT SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});
  @override State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale, _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scale   = Tween(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _opacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5)));
    _ctrl.forward();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final game   = context.watch<GameProvider>();
    final winner = game.players.isNotEmpty ? game.players.first : null;

    return Scaffold(
      body: AnimatedBg(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Gap(16),
              ScaleTransition(scale: _scale, child: FadeTransition(opacity: _opacity,
                child: Column(children: [
                  Container(width: 100, height: 100,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Colors.amber, Color(0xFFFF8C00)]),
                      boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.55), blurRadius: 36, spreadRadius: 4)]),
                    child: const Center(child: Text('🏆', style: TextStyle(fontSize: 50)))),
                  const Gap(14),
                  Text('Partie terminée !', style: GoogleFonts.raleway(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                  if (winner != null) ...[
                    const Gap(6),
                    Text('${winner.name} remporte la victoire ! 🎉',
                      style: TextStyle(color: Colors.amber, fontSize: 15), textAlign: TextAlign.center),
                  ],
                ]),
              )),
              const Gap(24),

              Expanded(
                child: ListView.builder(
                  itemCount: game.players.length,
                  itemBuilder: (_, i) {
                    final p = game.players[i]; final isMe = p.id == game.myPlayerId;
                    final medal = switch (i) { 0 => '🥇', 1 => '🥈', 2 => '🥉', _ => '${i+1}.' };
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 300 + i * 100),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: i == 0 ? LinearGradient(colors: [Colors.amber.withOpacity(0.22), Colors.amber.withOpacity(0.08)]) : null,
                          color: i == 0 ? null : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: i == 0 ? Colors.amber.withOpacity(0.55) : Colors.white.withOpacity(0.08), width: 1.5),
                          boxShadow: i == 0 ? [BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 16)] : [],
                        ),
                        child: Row(children: [
                          Text(medal, style: const TextStyle(fontSize: 26)),
                          const Gap(14),
                          Expanded(child: Text(p.name + (isMe ? ' (moi)' : ''),
                            style: TextStyle(color: isMe ? C.rose : Colors.white, fontSize: 17, fontWeight: FontWeight.w600))),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: (i == 0 ? Colors.amber : C.violet).withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12)),
                            child: Text('${p.score} ⭐', style: TextStyle(color: i == 0 ? Colors.amber : C.sub, fontSize: 15, fontWeight: FontWeight.bold))),
                        ]),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(width: double.infinity, child: GradientButton(
                label: '🔄  Retour à l\'accueil',
                colors: const [C.violet, C.pink],
                onTap: () => context.read<GameProvider>().reset(),
              )),
            ]),
          ),
        ),
      ),
    );
  }
}