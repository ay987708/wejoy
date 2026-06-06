import 'package:flutter/material.dart';
import 'package:wejoy/screens/defis/home_screen.dart';
import 'package:wejoy/screens/service/socket_service.dart';

class GameScreen extends StatefulWidget {
  final String roomId;
  final String symbol;
  const GameScreen({super.key, required this.roomId, required this.symbol});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final SocketService _socket = SocketService();
  List<String?> _board = List.filled(9, null);
  String _currentTurn = 'X';
  Map<String, int> _scores = {'X': 0, 'O': 0};
  String? _statusMessage;
  List<int>? _winCombo;
  bool _gameOver = false;
  bool _waitingForOpponent = true;
  late AnimationController _pulse;

  // ── Couleurs style GamesHub ──
  static const _bg        = Color(0xFFFDF6FF);
  static const _card      = Color(0xFFFFFFFF);
  static const _cardTint  = Color(0xFFF8F0FF);
  static const _violet    = Color(0xFF8B5CF6);
  static const _pink      = Color(0xFFEC4899);
  static const _textDark  = Color(0xFF1E1B2E);
  static const _textMid   = Color(0xFF6B7280);
  static const _textLight = Color(0xFFB0A8C0);
  static const _xCol      = Color(0xFF8B5CF6);
  static const _oCol      = Color(0xFFEC4899);

  Color get _myColor => widget.symbol == 'X' ? _xCol : _oCol;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _socket.on('game_start', (data) {
      if (!mounted) return;
      setState(() {
        _board = List<String?>.from(data['board'].map((e) => e?.toString()));
        _currentTurn = data['currentTurn'];
        _scores = Map<String, int>.from(
            data['scores'].map((k, v) => MapEntry(k, v as int)));
        _statusMessage = null;
        _winCombo = null;
        _gameOver = false;
        _waitingForOpponent = false;
      });
    });

    _socket.on('game_update', (data) {
      if (!mounted) return;
      final r = data['result'];
      setState(() {
        _board = List<String?>.from(data['board'].map((e) => e?.toString()));
        _currentTurn = data['currentTurn'];
        _scores = Map<String, int>.from(
            data['scores'].map((k, v) => MapEntry(k, v as int)));
        if (r != null) {
          _gameOver = true;
          _statusMessage = r['winner'] == 'draw'
              ? 'Match nul 🤝'
              : r['winner'] == widget.symbol
                  ? 'Tu as gagné 🏆'
                  : 'Adversaire gagne 😔';
          _winCombo = r['winner'] != 'draw'
              ? List<int>.from(r['combo'])
              : null;
        } else {
          _statusMessage = null;
          _winCombo = null;
          _gameOver = false;
        }
      });
    });

