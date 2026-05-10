import 'package:flutter/material.dart';
import 'package:wejoy/screens/service/socket_service.dart';
import 'games_hub.dart';

class QuizScreen extends StatefulWidget {
  final String roomId, playerName;
  final bool isHost;
  const QuizScreen({
    super.key, required this.roomId, required this.playerName, required this.isHost,
  });
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final SocketService _socket = SocketService();

  static const _bg   = Color(0xFF0F172A);
  static const _card = Color(0xFF1E293B);
  static const _teal = Color(0xFF10B981);
  static const _red  = Color(0xFFEF4444);

  // ── Lobby ──────────────────────────────────────────────
  List<dynamic> _players  = [];
  bool _gameStarted       = false;

  // ── Question ──────────────────────────────────────────
  String _question        = '';
  List<String> _options   = [];
  int _currentIndex       = 0;
  int _totalQuestions     = 0;
  Map<String, dynamic> _scores = {};
  int? _myAnswer;
  int? _correctAnswer;
  bool _revealed          = false;
  int _answeredCount      = 0;

  // ── Countdown affiché pendant le reveal ───────────────
  int _revealCountdown    = 4;

  // ── Fin ───────────────────────────────────────────────
  bool _gameOver          = false;
  String _winner          = '';
  List<dynamic> _ranking  = [];

  late AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..addListener(() => setState(() {}));

    _socket.on('lobby_update', (data) {
      if (!mounted) return;
      setState(() => _players = data['players'] ?? []);
    });

    _socket.on('quiz_question', (data) {
      if (!mounted) return;
      setState(() {
        _gameStarted    = true;
        _question       = data['question'] ?? '';
        _options        = List<String>.from(data['options'] ?? []);
        _currentIndex   = data['index'] ?? 0;
        _totalQuestions = data['total'] ?? 0;
        _scores         = Map<String, dynamic>.from(data['scores'] ?? {});
        _myAnswer       = null;
        _correctAnswer  = null;
        _revealed       = false;
        _answeredCount  = 0;
        _revealCountdown = 4;
      });
      _progressCtrl.reset();
      _progressCtrl.forward();
    });

    _socket.on('quiz_answer_update', (data) {
      if (!mounted) return;
      setState(() => _answeredCount = data['answered'] ?? 0);
    });

    _socket.on('quiz_reveal', (data) {
      if (!mounted) return;
      _progressCtrl.stop();
      setState(() {
        _correctAnswer   = data['correct'];
        _scores          = Map<String, dynamic>.from(data['scores'] ?? {});
        _revealed        = true;
        _revealCountdown = 4;
      });
      // Countdown visuel 4 → 0
      _startRevealCountdown();
    });

