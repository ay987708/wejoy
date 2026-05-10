import 'package:flutter/material.dart';
import 'package:wejoy/screens/service/socket_service.dart';
import 'games_hub.dart';

class WouldYouRatherScreen extends StatefulWidget {
  final String roomId, playerName;
  final bool isHost;
  const WouldYouRatherScreen({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.isHost,
  });
  @override
  State<WouldYouRatherScreen> createState() => _WouldYouRatherScreenState();
}

class _WouldYouRatherScreenState extends State<WouldYouRatherScreen>
    with TickerProviderStateMixin {
  final SocketService _socket = SocketService();

  static const _bg    = Color(0xFF0F172A);
  static const _card  = Color(0xFF1E293B);
  static const _coral = Color(0xFFF97316);
  static const _blue  = Color(0xFF3B82F6);

  // ── Lobby ──────────────────────────────────────────────
  List<dynamic> _players  = [];
  bool _gameStarted       = false;

  // ── Question ──────────────────────────────────────────
  String _questionA       = '';
  String _questionB       = '';
  int _currentIndex       = 0;
  int _totalQuestions     = 0;
  List<String> _votesA    = [];
  List<String> _votesB    = [];
  String? _myVote;
  bool _revealed          = false;
  int _totalVoted         = 0;

  // ── Countdown affiché pendant le reveal ───────────────
  int _revealCountdown    = 5;

  // ── Fin ───────────────────────────────────────────────
  bool _gameOver          = false;

  late AnimationController _barCtrlA;
  late AnimationController _barCtrlB;
  late Animation<double> _barAnimA;
  late Animation<double> _barAnimB;

  @override
  void initState() {
    super.initState();

    _barCtrlA = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _barCtrlB = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _barAnimA = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _barCtrlA, curve: Curves.easeOut));
    _barAnimB = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _barCtrlB, curve: Curves.easeOut));

    _socket.on('lobby_update', (data) {
      if (!mounted) return;
      setState(() => _players = data['players'] ?? []);
    });

    _socket.on('wyr_question', (data) {
      if (!mounted) return;
      setState(() {
        _gameStarted     = true;
        _questionA       = data['questionA'] ?? '';
        _questionB       = data['questionB'] ?? '';
        _currentIndex    = data['index'] ?? 0;
        _totalQuestions  = data['total'] ?? 0;
        _votesA          = [];
        _votesB          = [];
        _myVote          = null;
        _revealed        = false;
        _totalVoted      = 0;
        _revealCountdown = 5;
      });
      _animateBars(0, 0);
    });

    _socket.on('wyr_vote_update', (data) {
      if (!mounted) return;
      final votes = data['votes'];
      setState(() {
        _votesA     = List<String>.from(votes['a'] ?? []);
        _votesB     = List<String>.from(votes['b'] ?? []);
        _totalVoted = data['totalVoted'] ?? 0;
      });
    });

    _socket.on('wyr_reveal', (data) {
      if (!mounted) return;
      final votes = data['votes'];
      setState(() {
        _votesA          = List<String>.from(votes['a'] ?? []);
        _votesB          = List<String>.from(votes['b'] ?? []);
        _revealed        = true;
        _revealCountdown = 5;
      });
      final total = _votesA.length + _votesB.length;
      if (total > 0) {
        _animateBars(_votesA.length / total, _votesB.length / total);
      }
      _startRevealCountdown();
    });

    _socket.on('wyr_end', (data) {
      if (!mounted) return;
      setState(() => _gameOver = true);
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

  void _animateBars(double a, double b) {
    _barCtrlA.dispose();
    _barCtrlB.dispose();
    _barCtrlA = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _barCtrlB = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _barAnimA = Tween<double>(begin: 0, end: a).animate(
        CurvedAnimation(parent: _barCtrlA, curve: Curves.easeOut));
    _barAnimB = Tween<double>(begin: 0, end: b).animate(
        CurvedAnimation(parent: _barCtrlB, curve: Curves.easeOut));
    _barCtrlA.forward();
    _barCtrlB.forward();
  }

  @override
  void dispose() {
    _barCtrlA.dispose();
    _barCtrlB.dispose();
    _socket.off('lobby_update');
    _socket.off('wyr_question');
    _socket.off('wyr_vote_update');
    _socket.off('wyr_reveal');
    _socket.off('wyr_end');
    super.dispose();
  }

  void _startGame() => _socket.startWyr(widget.roomId);

  void _vote(String choice) {
    if (_myVote != null || _revealed) return;
    setState(() => _myVote = choice);
    _socket.voteWyr(widget.roomId, widget.playerName, choice);
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
        title: const Text('Ce que je préfère 💬',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: Column(children: [
              Text('Code de la salle',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.4))),
              const SizedBox(height: 8),
              Text(widget.roomId,
                  style: const TextStyle(
                      fontSize: 36, fontWeight: FontWeight.w800,
                      color: _coral, letterSpacing: 6)),
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
                decoration: BoxDecoration(
                    color: _card, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05))),
                child: Row(children: [
                  Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                          color: _coral.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: Text((p['name'] ?? '?')[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700, color: _coral))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(p['name'] ?? '',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
                  if (p['name'] == widget.playerName)
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: _coral.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20)),
                        child: const Text('Toi',
                            style: TextStyle(
                                fontSize: 10, color: _coral, fontWeight: FontWeight.w700))),
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
                onPressed: _players.length >= 2 ? _startGame : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _coral, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0, disabledBackgroundColor: Colors.white10,
                ),
                child: const Text('Lancer le jeu',
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
    final totalVotes = _votesA.length + _votesB.length;
    final pctA = totalVotes > 0 ? (_votesA.length / totalVotes * 100).round() : 0;
    final pctB = totalVotes > 0 ? (_votesB.length / totalVotes * 100).round() : 0;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(children: [

            // ── Progress bar question ──
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _totalQuestions,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    color: _coral, minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${_currentIndex + 1}/$_totalQuestions',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white54)),
            ]),

            const SizedBox(height: 28),

            // ── Label ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                  color: _coral.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _coral.withOpacity(0.3))),
              child: const Text('Tu préfères... ?',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _coral)),
            ),

            const SizedBox(height: 28),

            // ── Option A ──
            _VoteCard(
              label: 'A', text: _questionA, color: _coral,
              voted: _myVote == 'a', revealed: _revealed,
              percent: pctA, voters: _votesA,
              barAnim: _barAnimA, barCtrl: _barCtrlA,
              onTap: () => _vote('a'),
            ),

            const SizedBox(height: 14),

            // ── VS ──
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF243044),
                  border: Border.all(color: Colors.white.withOpacity(0.08))),
              alignment: Alignment.center,
              child: const Text('VS',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white38)),
            ),

            const SizedBox(height: 14),

            // ── Option B ──
            _VoteCard(
              label: 'B', text: _questionB, color: _blue,
              voted: _myVote == 'b', revealed: _revealed,
              percent: pctB, voters: _votesB,
              barAnim: _barAnimB, barCtrl: _barCtrlB,
              onTap: () => _vote('b'),
            ),

            const Spacer(),

            // ── Statut ──
            if (!_revealed) ...[
              if (_myVote == null)
                Text('Vote pour continuer !',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.3)))
              else
                Text('$_totalVoted/${_players.length} ont voté',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.3))),
            ],

            // ── Reveal : résultats + countdown ──
            if (_revealed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _coral.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _coral.withOpacity(0.25)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    _myVote == null
                        ? '⏱ Temps écoulé !'
                        : _votesA.length >= _votesB.length && _myVote == 'a'
                            ? '🎉 Majorité avec toi !'
                            : _votesB.length >= _votesA.length && _myVote == 'b'
                                ? '🎉 Majorité avec toi !'
                                : '🤔 Tu étais minorité !',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: _coral),
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
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white54)),
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
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🎉', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            const Text('Partie terminée !',
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 12),
            Text('Vous avez joué $_totalQuestions questions ensemble.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.white54)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const GamesHub()),
                    (_) => false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _coral, foregroundColor: Colors.white,
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

// ═══════════════════════════════════════════════════════════
//  WIDGET — Carte de vote
// ═══════════════════════════════════════════════════════════

class _VoteCard extends StatelessWidget {
  final String label, text;
  final Color color;
  final bool voted, revealed;
  final int percent;
  final List<String> voters;
  final Animation<double> barAnim;
  final AnimationController barCtrl;
  final VoidCallback onTap;

  const _VoteCard({
    required this.label, required this.text, required this.color,
    required this.voted, required this.revealed, required this.percent,
    required this.voters, required this.barAnim, required this.barCtrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: voted ? color.withOpacity(0.15) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: voted ? color.withOpacity(0.6) : Colors.white.withOpacity(0.07),
            width: voted ? 1.5 : 1,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: color)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: Colors.white, height: 1.3))),
            if (voted)
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('Ton choix',
                      style: TextStyle(
                          fontSize: 10, color: color, fontWeight: FontWeight.w700))),
          ]),
          if (revealed) ...[
            const SizedBox(height: 14),
            AnimatedBuilder(
              animation: barAnim,
              builder: (_, __) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: barAnim.value,
                        backgroundColor: Colors.white.withOpacity(0.06),
                        color: color, minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text('$percent%',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800, color: color)),
                      const SizedBox(width: 8),
                      Text(
                          voters.isEmpty ? 'Personne' : voters.join(', '),
                          style: const TextStyle(fontSize: 11, color: Colors.white38)),
                    ]),
                  ]),
            ),
          ],
        ]),
      ),
    );
  }
}
