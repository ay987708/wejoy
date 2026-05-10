import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wejoy/screens/service/socket_service.dart';
import 'games_hub.dart';

class TruthOrDareScreen extends StatefulWidget {
  final String roomId, playerName;
  final bool isHost;
  const TruthOrDareScreen({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.isHost,
  });
  @override
  State<TruthOrDareScreen> createState() => _TruthOrDareScreenState();
}

class _TruthOrDareScreenState extends State<TruthOrDareScreen>
    with TickerProviderStateMixin {
  final SocketService _socket = SocketService();

  static const _bg     = Color(0xFF0F172A);
  static const _card   = Color(0xFF1E293B);
  static const _amber  = Color(0xFFF59E0B);
  static const _purple = Color(0xFF8B5CF6);
  static const _red    = Color(0xFFEF4444);

  // ── Lobby ──
  List<dynamic> _players = [];
  bool _gameStarted      = false;

  // ── Tour en cours ──
  String _currentPlayer  = '';
  String? _choiceMode;
  String _challenge      = '';
  int _turnIndex         = 0;
  int _totalTurns        = 0;
  int _countdown         = 30;
  bool _challengeActive  = false;
  bool _doneSent         = false;

  // ── Réponse Vérité ──
  String _answer                    = '';
  final TextEditingController _answerController = TextEditingController();

  // ── Spin animation ──
  late AnimationController _spinCtrl;
  late Animation<double> _spinAnim;
  bool _spinning         = false;

  // ── Fin ──
  bool _gameOver         = false;

  @override
  void initState() {
    super.initState();

    _spinCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _spinAnim = CurvedAnimation(parent: _spinCtrl, curve: Curves.easeOut);

    _socket.on('lobby_update', (data) {
      if (!mounted) return;
      setState(() => _players = data['players'] ?? []);
    });

    _socket.on('tod_spin', (data) {
      if (!mounted) return;
      setState(() {
        _gameStarted     = true;
        _spinning        = true;
        _currentPlayer   = data['player'] ?? '';
        _turnIndex       = data['turnIndex'] ?? 0;
        _totalTurns      = data['totalTurns'] ?? 0;
        _choiceMode      = null;
        _challenge       = '';
        _challengeActive = false;
        _doneSent        = false;
        _countdown       = 30;
        // Reset réponse à chaque nouveau tour
        _answer          = '';
        _answerController.clear();
      });
      _spinCtrl.reset();
      _spinCtrl.forward().then((_) {
        if (mounted) setState(() => _spinning = false);
      });
    });

    _socket.on('tod_challenge', (data) {
      if (!mounted) return;
      setState(() {
        _choiceMode      = data['mode'];
        _challenge       = data['challenge'] ?? '';
        _challengeActive = true;
        _doneSent        = false;
        _countdown       = 30;
        _answer          = '';
        _answerController.clear();
      });
      _startCountdown();
    });

    // Réception de la réponse de l'autre joueur (Vérité)
    _socket.on('tod_answer', (data) {
      if (!mounted) return;
      setState(() => _answer = data['answer'] ?? '');
    });

    _socket.on('tod_end', (_) {
      if (!mounted) return;
      setState(() => _gameOver = true);
    });
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_challengeActive) return false;
      setState(() => _countdown--);
      return _countdown > 0 && _challengeActive;
    });
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _answerController.dispose();
    _socket.off('lobby_update');
    _socket.off('tod_spin');
    _socket.off('tod_challenge');
    _socket.off('tod_answer');
    _socket.off('tod_end');
    super.dispose();
  }

  void _startGame() => _socket.startTod(widget.roomId);

  void _chooseMode(String mode) {
    if (_currentPlayer != widget.playerName) return;
    if (_choiceMode != null) return;
    _socket.chooseTod(widget.roomId, mode);
  }

  void _done() {
    if (_doneSent) return;
    if (_currentPlayer != widget.playerName) return;
    if (!_challengeActive) return;
    setState(() {
      _doneSent        = true;
      _challengeActive = false;
    });
    _socket.doneTod(widget.roomId);
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
          onPressed: () { _socket.leaveGameRoom(widget.roomId); Navigator.pop(context); },
        ),
        title: const Text('Action ou Vérité ⚡',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: Column(children: [
              Text('Code de la salle', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.4))),
              const SizedBox(height: 8),
              Text(widget.roomId, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _amber, letterSpacing: 6)),
              const SizedBox(height: 4),
              const Text('Partage ce code avec tes amis', style: TextStyle(fontSize: 12, color: Colors.white24)),
            ]),
          ),
          const SizedBox(height: 20),
          Text('JOUEURS (${_players.length})',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.3), letterSpacing: 1.5)),
          const SizedBox(height: 12),
          ..._players.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: Row(children: [
              Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: _amber.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Text((p['name'] ?? '?')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _amber))),
              const SizedBox(width: 12),
              Expanded(child: Text(p['name'] ?? '',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
              if (p['name'] == widget.playerName)
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _amber.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Toi', style: TextStyle(fontSize: 10, color: _amber, fontWeight: FontWeight.w700))),
            ]),
          )),
          const Spacer(),
          if (widget.isHost) ...[
            if (_players.length < 2)
              Text('En attente d\'un adversaire...', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.3))),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _players.length >= 2 ? _startGame : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _amber, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0, disabledBackgroundColor: Colors.white10,
                ),
                child: const Text('Lancer le jeu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ] else
            Text('En attente que l\'hôte lance la partie...', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.35))),
        ]),
      ),
    );
  }

  // ─── Jeu ─────────────────────────────────────────────
  Widget _buildGame() {
    final isMe = _currentPlayer == widget.playerName;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(children: [

            // ── Progress bar ──
            Row(children: [
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _totalTurns > 0 ? _turnIndex / _totalTurns : 0,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  color: _amber, minHeight: 6,
                ),
              )),
              const SizedBox(width: 12),
              Text('$_turnIndex/$_totalTurns',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white54)),
            ]),

            const SizedBox(height: 20),

            // ── Liste des joueurs ──
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _players.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p      = _players[i];
                  final name   = p['name'] ?? '';
                  final active = name == _currentPlayer;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? _amber.withOpacity(0.15) : _card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: active ? _amber.withOpacity(0.5) : Colors.white.withOpacity(0.05),
                          width: active ? 1.5 : 1),
                    ),
                    child: Row(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: active ? _amber.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(name[0].toUpperCase(),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                color: active ? _amber : Colors.white38)),
                      ),
                      const SizedBox(width: 8),
                      Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: active ? Colors.white : Colors.white38)),
                    ]),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ── Zone principale ──
            Expanded(
              child: _spinning
                  ? _buildSpinning()
                  : _choiceMode == null
                      ? _buildChoicePrompt(isMe)
                      : _buildChallenge(isMe),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Animation spin ───────────────────────────────────
  Widget _buildSpinning() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      AnimatedBuilder(
        animation: _spinAnim,
        builder: (_, __) => Transform.rotate(
          angle: _spinAnim.value * 6 * pi,
          child: Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(colors: [_amber, _purple, _red, _amber]),
              boxShadow: [BoxShadow(color: _amber.withOpacity(0.3), blurRadius: 30, spreadRadius: 4)],
            ),
            alignment: Alignment.center,
            child: Container(
              width: 90, height: 90,
              decoration: const BoxDecoration(color: _bg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text('⚡', style: TextStyle(fontSize: 36)),
            ),
          ),
        ),
      ),
      const SizedBox(height: 28),
      const Text('La roue tourne...', style: TextStyle(fontSize: 16, color: Colors.white54)),
      const SizedBox(height: 8),
      AnimatedBuilder(
        animation: _spinAnim,
        builder: (_, __) => _spinAnim.value > 0.7
            ? Text(_currentPlayer, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white))
            : const SizedBox.shrink(),
      ),
    ]);
  }

  // ── Choix : Action ou Vérité ─────────────────────────
  Widget _buildChoicePrompt(bool isMe) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: _amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _amber.withOpacity(0.3)),
        ),
        child: Text(
          isMe ? '⚡ C\'est ton tour !' : '🎯 C\'est le tour de $_currentPlayer',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isMe ? _amber : Colors.white54),
        ),
      ),

      const SizedBox(height: 40),
      const Text('Choisis', style: TextStyle(fontSize: 18, color: Colors.white54)),
      const SizedBox(height: 20),

      Row(children: [
        // VÉRITÉ
        Expanded(child: GestureDetector(
          onTap: isMe ? () => _chooseMode('truth') : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 130,
            decoration: BoxDecoration(
              color: isMe ? _purple.withOpacity(0.15) : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isMe ? _purple.withOpacity(0.5) : Colors.white.withOpacity(0.05),
                  width: 1.5),
            ),
            alignment: Alignment.center,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🔮', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 10),
              Text('Vérité', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                  color: isMe ? _purple : Colors.white24)),
            ]),
          ),
        )),

        const SizedBox(width: 16),

        // ACTION
        Expanded(child: GestureDetector(
          onTap: isMe ? () => _chooseMode('dare') : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 130,
            decoration: BoxDecoration(
              color: isMe ? _red.withOpacity(0.15) : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isMe ? _red.withOpacity(0.5) : Colors.white.withOpacity(0.05),
                  width: 1.5),
            ),
            alignment: Alignment.center,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🔥', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 10),
              Text('Action', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                  color: isMe ? _red : Colors.white24)),
            ]),
          ),
        )),
      ]),

      const SizedBox(height: 24),
      if (!isMe)
        Text('En attente que $_currentPlayer choisisse...',
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.3))),
    ]);
  }

  // ── Défi affiché ─────────────────────────────────────
  Widget _buildChallenge(bool isMe) {
    final isDare = _choiceMode == 'dare';
    final color  = isDare ? _red : _purple;
    final emoji  = isDare ? '🔥' : '🔮';
    final label  = isDare ? 'Action' : 'Vérité';

    return SingleChildScrollView(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

        const SizedBox(height: 16),

        // Badge mode + joueur
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text('$label — $_currentPlayer',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),

        const SizedBox(height: 24),

        // Carte défi
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 24, spreadRadius: 2)],
          ),
          child: Text(_challenge, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, height: 1.5)),
        ),

        const SizedBox(height: 20),

        // ── Zone réponse Vérité uniquement ──
        if (!isDare) ...[
          if (isMe) ...[
            // Le joueur ciblé tape sa réponse
            TextField(
              controller: _answerController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ta réponse...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                filled: true,
                fillColor: _card,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: color.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: color.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: color, width: 1.5),
                ),
              ),
              onChanged: (val) => _socket.answerTod(widget.roomId, val),
            ),
            const SizedBox(height: 16),
          ] else ...[
            // L'autre joueur voit la réponse en temps réel
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: _answer.isEmpty
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: color.withOpacity(0.5)),
                      ),
                      const SizedBox(width: 10),
                      Text('$_currentPlayer est en train de répondre...',
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.35))),
                    ])
                  : Text(_answer,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white, height: 1.4)),
            ),
            const SizedBox(height: 16),
          ],
        ],

        // Countdown
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.timer_outlined, size: 16, color: _countdown <= 10 ? _red : Colors.white38),
          const SizedBox(width: 6),
          Text('$_countdown s', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700,
              color: _countdown <= 10 ? _red : Colors.white54)),
          const SizedBox(width: 6),
          Text('— auto', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.25))),
        ]),

        const SizedBox(height: 20),

        // Boutons uniquement pour le joueur désigné
        if (isMe) Row(children: [
          Expanded(child: ElevatedButton(
            onPressed: _doneSent ? null : _done,
            style: ElevatedButton.styleFrom(
              backgroundColor: color, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0, disabledBackgroundColor: Colors.white10,
            ),
            child: const Text('✅  J\'ai fait !', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          )),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton(
            onPressed: _doneSent ? null : _done,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white54,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('⏭  Passer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          )),
        ]) else
          Text('En attente que $_currentPlayer termine...',
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.3))),

        const SizedBox(height: 16),
      ]),
    );
  }

  // ─── Écran de fin ─────────────────────────────────────
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
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 12),
            Text('Vous avez joué $_totalTurns tours ensemble.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.white54)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                    context, MaterialPageRoute(builder: (_) => const GamesHub()), (_) => false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _amber, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Retour aux jeux', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
