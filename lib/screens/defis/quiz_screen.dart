import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wejoy/screens/service/socket_service.dart';

// ═══════════════════════════════════════════════════════════
//  QUIZ SCREEN — branché sur socket.js
//  Événements reçus : quiz_question, quiz_answer_update,
//                     quiz_reveal, quiz_end
//  Événements émis  : quiz_start, quiz_answer
// ═══════════════════════════════════════════════════════════

enum _Phase { lobby, playing, reveal, finished }

class QuizScreen extends StatefulWidget {
  final String roomId;
  final String playerName;
  final bool isHost;
  final List<dynamic> initialPlayers;   // FIX timing lobby_update

  const QuizScreen({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.isHost,
    this.initialPlayers = const [],
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  // ── Palette WeJoy ──────────────────────────────────────
  static const _bg        = Color(0xFFFDF6FF);
  static const _card      = Color(0xFFFFFFFF);
  static const _cardTint  = Color(0xFFF8F0FF);
  static const _teal      = Color(0xFF0D9488);
  static const _textDark  = Color.fromARGB(255, 221, 6, 114);
  static const _textMid   = Color.fromARGB(255, 172, 43, 114);
  static const _textLight = Color.fromARGB(255, 201, 137, 214);

  final SocketService _socket = SocketService();

  // ── État ───────────────────────────────────────────────
  _Phase _phase = _Phase.lobby;
  late List<dynamic> _players;   // initialisé depuis widget.initialPlayers

  int    _questionIndex  = 0;
  int    _totalQuestions = 7;
  String _questionText   = '';
  List<String> _options  = [];

  int?   _selectedAnswer;
  bool   _answered       = false;
  int    _answeredCount  = 0;
  int?   _correctAnswer;
  Map<String, dynamic> _scores = {};

  List<dynamic> _ranking = [];

  // Timer 20 s
  int    _timeLeft = 20;
  Timer? _countdownTimer;

  // Animation slide
  late AnimationController _slideCtrl;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(
      begin: const Offset(1, 0), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    //  Partir avec les joueurs déjà capturés avant la navigation
    _players = List<dynamic>.from(widget.initialPlayers);
    _setupSocket();
  }

  // ── Listeners ──────────────────────────────────────────
  void _setupSocket() {
    _socket.on('lobby_update', (data) {
      if (!mounted) return;
      setState(() => _players = data['players'] ?? []);
    });

    _socket.on('quiz_question', (data) {
      if (!mounted) return;
      _countdownTimer?.cancel();
      setState(() {
        _phase          = _Phase.playing;
        _questionIndex  = data['index']    ?? 0;
        _totalQuestions = data['total']    ?? 7;
        _questionText   = data['question'] ?? '';
        _options        = List<String>.from(data['options'] ?? []);
        _scores         = Map<String, dynamic>.from(data['scores'] ?? {});
        _selectedAnswer = null;
        _answered       = false;
        _answeredCount  = 0;
        _correctAnswer  = null;
        _timeLeft       = 20;
      });
      _slideCtrl.forward(from: 0);
      _startCountdown();
    });

    _socket.on('quiz_answer_update', (data) {
      if (!mounted) return;
      setState(() => _answeredCount = data['answered'] ?? _answeredCount);
    });

    _socket.on('quiz_reveal', (data) {
      if (!mounted) return;
      _countdownTimer?.cancel();
      setState(() {
        _phase         = _Phase.reveal;
        _correctAnswer = data['correct'];
        _scores        = Map<String, dynamic>.from(data['scores'] ?? _scores);
      });
    });

    _socket.on('quiz_end', (data) {
      if (!mounted) return;
      _countdownTimer?.cancel();
      setState(() {
        _phase   = _Phase.finished;
        _scores  = Map<String, dynamic>.from(data['scores'] ?? {});
        _ranking = data['ranking'] ?? [];
      });
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_timeLeft <= 1) {
        t.cancel();
        setState(() => _timeLeft = 0);
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  // ── Actions ────────────────────────────────────────────
  void _startQuiz() =>
      _socket.socket?.emit('quiz_start', {'roomId': widget.roomId});

  void _sendAnswer(int index) {
    if (_answered) return;
    setState(() { _selectedAnswer = index; _answered = true; });
    _countdownTimer?.cancel();
    _socket.socket?.emit('quiz_answer', {
      'roomId':        widget.roomId,
      'playerName':    widget.playerName,
      'questionIndex': _questionIndex,
      'answerIndex':   index,
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _slideCtrl.dispose();
    _socket.off('lobby_update');
    _socket.off('quiz_question');
    _socket.off('quiz_answer_update');
    _socket.off('quiz_reveal');
    _socket.off('quiz_end');
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _textMid, size: 16),
          onPressed: () {
            _socket.leaveGameRoom(widget.roomId);
            Navigator.pop(context);
          },
        ),
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [_teal, Color(0xFF06B6D4)],
          ).createShader(b),
          child: const Text('Quiz Bien-être 🧠',
            style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
        ),
        actions: [
          if (_phase == _Phase.playing)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _TimerBadge(timeLeft: _timeLeft),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_phase) {
          _Phase.lobby    => _buildLobby(),
          _Phase.playing  => _buildQuestion(),
          _Phase.reveal   => _buildQuestion(revealing: true),
          _Phase.finished => _buildFinished(),
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────
  //  LOBBY
  // ───────────────────────────────────────────────────────
  Widget _buildLobby() {
    return SingleChildScrollView(
      key: const ValueKey('lobby'),
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        // Banner code salle
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF06B6D4)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
              color: _teal.withOpacity(0.3),
              blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(children: [
            const Text('🧠', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            const Text('Code de la salle',
              style: TextStyle(fontSize: 13, color: Colors.white70)),
            const SizedBox(height: 8),
            Text(widget.roomId, style: const TextStyle(
              fontSize: 38, fontWeight: FontWeight.w900,
              color: Colors.white, letterSpacing: 6)),
            const SizedBox(height: 4),
            const Text('Partage ce code avec tes amis',
              style: TextStyle(fontSize: 12, color: Colors.white60)),
          ]),
        ),

        const SizedBox(height: 24),

        // Titre section joueurs
        Row(children: [
          Container(
            width: 3, height: 14,
            decoration: BoxDecoration(
              color: _teal, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          const Text('JOUEURS', style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: _textLight, letterSpacing: 1.8)),
          const Spacer(),
          Text('${_players.length}/6',
            style: const TextStyle(fontSize: 11, color: _textLight)),
        ]),

        const SizedBox(height: 12),

        ..._players.map((p) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _teal.withOpacity(0.12)),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF06B6D4)]),
                borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text(
                (p['name'] ?? '?')[0].toUpperCase(),
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
                  color: _teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _teal.withOpacity(0.25))),
                child: const Text('Toi', style: TextStyle(
                  fontSize: 10, color: _teal, fontWeight: FontWeight.w700))),
          ]),
        )),

        const SizedBox(height: 32),

        if (widget.isHost) ...[
          if (_players.length < 2)
            const Text('En attente d\'un adversaire...',
              style: TextStyle(fontSize: 13, color: _textMid)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _players.length >= 2 ? _startQuiz : null,
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
                      ? const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF06B6D4)])
                      : null,
                  color: _players.length < 2
                      ? const Color(0xFFE5E7EB) : null,
                  borderRadius: BorderRadius.circular(14)),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🧠', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text('Lancer le quiz', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: _players.length >= 2
                            ? Colors.white : _textMid)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardTint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _teal.withOpacity(0.15))),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_top_rounded, color: _teal, size: 18),
                SizedBox(width: 8),
                Text('En attente que l\'hôte lance le quiz...',
                  style: TextStyle(fontSize: 13, color: _textMid)),
              ]),
          ),
      ]),
    );
  }

  // ───────────────────────────────────────────────────────
  //  QUESTION / REVEAL
  // ───────────────────────────────────────────────────────
  Widget _buildQuestion({bool revealing = false}) {
    return SlideTransition(
      key: ValueKey('q$_questionIndex${revealing ? 'r' : ''}'),
      position: _slideAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Barre de progression
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_questionIndex + 1) / _totalQuestions,
                  backgroundColor: _teal.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation(_teal),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('${_questionIndex + 1}/$_totalQuestions',
              style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: _teal)),
          ]),

          const SizedBox(height: 16),

          // Scores en direct
          if (_scores.isNotEmpty)
            _ScoresRow(scores: _scores),

          const SizedBox(height: 16),

          // Carte question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF06B6D4)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: _teal.withOpacity(0.3),
                blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
                child: const Text('🧠 Bien-être', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: Colors.white)),
              ),
              const SizedBox(height: 16),
              Text(_questionText, style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800,
                color: Colors.white, height: 1.3)),
              const SizedBox(height: 16),
              Row(children: [
                Icon(Icons.people_rounded,
                  color: Colors.white.withOpacity(0.8), size: 14),
                const SizedBox(width: 6),
                Text('$_answeredCount/${_players.length} ont répondu',
                  style: TextStyle(
                    fontSize: 12, color: Colors.white.withOpacity(0.8))),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // Options
          ..._options.asMap().entries.map((entry) => _AnswerOption(
            index:    entry.key,
            text:     entry.value,
            selected: _selectedAnswer == entry.key,
            correct:  revealing ? _correctAnswer : null,
            answered: _answered,
            onTap:    () => _sendAnswer(entry.key),
          )),

          const SizedBox(height: 12),

          // Message après avoir répondu (avant reveal)
          if (_answered && !revealing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cardTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _teal.withOpacity(0.2))),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_top_rounded,
                    color: _teal, size: 16),
                  SizedBox(width: 8),
                  Text('Réponse envoyée, on attend les autres...',
                    style: TextStyle(
                      fontSize: 13, color: _teal,
                      fontWeight: FontWeight.w600)),
                ]),
            ),

          // Reveal de la bonne réponse
          if (revealing && _correctAnswer != null && _options.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('✅', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Bonne réponse : ${_options[_correctAnswer!]}',
                      style: const TextStyle(
                        fontSize: 13, color: Color(0xFF065F46),
                        fontWeight: FontWeight.w700)),
                  ),
                ]),
            ),
        ]),
      ),
    );
  }

  // ───────────────────────────────────────────────────────
  //  FIN
  // ───────────────────────────────────────────────────────
  Widget _buildFinished() {
    final myScore  = _scores[widget.playerName] ?? 0;
    final isWinner = _ranking.isNotEmpty &&
        _ranking[0]['name'] == widget.playerName;

    return SingleChildScrollView(
      key: const ValueKey('finished'),
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 16),

        // Bannière
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isWinner
                  ? [const Color(0xFFF59E0B), const Color(0xFFF97316)]
                  : [const Color(0xFF0D9488), const Color(0xFF06B6D4)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(
              color: (isWinner
                  ? const Color(0xFFF59E0B)
                  : _teal).withOpacity(0.35),
              blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Column(children: [
            Text(isWinner ? '🏆' : '🧠',
              style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(isWinner ? 'Tu as gagné !' : 'Partie terminée !',
              style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w900,
                color: Colors.white)),
            const SizedBox(height: 6),
            Text('Ton score : $myScore/$_totalQuestions',
              style: const TextStyle(fontSize: 15, color: Colors.white70)),
          ]),
        ),

        const SizedBox(height: 28),

        // Classement
        Row(children: [
          Container(
            width: 3, height: 14,
            decoration: BoxDecoration(
              color: _teal, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          const Text('CLASSEMENT', style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: _textLight, letterSpacing: 1.8)),
        ]),

        const SizedBox(height: 14),

        ..._ranking.asMap().entries.map((e) {
          final rank  = e.key;
          final entry = e.value;
          final medal = rank == 0 ? '🥇'
              : rank == 1 ? '🥈'
              : rank == 2 ? '🥉'
              : '${rank + 1}.';
          final isMe = entry['name'] == widget.playerName;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isMe ? _teal.withOpacity(0.06) : _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isMe
                    ? _teal.withOpacity(0.3)
                    : Colors.transparent,
                width: isMe ? 1.5 : 1),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Text(medal, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(entry['name'] ?? '',
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: isMe ? _teal : _textDark))),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
                child: Text('${entry['score']} pts',
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: _teal)),
              ),
            ]),
          );
        }),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              _socket.leaveGameRoom(widget.roomId);
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: _teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: _teal.withOpacity(0.5), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14))),
            child: const Text('Retour aux jeux',
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  WIDGETS UTILITAIRES
// ═══════════════════════════════════════════════════════════

class _TimerBadge extends StatelessWidget {
  final int timeLeft;
  const _TimerBadge({required this.timeLeft});

  @override
  Widget build(BuildContext context) {
    final urgent = timeLeft <= 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: urgent
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: urgent
              ? Colors.red.withOpacity(0.3)
              : const Color(0xFF0D9488).withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.timer_rounded, size: 14,
          color: urgent ? Colors.red : const Color(0xFF0D9488)),
        const SizedBox(width: 4),
        Text('$timeLeft s', style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: urgent ? Colors.red : const Color(0xFF0D9488))),
      ]),
    );
  }
}

