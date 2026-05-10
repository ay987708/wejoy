import 'package:flutter/material.dart';
import 'package:wejoy/screens/d%C3%A9fis/home_screen.dart';
import 'package:wejoy/screens/service/socket_service.dart';
import 'home_screen.dart';

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

  static const _bg = Color(0xFF0F172A);
  static const _card = Color(0xFF1E293B);
  static const _cell = Color(0xFF243044);
  static const _xCol = Color(0xFF3B82F6);
  static const _oCol = Color(0xFFF97316);

  Color get _myColor => widget.symbol == 'X' ? _xCol : _oCol;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

    _socket.on('game_start', (data) {
      if (!mounted) return;
      setState(() {
        _board = List<String?>.from(data['board'].map((e) => e?.toString()));
        _currentTurn = data['currentTurn'];
        _scores = Map<String, int>.from(data['scores'].map((k, v) => MapEntry(k, v as int)));
        _statusMessage = null; _winCombo = null; _gameOver = false; _waitingForOpponent = false;
      });
    });

    _socket.on('game_update', (data) {
      if (!mounted) return;
      final r = data['result'];
      setState(() {
        _board = List<String?>.from(data['board'].map((e) => e?.toString()));
        _currentTurn = data['currentTurn'];
        _scores = Map<String, int>.from(data['scores'].map((k, v) => MapEntry(k, v as int)));
        if (r != null) {
          _gameOver = true;
          _statusMessage = r['winner'] == 'draw' ? 'Match nul 🤝' : r['winner'] == widget.symbol ? 'Tu as gagné 🏆' : 'Adversaire gagne 😔';
          _winCombo = r['winner'] != 'draw' ? List<int>.from(r['combo']) : null;
        } else { _statusMessage = null; _winCombo = null; _gameOver = false; }
      });
    });

    _socket.on('player_left', (_) {
      if (!mounted) return;
      showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Partie terminée', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        content: const Text('Ton adversaire a quitté.', style: TextStyle(color: Colors.white54)),
        actions: [TextButton(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false), child: Text('Accueil', style: TextStyle(color: _myColor, fontWeight: FontWeight.w600)))],
      ));
    });
  }

  @override
  void dispose() { _pulse.dispose(); _socket.off('game_start'); _socket.off('game_update'); _socket.off('player_left'); super.dispose(); }

  bool get _isMyTurn => _currentTurn == widget.symbol && !_gameOver && !_waitingForOpponent;

  void _play(int i) { if (!_isMyTurn || _board[i] != null) return; _socket.playMove(i); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boardSize = (size.width < size.height ? size.width : size.height * 0.55) - 40;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              // ── Top bar ──
              Row(children: [
                _IconBtn(Icons.arrow_back_ios_new, () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.07))),
                  child: Row(children: [
                    const Icon(Icons.grid_view_rounded, size: 13, color: Colors.white38),
                    const SizedBox(width: 7),
                    Text(widget.roomId, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 3)),
                  ]),
                ),
                const Spacer(),
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: _myColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: _myColor.withOpacity(0.35))),
                  alignment: Alignment.center,
                  child: Text(widget.symbol, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _myColor)),
                ),
              ]),

              const SizedBox(height: 18),

              // ── Score ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
                child: Row(children: [
                  _ScorePill('X', _scores['X'] ?? 0, _xCol, _currentTurn == 'X' && !_waitingForOpponent && !_gameOver),
                  const Spacer(),
                  // centre
                  if (_waitingForOpponent)
                    const Text('En attente...', style: TextStyle(color: Colors.white30, fontSize: 12))
                  else if (_gameOver)
                    Text(_statusMessage ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center)
                  else
                    Column(children: [
                      AnimatedBuilder(animation: _pulse, builder: (_, __) => Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Color.lerp(_isMyTurn ? _myColor : Colors.white24, Colors.white, _pulse.value * 0.25)!),
                      )),
                      const SizedBox(height: 5),
                      Text(_isMyTurn ? 'Ton tour' : 'Adversaire', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _isMyTurn ? Colors.white60 : Colors.white24)),
                    ]),
                  const Spacer(),
                  _ScorePill('O', _scores['O'] ?? 0, _oCol, _currentTurn == 'O' && !_waitingForOpponent && !_gameOver),
                ]),
              ),

              const SizedBox(height: 22),

              // ── Board ──
              SizedBox(
                width: boardSize, height: boardSize,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 9, mainAxisSpacing: 9),
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
                          color: isWin ? symColor.withOpacity(0.18) : canPlay ? const Color(0xFF2A3A52) : _cell,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: isWin ? symColor.withOpacity(0.55) : canPlay ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.04), width: isWin ? 1.5 : 1),
                        ),
                        alignment: Alignment.center,
                        child: val == null
                            ? (canPlay ? Icon(Icons.add, color: Colors.white10, size: 22) : null)
                            : TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.2, end: 1.0),
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.elasticOut,
                                builder: (_, s, child) => Transform.scale(scale: s, child: child),
                                child: Text(val, style: TextStyle(fontSize: boardSize / 8, fontWeight: FontWeight.w800, color: symColor)),
                              ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 22),

              // ── Waiting card ──
              if (_waitingForOpponent)
                Container(
                  width: boardSize,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.05))),
                  child: Column(children: [
                    SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5, color: _myColor)),
                    const SizedBox(height: 12),
                    const Text('En attente d\'un adversaire', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 10),
                    Text(widget.roomId, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: _myColor, letterSpacing: 7)),
                    const SizedBox(height: 4),
                    const Text('Partage ce code', style: TextStyle(color: Colors.white24, fontSize: 11)),
                  ]),
                ),

              // ── Game over buttons ──
              if (_gameOver) ...[
                SizedBox(
                  width: boardSize,
                  child: ElevatedButton(
                    onPressed: () => _socket.restart(),
                    style: ElevatedButton.styleFrom(backgroundColor: _myColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                    child: const Text('Rejouer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false),
                  child: const Text('Quitter', style: TextStyle(color: Colors.white24, fontSize: 13)),
                ),
              ],
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
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: Colors.white54, size: 15),
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
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
    decoration: BoxDecoration(
      color: active ? color.withOpacity(0.13) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: active ? color.withOpacity(0.28) : Colors.transparent),
    ),
    child: Column(children: [
      Text(symbol, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? color : Colors.white30)),
      const SizedBox(height: 3),
      Text('$score', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: active ? color : Colors.white38)),
    ]),
  );
}
