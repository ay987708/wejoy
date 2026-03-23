import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

const String _serverUrl = 'http://192.168.1.11:5000';

// ══════════════════════════════════════════════════════════════════════════════
// PAGE PRINCIPALE DÉFIS
// ══════════════════════════════════════════════════════════════════════════════
class DefisPage extends StatelessWidget {
  const DefisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD63FBF), Color(0xFF9C27B0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFD63FBF).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🎮 Jeux collaboratifs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                    SizedBox(height: 6),
                    Text('Jouez avec vos amis en temps réel', style: TextStyle(fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Comment jouer ────────────────────────────────────────────
              const Text('Comment jouer ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    _HowToStep(number: '1', text: 'Choisis un jeu et clique sur Jouer'),
                    _HowToStep(number: '2', text: 'Entre ton prénom et un code de room'),
                    _HowToStep(number: '3', text: 'Partage le code avec ton ami'),
                    _HowToStep(number: '4', text: 'La partie commence quand vous êtes 2 !', isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Jeux disponibles ─────────────────────────────────────────
              const Text('Jeux disponibles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              _GameCard(
                emoji: '❌⭕',
                title: 'Morpion',
                description: 'Le classique ! Alignez 3 symboles pour gagner.',
                players: '2 joueurs',
                difficulty: 'Facile',
                color: const Color(0xFF6366F1),
                onTap: () => _showRoomDialog(context, 'morpion'),
              ),
              const SizedBox(height: 16),

              _GameCard(
                emoji: '🎭',
                title: 'Action ou Vérité',
                description: 'Tirez une carte et relevez le défi ou répondez honnêtement !',
                players: '2+ joueurs',
                difficulty: 'Fun',
                color: const Color(0xFFD63FBF),
                onTap: () => _showRoomDialog(context, 'action_verite'),
              ),
              const SizedBox(height: 16),

              _GameCard(
                emoji: '🧠',
                title: 'Quiz Bien-être',
                description: 'Testez vos connaissances sur la santé et le bien-être !',
                players: '2 joueurs',
                difficulty: 'Moyen',
                color: const Color(0xFF22C55E),
                onTap: () => _showRoomDialog(context, 'quiz'),
              ),
              const SizedBox(height: 24),

              // ── Stats rapides ────────────────────────────────────────────
              const Text('Vos stats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _StatBox(emoji: '🎮', value: '0', label: 'Parties jouées')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatBox(emoji: '🏆', value: '0', label: 'Victoires')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatBox(emoji: '🔥', value: '0', label: 'Série')),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoomDialog(BuildContext context, String gameType) {
    final roomController = TextEditingController();
    final nameController = TextEditingController();

    final gameNames = {
      'morpion': 'Morpion ❌⭕',
      'action_verite': 'Action ou Vérité 🎭',
      'quiz': 'Quiz Bien-être 🧠',
    };

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Text(gameNames[gameType] ?? 'Jeu', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Rejoindre ou créer une partie', style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w400)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: _inputDecoration('Ton prénom', Icons.person_outline_rounded),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roomController,
              decoration: _inputDecoration('Code de la room (ex: ABC123)', Icons.tag_rounded),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFD63FBF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFD63FBF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Inventez un code et partagez-le avec votre ami',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD63FBF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              if (nameController.text.trim().isEmpty || roomController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Remplis tous les champs !'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameLobbyPage(
                    roomId: roomController.text.trim().toUpperCase(),
                    playerName: nameController.text.trim(),
                    gameType: gameType,
                  ),
                ),
              );
            },
            child: const Text('Rejoindre', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      prefixIcon: Icon(icon, size: 18, color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD63FBF), width: 1.5),
      ),
    );
  }
}