class _ScoresRow extends StatelessWidget {
  final Map<String, dynamic> scores;
  const _ScoresRow({required this.scores});

  @override
  Widget build(BuildContext context) {
    final entries = scores.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final e = entries[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0D9488).withOpacity(0.15)),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(i == 0 ? '🥇' : i == 1 ? '🥈' : '🥉',
                style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(e.key, style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1B2E))),
                  Text('${e.value} pts', style: const TextStyle(
                    fontSize: 10, color: Color(0xFF0D9488),
                    fontWeight: FontWeight.w600)),
                ],
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  final int index;
  final String text;
  final bool selected;
  final int? correct;    // null = pas encore révélé
  final bool answered;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.index,
    required this.text,
    required this.selected,
    required this.correct,
    required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF0D9488);

    Color  bgColor     = Colors.white;
    Color  borderColor = const Color(0xFFE5E7EB);
    Color  textColor   = const Color(0xFF1E1B2E);
    Widget? trailing;

    if (correct != null) {
      if (index == correct) {
        bgColor     = const Color(0xFFD1FAE5);
        borderColor = Colors.green;
        textColor   = const Color(0xFF065F46);
        trailing    = const Icon(Icons.check_circle_rounded,
          color: Colors.green, size: 20);
      } else if (selected) {
        bgColor     = const Color(0xFFFEE2E2);
        borderColor = Colors.red;
        textColor   = const Color(0xFF991B1B);
        trailing    = const Icon(Icons.cancel_rounded,
          color: Colors.red, size: 20);
      } else {
        bgColor     = const Color(0xFFF9FAFB);
        borderColor = const Color(0xFFE5E7EB);
        textColor   = const Color(0xFF9CA3AF);
      }
    } else if (selected) {
      bgColor     = teal.withOpacity(0.08);
      borderColor = teal;
      textColor   = teal;
    }

    final labels = ['A', 'B', 'C', 'D'];

    return GestureDetector(
      onTap: answered ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: borderColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text(labels[index], style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800,
              color: textColor)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: textColor))),
          if (trailing != null) trailing,
        ]),
      ),
    );
  }
}