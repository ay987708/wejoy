import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class MemoryPage extends StatefulWidget {
  final IO.Socket socket;
  final Map<String, dynamic> room;
  final String playerName;

  const MemoryPage({
    super.key,
    required this.socket,
    required this.room,
    required this.playerName,
  });

  @override
  State<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends State<MemoryPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _cards = [];
  Map<String, dynamic> _scores     = {};
  String? _currentTurn;
  int _matchedPairs                 = 0;
  bool _locked                      = false;
  Map<String, dynamic>? _endResult;
  List<dynamic> _players            = [];

  final Map<int, AnimationController> _flipControllers = {};
  final Map<int, Animation<double>>   _flipAnimations  = {};

  static const _bg      = Color(0xFF0F172A);
  static const _card    = Color(0xFF1E293B);
  static const _accent1 = Color(0xFF8B5CF6);
  static const _accent2 = Color(0xFFF59E0B);
  static const _matched = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _players = List.from(widget.room['players'] ?? []);

    // ✅ FIX 1 : lire le state correctement depuis room
    final rawState = widget.room['state'];
    if (rawState != null && rawState is Map) {
      _applyState(Map<String, dynamic>.from(rawState));
    }

    // ✅ FIX 2 : si cartes vides, écouter game_start qui renvoie tout
    widget.socket.on('game_start', (data) {
      if (!mounted) return;
      final r = Map<String, dynamic>.from(data as Map);
      final rawS = r['state'];
      if (rawS != null && rawS is Map) {
        _applyState(Map<String, dynamic>.from(rawS));
      }
    });

    widget.socket.on('memory_update', (data) {
      if (!mounted) return;
      final prev = List<Map<String, dynamic>>.from(_cards);
      _applyState(Map<String, dynamic>.from(data as Map));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (int i = 0; i < _cards.length; i++) {
          final wasFlipped = i < prev.length ? (prev[i]['flipped'] as bool? ?? false) : false;
          final wasMatched = i < prev.length ? (prev[i]['matched'] as bool? ?? false) : false;
          final nowFlipped = _cards[i]['flipped'] as bool? ?? false;
          final nowMatched = _cards[i]['matched'] as bool? ?? false;

          if ((!wasFlipped && nowFlipped) || (!wasMatched && nowMatched)) {
            _playFlip(i, true);
          } else if (wasFlipped && !nowFlipped && !nowMatched) {
            _playFlip(i, false);
          }
        }
      });
    });

    widget.socket.on('memory_end', (data) {
      if (!mounted) return;
      final d = Map<String, dynamic>.from(data as Map);
      setState(() {
        _endResult = d;
        _players   = List.from(d['players'] ?? _players);
      });
    });
  }

  void _applyState(Map<String, dynamic> state) {
    if (!mounted) return;
    setState(() {
      // ✅ FIX 3 : parser les cartes avec cast sécurisé
      final rawCards = state['cards'];
      if (rawCards != null && rawCards is List && rawCards.isNotEmpty) {
        _cards = rawCards.map<Map<String, dynamic>>((c) {
          return c is Map ? Map<String, dynamic>.from(c) : <String, dynamic>{};
        }).toList();

        for (int i = 0; i < _cards.length; i++) {
          if (!_flipControllers.containsKey(i)) {
            final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
            _flipControllers[i] = ctrl;
            _flipAnimations[i]  = Tween<double>(begin: 0, end: 1)
                .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
          }
          final isActive = _cards[i]['flipped'] == true || _cards[i]['matched'] == true;
          final ctrl = _flipControllers[i]!;
          if (isActive && ctrl.value < 0.5) ctrl.value = 1.0;
          else if (!isActive && ctrl.value > 0.5) ctrl.value = 0.0;
        }
      }

      // ✅ FIX 4 : scores avec cast sécurisé
      final rawScores = state['scores'];
      if (rawScores is Map) {
        _scores = rawScores.map((k, v) => MapEntry(k.toString(), v));
      }

      final t = state['currentTurn'];
      if (t != null) _currentTurn = t.toString();

      final p = state['matchedPairs'];
      if (p != null) _matchedPairs = (p as num).toInt();

      final l = state['locked'];
      if (l != null) _locked = l as bool? ?? false;
    });
  }

  void _playFlip(int i, bool forward) {
    final ctrl = _flipControllers[i];
    if (ctrl == null) return;
    if (forward && ctrl.value < 0.5) ctrl.forward();
    else if (!forward && ctrl.value > 0.5) ctrl.reverse();
  }

  bool get _isMyTurn => _currentTurn == widget.playerName && !_locked;

  void _flip(int i) {
    if (!_isMyTurn || i >= _cards.length) return;
    if (_cards[i]['flipped'] == true || _cards[i]['matched'] == true) return;
    widget.socket.emit('memory_flip', {
      'roomId':     widget.room['id'],
      'cardIndex':  i,
      'playerName': widget.playerName,
    });
  }

  void _reset() {
    setState(() { _endResult = null; _cards = []; });
    widget.socket.emit('memory_reset', {'roomId': widget.room['id']});
  }

  @override
  void dispose() {
    for (final c in _flipControllers.values) c.dispose();
    widget.socket.off('memory_update');
    widget.socket.off('memory_end');
    widget.socket.off('game_start');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_endResult != null) return _buildEndScreen();

    final totalPairs = _cards.length ~/ 2;
    final progress   = totalPairs > 0 ? _matchedPairs / totalPairs : 0.0;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white54, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Memory 🧩', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _accent1.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accent1.withOpacity(0.3)),
            ),
            child: Text('$_matchedPairs / $totalPairs paires',
              style: const TextStyle(color: _accent1, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(children: [

        // ── Score bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: Column(children: [
              Row(children: _players.map((p) {
                final name     = p['name']?.toString() ?? '';
                final score    = (_scores[name] ?? 0) as num;
                final isActive = _currentTurn == name;
                final isMe     = name == widget.playerName;
                final color    = isMe ? _accent1 : _accent2;
                return Expanded(child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isActive ? color.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isActive ? color.withOpacity(0.4) : Colors.transparent),
                  ),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (isActive) Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                      Flexible(child: Text(name, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: isActive ? color : Colors.white38))),
                      if (isMe) Container(margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                        child: Text('Toi', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700))),
                    ]),
                    const SizedBox(height: 4),
                    Text('${score.toInt()} 🃏', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: isActive ? color : Colors.white38)),
                  ]),
                ));
              }).toList()),
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white.withOpacity(0.06),
                  color: _matched, minHeight: 5)),
              const SizedBox(height: 6),
              Text(_isMyTurn ? '👆 C\'est ton tour !' : '⏳ Tour de $_currentTurn',
                style: TextStyle(fontSize: 12, color: _isMyTurn ? _accent1 : Colors.white30, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),

        // ── Grille ──
        Expanded(
          child: _cards.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(color: _accent1, strokeWidth: 2.5),
                  const SizedBox(height: 16),
                  const Text('Chargement des cartes...', style: TextStyle(color: Colors.white38, fontSize: 13)),
                ]))
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.85),
                    itemCount: _cards.length,
                    itemBuilder: (_, i) => _buildCard(i),
                  ),
                ),
        ),
        const SizedBox(height: 12),
      ]),
    );
  }

  Widget _buildCard(int i) {
    if (i >= _cards.length) return const SizedBox();
    final card      = _cards[i];
    final isFlipped = card['flipped'] == true || card['matched'] == true;
    final isMatched = card['matched'] == true;
    final canTap    = _isMyTurn && !isFlipped;
    final ctrl      = _flipControllers[i];
    final anim      = _flipAnimations[i];

    return GestureDetector(
      onTap: () => _flip(i),
      child: AnimatedBuilder(
        animation: anim ?? AlwaysStoppedAnimation(isFlipped ? 1.0 : 0.0),
        builder: (_, __) {
          final val       = ctrl?.value ?? (isFlipped ? 1.0 : 0.0);
          final showFront = val >= 0.5;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isMatched ? _matched.withOpacity(0.15)
                  : showFront ? _card
                  : canTap ? const Color(0xFF2D3A50)
                  : const Color(0xFF1A2332),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMatched ? _matched.withOpacity(0.5)
                    : showFront ? _accent1.withOpacity(0.3)
                    : canTap ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.04),
                width: isMatched ? 1.5 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: showFront
                ? Text(card['emoji']?.toString() ?? '?', style: TextStyle(fontSize: isMatched ? 26 : 24))
                : canTap
                    ? const Text('🎴', style: TextStyle(fontSize: 22))
                    : const Icon(Icons.style_rounded, color: Colors.white12, size: 20),
          );
        },
      ),
    );
  }

  Widget _buildEndScreen() {
    final scores = Map<String, dynamic>.from(_endResult!['scores'] ?? {});
    final winner = _endResult!['winner']?.toString() ?? '';
    final isDraw = winner == 'draw';
    final iWon   = winner == widget.playerName;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(isDraw ? '🤝' : iWon ? '🏆' : '😔', style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            Text(isDraw ? 'Match nul !' : iWon ? 'Tu as gagné !' : '$winner a gagné !',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                color: isDraw ? _accent2 : iWon ? _matched : Colors.white54)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.06))),
              child: Column(children: _players.map((p) {
                final name  = p['name']?.toString() ?? '';
                final score = (scores[name] ?? 0) as num;
                final isMe  = name == widget.playerName;
                final color = isMe ? _accent1 : _accent2;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: Text(p['symbol']?.toString() ?? '?',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                      color: isMe ? Colors.white : Colors.white60))),
                    Text('${score.toInt()} paire${score.toInt() > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
                  ]),
                );
              }).toList()),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _reset,
                style: ElevatedButton.styleFrom(backgroundColor: _accent1, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: const Text('Rejouer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text('Retour aux jeux', style: TextStyle(color: Colors.white30)),
            ),
          ]),
        ),
      ),
    );
  }
}