// ── Widgets utilitaires ───────────────────────────────────────────────────────
class _HowToStep extends StatelessWidget {
  final String number;
  final String text;
  final bool isLast;
  const _HowToStep({required this.number, required this.text, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: const Color(0xFFD63FBF).withOpacity(0.1), shape: BoxShape.circle),
            child: Center(child: Text(number, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFD63FBF)))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatBox({required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFD63FBF))),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final String players;
  final String difficulty;
  final Color color;
  final VoidCallback onTap;

  const _GameCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.players,
    required this.difficulty,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 30))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Tag(text: players, color: color),
                      const SizedBox(width: 6),
                      _Tag(text: difficulty, color: Colors.grey[600]!),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
              child: const Text('Jouer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// LOBBY
// ══════════════════════════════════════════════════════════════════════════════
class GameLobbyPage extends StatefulWidget {
  final String roomId;
  final String playerName;
  final String gameType;
  const GameLobbyPage({super.key, required this.roomId, required this.playerName, required this.gameType});

  @override
  State<GameLobbyPage> createState() => _GameLobbyPageState();
}

class _GameLobbyPageState extends State<GameLobbyPage> {
  late IO.Socket socket;
  Map<String, dynamic>? room;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    socket = IO.io(_serverUrl, IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build());
    socket.connect();

    socket.onConnect((_) {
      socket.emit('join_room', {
        'roomId': widget.roomId,
        'playerName': widget.playerName,
        'gameType': widget.gameType,
      });
    });

    socket.on('room_update', (data) {
      if (mounted) setState(() => room = Map<String, dynamic>.from(data));
    });

    socket.on('game_start', (data) {
      if (!mounted) return;
      setState(() => room = Map<String, dynamic>.from(data));
      _navigateToGame();
    });

    socket.on('player_left', (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Un joueur a quitté la partie 😢'), backgroundColor: Colors.orange),
        );
        setState(() => room = null);
      }
    });
  }

  void _navigateToGame() {
    Widget page;
    if (widget.gameType == 'morpion') {
      page = MorpionPage(socket: socket, room: room!, playerName: widget.playerName);
    } else if (widget.gameType == 'action_verite') {
      page = ActionVeritePage(socket: socket, room: room!, playerName: widget.playerName);
    } else {
      page = QuizPage(socket: socket, room: room!, playerName: widget.playerName);
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerCount = (room?['players'] as List?)?.length ?? 0;
    final players = (room?['players'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Salle d\'attente', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            socket.disconnect();
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    Text('Code de la room', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD63FBF).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.roomId,
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFFD63FBF), letterSpacing: 6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Partage ce code avec ton ami !', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Joueurs', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('$playerCount / 2', style: const TextStyle(color: Color(0xFFD63FBF), fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _PlayerSlot(name: players.isNotEmpty ? players[0]['name'] : null, symbol: 'X'),
                        const SizedBox(width: 12),
                        const Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD63FBF), fontSize: 16)),
                        const SizedBox(width: 12),
                        _PlayerSlot(name: players.length > 1 ? players[1]['name'] : null, symbol: 'O'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (playerCount < 2) ...[
                const CircularProgressIndicator(color: Color(0xFFD63FBF)),
                const SizedBox(height: 16),
                Text('En attente d\'un adversaire...', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              ] else ...[
                const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 48),
                const SizedBox(height: 12),
                const Text('Tous les joueurs sont là !', style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w600)),
                const Text('La partie commence...', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerSlot extends StatelessWidget {
  final String? name;
  final String symbol;
  const _PlayerSlot({this.name, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: name != null ? const Color(0xFFD63FBF).withOpacity(0.08) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: name != null ? const Color(0xFFD63FBF).withOpacity(0.3) : Colors.grey[200]!,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(symbol, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: name != null ? const Color(0xFFD63FBF) : Colors.grey[400])),
            const SizedBox(height: 6),
            Text(
              name ?? 'En attente...',
              style: TextStyle(fontSize: 13, fontWeight: name != null ? FontWeight.w600 : FontWeight.w400, color: name != null ? Colors.black87 : Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MORPION
// ══════════════════════════════════════════════════════════════════════════════
class MorpionPage extends StatefulWidget {
  final IO.Socket socket;
  final Map<String, dynamic> room;
  final String playerName;
  const MorpionPage({super.key, required this.socket, required this.room, required this.playerName});

  @override
  State<MorpionPage> createState() => _MorpionPageState();
}

class _MorpionPageState extends State<MorpionPage> {
  List<String?> board = List.filled(9, null);
  String? currentTurn;
  String? winner;
  late String myId;
  late String mySymbol;

  @override
  void initState() {
    super.initState();
    final state = Map<String, dynamic>.from(widget.room['state']);
    board = List<String?>.from(state['board']);
    currentTurn = state['currentTurn'];
    winner = state['winner'];

    final players = widget.room['players'] as List;
    final me = players.firstWhere((p) => p['name'] == widget.playerName);
    myId = me['id'];
    mySymbol = me['symbol'];

    widget.socket.on('morpion_update', (data) {
      if (!mounted) return;
      setState(() {
        board = List<String?>.from(data['board']);
        currentTurn = data['currentTurn'];
        winner = data['winner'];
      });
    });
  }

  void _play(int index) {
    if (board[index] != null || winner != null) return;
    if (currentTurn != myId) return;
    widget.socket.emit('morpion_play', {'roomId': widget.room['id'], 'index': index});
  }

  void _reset() {
    widget.socket.emit('morpion_reset', {'roomId': widget.room['id']});
  }

  @override
  Widget build(BuildContext context) {
    final isMyTurn = currentTurn == myId;
    final players = widget.room['players'] as List;
    final opponent = players.firstWhere((p) => p['id'] != myId, orElse: () => {'name': 'Adversaire'});

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Morpion ❌⭕', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (winner != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _reset,
              color: const Color(0xFFD63FBF),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _PlayerBadge(name: widget.playerName, symbol: mySymbol, isActive: isMyTurn && winner == null)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD63FBF))),
                ),
                Expanded(child: _PlayerBadge(name: opponent['name'], symbol: mySymbol == 'X' ? 'O' : 'X', isActive: !isMyTurn && winner == null)),
              ],
            ),
            const SizedBox(height: 20),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: winner != null
                    ? (winner == 'draw' ? Colors.orange.withOpacity(0.1) : const Color(0xFF22C55E).withOpacity(0.1))
                    : (isMyTurn ? const Color(0xFFD63FBF).withOpacity(0.1) : Colors.grey[100]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                winner != null
                    ? (winner == 'draw' ? '🤝 Match nul !' : '🎉 $winner a gagné !')
                    : (isMyTurn ? '👆 C\'est ton tour ! ($mySymbol)' : '⏳ Tour de ${opponent['name']}...'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: winner != null
                      ? (winner == 'draw' ? Colors.orange : const Color(0xFF22C55E))
                      : (isMyTurn ? const Color(0xFFD63FBF) : Colors.grey[600]),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 9,
                itemBuilder: (_, i) {
                  final cell = board[i];
                  return GestureDetector(
                    onTap: () => _play(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cell != null ? const Color(0xFFD63FBF).withOpacity(0.3) : Colors.grey[200]!,
                          width: 2,
                        ),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            cell ?? '',
                            key: ValueKey(cell ?? i),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: cell == 'X' ? const Color(0xFF6366F1) : const Color(0xFFD63FBF),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            if (winner != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Rejouer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD63FBF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayerBadge extends StatelessWidget {
  final String name;
  final String symbol;
  final bool isActive;
  const _PlayerBadge({required this.name, required this.symbol, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFD63FBF).withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isActive ? const Color(0xFFD63FBF) : Colors.grey[200]!, width: isActive ? 2 : 1),
      ),
      child: Column(
        children: [
          Text(symbol, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: symbol == 'X' ? const Color(0xFF6366F1) : const Color(0xFFD63FBF))),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          if (isActive) const Text('▶ Son tour', style: TextStyle(fontSize: 10, color: Color(0xFFD63FBF))),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ACTION OU VÉRITÉ
// ══════════════════════════════════════════════════════════════════════════════
class ActionVeritePage extends StatefulWidget {
  final IO.Socket socket;
  final Map<String, dynamic> room;
  final String playerName;
  const ActionVeritePage({super.key, required this.socket, required this.room, required this.playerName});

  @override
  State<ActionVeritePage> createState() => _ActionVeritePageState();
}

class _ActionVeritePageState extends State<ActionVeritePage> {
  Map<String, dynamic>? state;

  @override
  void initState() {
    super.initState();
    widget.socket.on('action_verite_update', (data) {
      if (mounted) setState(() => state = Map<String, dynamic>.from(data));
    });
  }

  void _draw() {
    widget.socket.emit('action_verite_draw', {'roomId': widget.room['id']});
  }

  @override
  Widget build(BuildContext context) {
    final card = state?['currentCard'];
    final players = widget.room['players'] as List;
    final currentIdx = state?['currentPlayerIndex'] ?? 0;
    final currentPlayer = players.isNotEmpty ? players[currentIdx % players.length]['name'] : '';
    final isMyTurn = currentPlayer == widget.playerName;
    final isAction = card?['type'] == 'action';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Action ou Vérité 🎭', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: players.map((p) {
                final isActive = p['name'] == currentPlayer;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFD63FBF).withOpacity(0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isActive ? const Color(0xFFD63FBF) : Colors.grey[200]!, width: isActive ? 2 : 1),
                      ),
                      child: Column(
                        children: [
                          Text(p['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                          if (isActive) const Text('▶ Son tour', style: TextStyle(fontSize: 10, color: Color(0xFFD63FBF))),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            if (card != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isAction
                        ? [const Color(0xFF6366F1), const Color(0xFF9C27B0)]
                        : [const Color(0xFFD63FBF), const Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: (isAction ? const Color(0xFF6366F1) : const Color(0xFFD63FBF)).withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(isAction ? '💪' : '🤔', style: const TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    Text(
                      isAction ? 'ACTION' : 'VÉRITÉ',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      card['text'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text('Pour : $currentPlayer', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🎴', style: TextStyle(fontSize: 60)),
                    SizedBox(height: 12),
                    Text('Appuie sur le bouton\npour tirer une carte !', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            Text(
              isMyTurn ? '🎯 C\'est ton tour !' : '⏳ Tour de $currentPlayer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isMyTurn ? const Color(0xFFD63FBF) : Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            if (isMyTurn)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _draw,
                  icon: const Text('🎴', style: TextStyle(fontSize: 18)),
                  label: const Text('Tirer une carte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD63FBF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                child: Text('Attends que $currentPlayer tire une carte...', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500])),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// QUIZ
// ══════════════════════════════════════════════════════════════════════════════
class QuizPage extends StatefulWidget {
  final IO.Socket socket;
  final Map<String, dynamic> room;
  final String playerName;
  const QuizPage({super.key, required this.socket, required this.room, required this.playerName});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  Map<String, dynamic>? state;
  String? selectedAnswer;
  bool answered = false;

  final List<Map<String, dynamic>> _questions = [
    {'question': 'Quelle vitamine est synthétisée grâce au soleil ?', 'options': ['Vitamine A', 'Vitamine B12', 'Vitamine D', 'Vitamine C'], 'correct': 'Vitamine D'},
    {'question': 'Combien d\'heures de sommeil sont recommandées pour un adulte ?', 'options': ['5-6h', '7-9h', '10-12h', '4-5h'], 'correct': '7-9h'},
    {'question': 'Quel sport est le meilleur pour renforcer le dos ?', 'options': ['Course à pied', 'Natation', 'Football', 'Tennis'], 'correct': 'Natation'},
    {'question': 'Quelle est la quantité d\'eau recommandée par jour ?', 'options': ['500ml', '1 litre', '1.5-2 litres', '3 litres'], 'correct': '1.5-2 litres'},
    {'question': 'Quel aliment est le plus riche en oméga-3 ?', 'options': ['Pain blanc', 'Saumon', 'Sucre', 'Café'], 'correct': 'Saumon'},
  ];

  @override
  void initState() {
    super.initState();
    widget.socket.on('quiz_update', (data) {
      if (mounted) {
        setState(() {
          state = Map<String, dynamic>.from(data['state']);
          answered = false;
          selectedAnswer = null;
        });
      }
    });
  }

  void _answer(String answer) {
    if (answered) return;
    setState(() { selectedAnswer = answer; answered = true; });
    widget.socket.emit('quiz_answer', {'roomId': widget.room['id'], 'answer': answer});
  }

  @override
  Widget build(BuildContext context) {
    final currentIdx = state?['currentQuestion'] ?? 0;
    final phase = state?['phase'] ?? 'question';

    if (phase == 'results') {
      final scores = Map<String, dynamic>.from(state?['scores'] ?? {});
      final players = List.from(widget.room['players'] as List);
      players.sort((a, b) => (scores[b['id']] ?? 0).compareTo(scores[a['id']] ?? 0));
      final medals = ['🥇', '🥈', '🥉'];

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 70)),
                const SizedBox(height: 16),
                const Text('Résultats finaux', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Quiz terminé !', style: TextStyle(color: Colors.grey[500])),
                const SizedBox(height: 32),
                ...players.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  final score = scores[p['id']] ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: i == 0 ? Border.all(color: const Color(0xFFEAB308), width: 2) : null,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        Text(i < 3 ? medals[i] : '${i + 1}', style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 16),
                        Expanded(child: Text(p['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        Text('$score / ${_questions.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFD63FBF))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    }

    if (currentIdx >= _questions.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFD63FBF))));
    }

    final q = _questions[currentIdx];
    final options = q['options'] as List;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Quiz Bien-être 🧠', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Question ${currentIdx + 1} / ${_questions.length}', style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (currentIdx + 1) / _questions.length,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFD63FBF), Color(0xFF9C27B0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: const Color(0xFFD63FBF).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  const Text('❓', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 12),
                  Text(q['question'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...options.map((opt) {
              final optStr = opt as String;
              Color bg = Colors.white;
              Color border = Colors.grey[200]!;
              Color textColor = Colors.black87;
              IconData? icon;

              if (answered) {
                if (optStr == q['correct']) {
                  bg = const Color(0xFF22C55E).withOpacity(0.1);
                  border = const Color(0xFF22C55E);
                  textColor = const Color(0xFF22C55E);
                  icon = Icons.check_circle_rounded;
                } else if (optStr == selectedAnswer) {
                  bg = Colors.red.withOpacity(0.1);
                  border = Colors.red;
                  textColor = Colors.red;
                  icon = Icons.cancel_rounded;
                }
              }

              return GestureDetector(
                onTap: () => _answer(optStr),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(optStr, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor))),
                      if (icon != null) Icon(icon, color: textColor, size: 20),
                    ],
                  ),
                ),
              );
            }),
            if (answered) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selectedAnswer == q['correct'] ? const Color(0xFF22C55E).withOpacity(0.08) : Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  selectedAnswer == q['correct'] ? '✅ Excellente réponse ! +1 point' : '❌ La bonne réponse était : ${q['correct']}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selectedAnswer == q['correct'] ? const Color(0xFF22C55E) : Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}