    _socket.on('quiz_end', (data) {
      if (!mounted) return;
      setState(() {
        _gameOver = true;
        _winner   = data['winner'] ?? '';
        _ranking  = data['ranking'] ?? [];
      });
    });
  }

  void _startRevealCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _revealCountdown--);
      return _revealCountdown > 0;
    });
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _socket.off('lobby_update');
    _socket.off('quiz_question');
    _socket.off('quiz_answer_update');
    _socket.off('quiz_reveal');
    _socket.off('quiz_end');
    super.dispose();
  }

  void _startQuiz() => _socket.startQuiz(widget.roomId);

  void _answer(int index) {
    if (_myAnswer != null || _revealed) return;
    setState(() => _myAnswer = index);
    _socket.answerQuiz(widget.roomId, widget.playerName, _currentIndex, index);
  }

  Color _optionColor(int i) {
    if (!_revealed) {
      return _myAnswer == i ? _teal.withOpacity(0.2) : const Color(0xFF243044);
    }
    if (i == _correctAnswer) return _teal.withOpacity(0.2);
    if (_myAnswer == i && i != _correctAnswer) return _red.withOpacity(0.15);
    return const Color(0xFF243044);
  }

  Color _optionBorder(int i) {
    if (!_revealed) {
      return _myAnswer == i ? _teal.withOpacity(0.6) : Colors.white.withOpacity(0.06);
    }
    if (i == _correctAnswer) return _teal.withOpacity(0.7);
    if (_myAnswer == i && i != _correctAnswer) return _red.withOpacity(0.6);
    return Colors.white.withOpacity(0.06);
  }

  @override
  Widget build(BuildContext context) {
    if (_gameOver) return _buildEndScreen();
    if (!_gameStarted) return _buildLobby();
    return _buildGame();
  }

  // ─── Lobby ───────────────────────────────────────────
  Widget _buildLobby() {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white54, size: 16),
          onPressed: () {
            _socket.leaveGameRoom(widget.roomId);
            Navigator.pop(context);
          },
        ),
        title: const Text('Quiz 🧠',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: Column(children: [
              Text('Code de la salle',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.4))),
              const SizedBox(height: 8),
              Text(widget.roomId, style: const TextStyle(
                fontSize: 36, fontWeight: FontWeight.w800, color: _teal, letterSpacing: 6)),
              const SizedBox(height: 4),
              const Text('Partage ce code avec tes amis',
                style: TextStyle(fontSize: 12, color: Colors.white24)),
            ]),
          ),
          const SizedBox(height: 20),
          Text('JOUEURS (${_players.length})',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.3), letterSpacing: 1.5)),
          const SizedBox(height: 12),
          ..._players.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(color: _teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text((p['name'] ?? '?')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _teal))),
              const SizedBox(width: 12),
              Expanded(child: Text(p['name'] ?? '',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
              if (p['name'] == widget.playerName)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _teal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                  child: const Text('Toi',
                    style: TextStyle(fontSize: 10, color: _teal, fontWeight: FontWeight.w700))),
            ]),
          )),
          const Spacer(),
          if (widget.isHost) ...[
            if (_players.length < 2)
              Text('En attente d\'un adversaire...',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.3))),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _players.length >= 2 ? _startQuiz : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0, disabledBackgroundColor: Colors.white10,
                ),
                child: const Text('Lancer le Quiz',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ] else
            Text('En attente que l\'hôte lance la partie...',
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.35))),
        ]),
      ),
    );
  }

  // ─── Jeu ─────────────────────────────────────────────
  Widget _buildGame() {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [

            // ── Progress bar question ──
            Row(children: [
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _totalQuestions,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  color: _teal, minHeight: 6,
                ),
              )),
              const SizedBox(width: 12),
              Text('${_currentIndex + 1}/$_totalQuestions',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white54)),
            ]),

            // ── Timer de réponse ──
            if (!_revealed) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 1 - _progressCtrl.value,
                  backgroundColor: Colors.white.withOpacity(0.06),
                  color: _progressCtrl.value > 0.7 ? _red : _teal,
                  minHeight: 4,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Scores ──
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: _scores.entries.map((e) {
                final isMe = e.key == widget.playerName;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe ? _teal.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isMe ? _teal.withOpacity(0.35) : Colors.transparent),
                  ),
                  child: Column(children: [
                    Text(e.key, style: TextStyle(fontSize: 11,
                      color: isMe ? _teal : Colors.white38,
                      fontWeight: FontWeight.w600)),
                    Text('${e.value}', style: TextStyle(fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isMe ? _teal : Colors.white38)),
                  ]),
                );
              }).toList()),

            const SizedBox(height: 24),

            // ── Question ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.05))),
              child: Column(children: [
                const Text('❓', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 12),
                Text(_question, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                    color: Colors.white, height: 1.4)),
              ]),
            ),

            const SizedBox(height: 20),

            // ── Options ──
            ...List.generate(_options.length, (i) => GestureDetector(
              onTap: () => _answer(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: _optionColor(i),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _optionBorder(i), width: 1.5),
                ),
                child: Row(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                    alignment: Alignment.center,
                    child: Text(['A','B','C','D'][i],
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white54)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_options[i],
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
                  if (_revealed && i == _correctAnswer)
                    const Text('✅', style: TextStyle(fontSize: 16))
                  else if (_revealed && _myAnswer == i && i != _correctAnswer)
                    const Text('❌', style: TextStyle(fontSize: 16)),
                ]),
              ),
            )),

            const Spacer(),

            // ── Statut ──
            if (!_revealed) ...[
              if (_myAnswer == null)
                Text('Choisis ta réponse !',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.3)))
              else
                Text('$_answeredCount/${_players.length} ont répondu',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.3))),
            ],

            // ── Reveal : bonne réponse + countdown ──
            if (_revealed) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _teal.withOpacity(0.3)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    _myAnswer == _correctAnswer ? '🎉 Bonne réponse !' : '😔 Mauvaise réponse',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: _myAnswer == _correctAnswer ? _teal : _red,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                    alignment: Alignment.center,
                    child: Text('$_revealCountdown',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white54)),
                  ),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  // ─── Fin ─────────────────────────────────────────────
  Widget _buildEndScreen() {
    final iWon = _winner == widget.playerName;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(iWon ? '🏆' : '😔', style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            Text(iWon ? 'Tu as gagné !' : '$_winner a gagné !',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                color: iWon ? _teal : Colors.white54)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.06))),
              child: Column(
                children: _ranking.asMap().entries.map((e) {
                  final rank  = e.key + 1;
                  final item  = e.value;
                  final name  = item['name'] ?? '';
                  final score = item['score'] ?? 0;
                  final isMe  = name == widget.playerName;
                  final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      Text(medal, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(name,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                          color: isMe ? Colors.white : Colors.white60))),
                      Text('$score bonne${score > 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                          color: isMe ? _teal : Colors.white38)),
                    ]),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context, MaterialPageRoute(builder: (_) => const GamesHub()), (_) => false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Retour aux jeux',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
