import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// ════════════════════════════════════════════════════════════════
// PALETTE WeJoy
// ════════════════════════════════════════════════════════════════
const _rose   = Color(0xFFE84C88);
const _violet = Color(0xFF7C4DFF);
const _gold   = Color(0xFFFFC857);
const _snow   = Color(0xFFF8F1EA);
const _card   = Color(0xFFFFFFFF);
const _ink    = Color(0xFF1F1A24);
const _slate  = Color(0xFF6E6A78);
const _border = Color(0xFFF1E6DD);
const _green  = Color(0xFF10B981);
const _red    = Color(0xFFEF4444);

// ════════════════════════════════════════════════════════════════
// PAGE QUIZ
// ════════════════════════════════════════════════════════════════
class QuizPage extends StatefulWidget {
  final IO.Socket socket;
  final Map<String, dynamic> room;
  final String playerName;

  const QuizPage({
    super.key,
    required this.socket,
    required this.room,
    required this.playerName,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  // ── État du jeu ──────────────────────────────────────────────
  Map<String, dynamic>? _currentQuestion;
  int _questionIndex   = 0;
  int _totalQuestions  = 10;
  Map<String, int> _scores = {};
  int? _selectedAnswer;
  bool _answered       = false;
  bool _gameOver       = false;
  bool _waitingForNext = false;
  String? _correctAnswer;
  String? _winner;
  String? _currentPlayer; // qui doit répondre
  bool _isMyTurn        = false;
  List<String> _players = [];
  String? _statusMsg;

  late AnimationController _questionCtrl;
  late AnimationController _resultCtrl;
  late Animation<double>   _questionAnim;
  late Animation<double>   _resultAnim;

  @override
  void initState() {
    super.initState();

    _questionCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _resultCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _questionAnim = CurvedAnimation(parent: _questionCtrl, curve: Curves.easeOutCubic);
    _resultAnim   = CurvedAnimation(parent: _resultCtrl,   curve: Curves.easeOutCubic);

    // Init depuis room
    final players = widget.room['players'] as List? ?? [];
    _players = players.map((p) => p['name'].toString()).toList();
    for (final p in _players) {
      _scores[p] = 0;
    }

    _setupSocket();

    // Demander au serveur de démarrer le quiz
    widget.socket.emit('quiz_ready', {
      'roomId': widget.room['roomId'],
      'playerName': widget.playerName,
    });
  }

  void _setupSocket() {
    widget.socket.on('quiz_question', (data) {
      if (!mounted) return;
      final d = Map<String, dynamic>.from(data);
      setState(() {
        _currentQuestion = d;
        _questionIndex   = d['questionIndex'] ?? _questionIndex;
        _totalQuestions  = d['totalQuestions'] ?? _totalQuestions;
        _currentPlayer   = d['currentPlayer'];
        _isMyTurn        = _currentPlayer == widget.playerName;
        _selectedAnswer  = null;
        _answered        = false;
        _waitingForNext  = false;
        _correctAnswer   = null;
        _statusMsg       = _isMyTurn ? 'C\'est ton tour ! Réponds vite 🎯' : 'En attente de ${_currentPlayer}...';
      });
      _questionCtrl.forward(from: 0);
    });

    widget.socket.on('quiz_answer_result', (data) {
      if (!mounted) return;
      final d = Map<String, dynamic>.from(data);
      setState(() {
        _correctAnswer  = d['correctAnswer'];
        _scores         = Map<String, int>.from(d['scores'] ?? {});
        _waitingForNext = true;
        _statusMsg      = d['isCorrect'] == true
            ? '✅ Bonne réponse ! +10 points'
            : '❌ Mauvaise réponse. La bonne : ${d['correctAnswer']}';
      });
      _resultCtrl.forward(from: 0);
    });

    widget.socket.on('quiz_game_over', (data) {
      if (!mounted) return;
      final d = Map<String, dynamic>.from(data);
      setState(() {
        _gameOver = true;
        _scores   = Map<String, int>.from(d['scores'] ?? {});
        _winner   = d['winner'];
      });
    });

    widget.socket.on('quiz_player_left', (_) {
      if (!mounted) return;
      _showPlayerLeftDialog();
    });
  }

  void _submitAnswer(int answerIndex) {
    if (_answered || !_isMyTurn) return;
    setState(() {
      _selectedAnswer = answerIndex;
      _answered       = true;
    });
    widget.socket.emit('quiz_answer', {
      'roomId':      widget.room['roomId'],
      'playerName':  widget.playerName,
      'answerIndex': answerIndex,
    });
  }

  void _showPlayerLeftDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.person_off_rounded, color: _red, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Adversaire parti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 8),
            Text('Ton adversaire a quitté la partie.', style: const TextStyle(color: _slate, fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(
                backgroundColor: _rose, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Retour', style: TextStyle(fontWeight: FontWeight.w700)),
            )),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.socket.off('quiz_question');
    widget.socket.off('quiz_answer_result');
    widget.socket.off('quiz_game_over');
    widget.socket.off('quiz_player_left');
    _questionCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gameOver) return _buildGameOver();
    if (_currentQuestion == null) return _buildWaiting();
    return _buildGame();
  }