    _socket.on('player_left', (_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Partie terminée',
              style: TextStyle(color: _textDark, fontWeight: FontWeight.w700)),
          content: const Text('Ton adversaire a quitté.',
              style: TextStyle(color: _textMid)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false),
              child: Text('Accueil',
                  style: TextStyle(color: _myColor, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _socket.off('game_start');
    _socket.off('game_update');
    _socket.off('player_left');
    super.dispose();
  }

  bool get _isMyTurn =>
      _currentTurn == widget.symbol && !_gameOver && !_waitingForOpponent;

  void _play(int i) {
    if (!_isMyTurn || _board[i] != null) return;
    _socket.playMove(i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // ── Top bar ──
              Row(children: [
                _IconBtn(Icons.arrow_back_ios_new, () =>
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (_) => false)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _cardTint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _violet.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    Icon(Icons.grid_view_rounded,
                        size: 13, color: _violet.withOpacity(0.5)),
                    const SizedBox(width: 7),
                    Text(widget.roomId,
                        style: const TextStyle(
                            color: _textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3)),
                  ]),
                ),
                const Spacer(),
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: _myColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _myColor.withOpacity(0.35)),
                  ),
                  alignment: Alignment.center,
                  child: Text(widget.symbol,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _myColor)),
                ),
              ]),

              const SizedBox(height: 12),

              // ── Score ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _violet.withOpacity(0.1)),
                  boxShadow: [BoxShadow(
                      color: _violet.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  _ScorePill('X', _scores['X'] ?? 0, _xCol,
                      _currentTurn == 'X' && !_waitingForOpponent && !_gameOver),
                  const Spacer(),
                  if (_waitingForOpponent)
                    const Text('En attente...',
                        style: TextStyle(color: _textLight, fontSize: 12))
                  else if (_gameOver)
                    Text(_statusMessage ?? '',
                        style: const TextStyle(
                            color: _textDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center)
                  else
                    Column(children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, __) => Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.lerp(
                                _isMyTurn ? _myColor : _textLight,
                                Colors.white,
                                _pulse.value * 0.25)!,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_isMyTurn ? 'Ton tour' : 'Adversaire',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _isMyTurn ? _myColor : _textLight)),
                    ]),
                  const Spacer(),
                  _ScorePill('O', _scores['O'] ?? 0, _oCol,
                      _currentTurn == 'O' && !_waitingForOpponent && !_gameOver),
                ]),
              ),

              const SizedBox(height: 12),

              // ── Board — Expanded + LayoutBuilder pour éviter l'overflow ──
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Taille carrée = min(largeur, hauteur disponible)
                    final size = constraints.maxWidth < constraints.maxHeight
                        ? constraints.maxWidth
                        : constraints.maxHeight;
                    return Center(
                      child: SizedBox(
                        width: size,
                        height: size,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 9,
                                  mainAxisSpacing: 9),
                          itemCount: 9,
                          itemBuilder: (_, i) {
                            final val = _board[i];
                            final isWin = _winCombo?.contains(i) ?? false;
                            final canPlay = _isMyTurn && val == null;
                            final symColor = val == 'X' ? _xCol : _oCol;
                            return GestureDetector(
                              onTap: () => _play(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  color: isWin
                                      ? symColor.withOpacity(0.15)
                                      : canPlay
                                          ? _violet.withOpacity(0.06)
                                          : _cardTint,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                      color: isWin
                                          ? symColor.withOpacity(0.55)
                                          : canPlay
                                              ? _violet.withOpacity(0.3)
                                              : _violet.withOpacity(0.1),
                                      width: isWin ? 1.5 : 1),
                                  boxShadow: isWin
                                      ? [BoxShadow(
                                          color: symColor.withOpacity(0.2),
                                          blurRadius: 8)]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: val == null
                                    ? (canPlay
                                        ? Icon(Icons.add,
                                            color: _violet.withOpacity(0.2),
                                            size: 22)
                                        : null)
                                    : TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.2, end: 1.0),
                                        duration:
                                            const Duration(milliseconds: 320),
                                        curve: Curves.elasticOut,
                                        builder: (_, s, child) =>
                                            Transform.scale(scale: s, child: child),
                                        child: Text(val,
                                            style: TextStyle(
                                                fontSize: size / 8,
                                                fontWeight: FontWeight.w800,
                                                color: symColor)),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // ── Waiting card (horizontale pour gagner de la hauteur) ──
              if (_waitingForOpponent)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _violet.withOpacity(0.12)),
                    boxShadow: [BoxShadow(
                        color: _violet.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: _myColor)),
                      const SizedBox(width: 12),
                      const Text('En attente d\'un adversaire',
                          style: TextStyle(color: _textMid, fontSize: 13)),
                      const SizedBox(width: 12),
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                            colors: [_violet, _pink]).createShader(b),
                        child: Text(widget.roomId,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 4)),
                      ),
                    ],
                  ),
                ),

              // ── Game over buttons ──
              if (_gameOver) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _socket.restart(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: widget.symbol == 'X'
                                  ? [_violet, _pink]
                                  : [_pink, _violet]),
                          borderRadius: BorderRadius.circular(14)),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: const Text('Rejouer',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (_) => false),
                  child: const Text('Quitter',
                      style: TextStyle(color: _textLight, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF6B7280), size: 15),
        ),
      );
}

class _ScorePill extends StatelessWidget {
  final String symbol;
  final int score;
  final Color color;
  final bool active;
  const _ScorePill(this.symbol, this.score, this.color, this.active);

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? color.withOpacity(0.3) : Colors.transparent),
        ),
        child: Column(children: [
          Text(symbol,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? color : const Color(0xFFB0A8C0))),
          const SizedBox(height: 2),
          Text('$score',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: active ? color : const Color(0xFFD1D5DB))),
        ]),
      );
}