  // ── Écran d'attente ──────────────────────────────────────────
  Widget _buildWaiting() => Scaffold(
    backgroundColor: _snow,
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(width: 50, height: 50,
        child: CircularProgressIndicator(strokeWidth: 3, color: _violet)),
      const SizedBox(height: 24),
      const Text('Chargement du quiz...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
      const SizedBox(height: 8),
      const Text('Prépare-toi ! 🧠', style: TextStyle(color: _slate, fontSize: 13)),
    ])),
  );

  // ── Écran de jeu ─────────────────────────────────────────────
  Widget _buildGame() {
    final q       = _currentQuestion!;
    final choices = (q['choices'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final progress = (_questionIndex + 1) / _totalQuestions;

    return Scaffold(
      backgroundColor: _snow,
      body: Stack(children: [
        // Fond déco
        Positioned(top: -50, right: -30, child: Container(
          width: 160, height: 160,
          decoration: BoxDecoration(shape: BoxShape.circle, color: _violet.withOpacity(0.08)),
        )),
        Positioned(bottom: 60, left: -30, child: Container(
          width: 120, height: 120,
          decoration: BoxDecoration(shape: BoxShape.circle, color: _rose.withOpacity(0.07)),
        )),

        SafeArea(child: Column(children: [
          // Header
          _buildHeader(progress),

          // Scores
          _buildScoreBar(),

          // Question + réponses
          Expanded(child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(children: [
              // Status
              if (_statusMsg != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isMyTurn ? _violet.withOpacity(0.08) : _slate.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _isMyTurn ? _violet.withOpacity(0.20) : _border),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_isMyTurn ? Icons.touch_app_rounded : Icons.hourglass_top_rounded,
                      size: 15, color: _isMyTurn ? _violet : _slate),
                    const SizedBox(width: 8),
                    Text(_statusMsg!, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: _isMyTurn ? _violet : _slate,
                    )),
                  ]),
                ),

              // Carte question
              FadeTransition(
                opacity: _questionAnim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(_questionAnim),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_violet, _rose],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: _violet.withOpacity(0.30), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.20), borderRadius: BorderRadius.circular(20)),
                          child: Text('Question ${_questionIndex + 1}/$_totalQuestions',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                        const Spacer(),
                        const Text('🧠', style: TextStyle(fontSize: 24)),
                      ]),
                      const SizedBox(height: 16),
                      Text(q['question'] ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, height: 1.35)),
                    ]),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Choix de réponses
              ...List.generate(choices.length, (i) => _buildAnswerChoice(i, choices[i])),
            ]),
          )),
        ])),
      ]),
    );
  }

  Widget _buildHeader(double progress) => Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _border),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Column(children: [
      Row(children: [
        GestureDetector(
          onTap: () { widget.socket.disconnect(); Navigator.pop(context); },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _snow, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
            child: const Icon(Icons.arrow_back_ios_new, size: 14, color: _slate),
          ),
        ),
        const SizedBox(width: 12),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(colors: [_violet, _rose]).createShader(b),
          child: const Text('Quiz Bien-être 🧠',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ]),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress, minHeight: 6,
          backgroundColor: _border,
          valueColor: const AlwaysStoppedAnimation<Color>(_violet),
        ),
      ),
    ]),
  );

  Widget _buildScoreBar() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _players.map((p) {
        final isMe = p == widget.playerName;
        final score = _scores[p] ?? 0;
        return Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe ? _violet.withOpacity(0.12) : _rose.withOpacity(0.10),
            ),
            child: Center(child: Text(p.isNotEmpty ? p[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                color: isMe ? _violet : _rose))),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isMe ? '$p (Toi)' : p,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: isMe ? _violet : _ink)),
            Text('$score pts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
              color: isMe ? _violet : _rose)),
          ]),
        ]);
      }).toList(),
    ),
  );

  Widget _buildAnswerChoice(int index, String text) {
    Color bgColor  = _card;
    Color txtColor = _ink;
    Color bdColor  = _border;
    IconData? icon;

    if (_answered || _waitingForNext) {
      final choices = (_currentQuestion?['choices'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final isCorrect = _correctAnswer != null && choices.indexOf(_correctAnswer!) == index;
      final isSelected = _selectedAnswer == index;

      if (isCorrect) {
        bgColor  = _green.withOpacity(0.10);
        bdColor  = _green.withOpacity(0.40);
        txtColor = _green;
        icon     = Icons.check_circle_rounded;
      } else if (isSelected && !isCorrect) {
        bgColor  = _red.withOpacity(0.08);
        bdColor  = _red.withOpacity(0.35);
        txtColor = _red;
        icon     = Icons.cancel_rounded;
      }
    } else if (_selectedAnswer == index) {
      bgColor  = _violet.withOpacity(0.10);
      bdColor  = _violet.withOpacity(0.40);
      txtColor = _violet;
    }

    final canTap = !_answered && _isMyTurn;

    return GestureDetector(
      onTap: canTap ? () => _submitAnswer(index) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bdColor, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: canTap ? _violet.withOpacity(0.08) : bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: bdColor),
            ),
            child: Center(child: Text(
              ['A', 'B', 'C', 'D'][index],
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: txtColor),
            )),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txtColor))),
          if (icon != null) Icon(icon, color: txtColor, size: 20),
          if (!_isMyTurn && !_answered)
            Icon(Icons.lock_rounded, size: 14, color: _slate.withOpacity(0.4)),
        ]),
      ),
    );
  }

  // ── Écran de fin ─────────────────────────────────────────────
  Widget _buildGameOver() {
    final isWinner = _winner == widget.playerName;
    final sorted = _scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: _snow,
      body: Stack(children: [
        Positioned(top: -60, right: -40, child: Container(
          width: 200, height: 200,
          decoration: BoxDecoration(shape: BoxShape.circle, color: _violet.withOpacity(0.08)),
        )),
        SafeArea(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isWinner ? [_violet, _rose] : [_slate, _ink],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(
                  color: (isWinner ? _violet : _slate).withOpacity(0.30),
                  blurRadius: 24, offset: const Offset(0, 10),
                )],
              ),
              child: Column(children: [
                Text(isWinner ? '🏆' : '🎖️', style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                Text(isWinner ? 'Tu as gagné !' : 'Bien joué !',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 6),
                Text(isWinner ? 'Bravo, tu es le maître du quiz ! 🧠' : 'Continue à apprendre !',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.80))),
              ]),
            ),
            const SizedBox(height: 24),

            // Scores
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _card, borderRadius: BorderRadius.circular(22), border: Border.all(color: _border),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Column(children: [
                const Text('Résultats finaux',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                const SizedBox(height: 16),
                ...sorted.asMap().entries.map((e) {
                  final rank  = e.key;
                  final entry = e.value;
                  final isMe  = entry.key == widget.playerName;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isMe ? _violet.withOpacity(0.07) : _snow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isMe ? _violet.withOpacity(0.20) : _border),
                    ),
                    child: Row(children: [
                      Text(['🥇', '🥈', '🥉'][rank < 3 ? rank : 2],
                        style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(
                        isMe ? '${entry.key} (Toi)' : entry.key,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                          color: isMe ? _violet : _ink),
                      )),
                      Text('${entry.value} pts',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                          color: isMe ? _violet : _rose)),
                    ]),
                  );
                }),
              ]),
            ),
            const SizedBox(height: 20),

            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () { widget.socket.disconnect(); Navigator.pop(context); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_rose, _violet]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: _rose.withOpacity(0.30), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Text('Retour aux jeux', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            )),
          ]),
        )),
      ]),
    );
  }
}