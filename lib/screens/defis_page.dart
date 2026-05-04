import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:wejoy/theme/theme_provider.dart';

const String _serverUrl = 'http://localhost:5000';

// ── Couleurs statiques (non thématiques) ─────────────────────────────────
const Color _ink     = Color(0xFF111827);
const Color _bgPage  = Color(0xFFF6F7FB);
const Color _indigo  = Color(0xFF6366F1);
const Color _green   = Color(0xFF22C55E);

// ══════════════════════════════════════════════════════════════
// PAGE PRINCIPALE
// ══════════════════════════════════════════════════════════════
class DefisPage extends StatelessWidget {
  const DefisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final rose   = context.watch<ThemeProvider>().color1;
    final violet = context.watch<ThemeProvider>().color2;

    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [rose, violet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(
                    color: violet.withOpacity(0.35),
                    blurRadius: 25, offset: const Offset(0, 10),
                  )],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🎮 Jeux collaboratifs',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                    SizedBox(height: 6),
                    Text('Jouez ensemble en temps réel ✨',
                        style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [rose, rose.withOpacity(0.7)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(children: [
                  Text('💜', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 12),
                  Expanded(child: Text(
                    "Défi du jour : passe un vrai moment fun avec tes proches aujourd'hui 🌸",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, height: 1.35),
                  )),
                ]),
              ),
              const SizedBox(height: 24),

              const Text('Comment jouer ?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
                ),
                child: Column(children: [
                  _HowToStep(number: '1', text: 'Choisis un jeu et clique sur Jouer', rose: rose),
                  _HowToStep(number: '2', text: 'Entre ton prénom et crée un code de room', rose: rose),
                  _HowToStep(number: '3', text: 'Partage le code avec ton ami', rose: rose),
                  _HowToStep(number: '4', text: 'La partie commence quand vous êtes 2 !', isLast: true, rose: rose),
                ]),
              ),
              const SizedBox(height: 24),

              const Text('Jeux disponibles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),

              _GameCard(
                emoji: '❌⭕', title: 'Morpion',
                description: 'Le classique ! Alignez 3 symboles pour gagner.',
                players: '2 joueurs', difficulty: 'Facile',
                color: _indigo,
                onTap: () => _showRoomDialog(context, 'morpion', rose, violet),
              ),
              const SizedBox(height: 16),
              _GameCard(
                emoji: '🎭', title: 'Action ou Vérité',
                description: 'Tirez une carte et relevez le défi !',
                players: '2 joueurs', difficulty: 'Fun',
                color: rose,
                onTap: () => _showRoomDialog(context, 'action_verite', rose, violet),
              ),
              const SizedBox(height: 16),
              _GameCard(
                emoji: '🧠', title: 'Quiz Bien-être',
                description: 'Testez vos connaissances sur la santé !',
                players: '2 joueurs', difficulty: 'Moyen',
                color: _green,
                onTap: () => _showRoomDialog(context, 'quiz', rose, violet),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoomDialog(BuildContext context, String gameType, Color rose, Color violet) {
    final nameCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    bool isCreating = true;

    final gameNames = {
      'morpion': 'Morpion ❌⭕',
      'action_verite': 'Action ou Vérité 🎭',
      'quiz': 'Quiz Bien-être 🧠',
    };

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(children: [
            Text(gameNames[gameType] ?? 'Jeu',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Créer ou rejoindre une partie',
                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => setS(() => isCreating = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isCreating ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Text('✨ Créer',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: isCreating ? rose : Colors.grey[500]))),
                    ),
                  )),
                  Expanded(child: GestureDetector(
                    onTap: () => setS(() => isCreating = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isCreating ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Text('🔑 Rejoindre',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: !isCreating ? violet : Colors.grey[500]))),
                    ),
                  )),
                ]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: _inputDeco('Ton prénom', Icons.person_outline_rounded, rose),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roomCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDeco(
                  isCreating ? 'Crée un code (ex: ABC123)' : 'Code de la room',
                  Icons.tag_rounded, rose,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: rose.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: rose),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    isCreating
                        ? 'Inventez un code et partagez-le avec votre ami'
                        : 'Entrez le code que votre ami vous a partagé',
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  )),
                ]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCreating ? rose : violet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || roomCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Remplis tous les champs !'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => GameLobbyPage(
                    roomId: roomCtrl.text.trim().toUpperCase(),
                    playerName: nameCtrl.text.trim(),
                    gameType: gameType,
                  ),
                ));
              },
              child: Text(isCreating ? 'Créer' : 'Rejoindre',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon, Color rose) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
    prefixIcon: Icon(icon, size: 18, color: Colors.grey[400]),
    filled: true, fillColor: Colors.grey[50],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: rose, width: 1.5),
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// LOBBY
// ══════════════════════════════════════════════════════════════
class GameLobbyPage extends StatefulWidget {
  final String roomId, playerName, gameType;
  const GameLobbyPage({super.key, required this.roomId, required this.playerName, required this.gameType});

  @override
  State<GameLobbyPage> createState() => _GameLobbyPageState();
}

class _GameLobbyPageState extends State<GameLobbyPage> with SingleTickerProviderStateMixin {
  // ── Accesseurs thème dynamique ─────────────────────────────────────────
  Color get _rose   => context.read<ThemeProvider>().color1;
  Color get _violet => context.read<ThemeProvider>().color2;

  late IO.Socket socket;
  Map<String, dynamic>? room;
  String? errorMessage;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.02).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _connect();
  }

  void _connect() {
    socket = IO.io(_serverUrl, IO.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .disableAutoConnect()
        .enableReconnection()
        .build());

    socket.connect();

    socket.onConnect((_) {
      socket.emit('join_room', {
        'roomId':     widget.roomId,
        'playerName': widget.playerName,
        'gameType':   widget.gameType,
      });
    });

    socket.on('room_update', (data) {
      if (mounted) setState(() {
        room = Map<String, dynamic>.from(data);
        errorMessage = null;
      });
    });

    socket.on('room_full', (data) {
      if (mounted) setState(() => errorMessage = data['message']);
    });

    socket.on('game_start', (data) {
      if (!mounted) return;
      final r = Map<String, dynamic>.from(data);
      setState(() => room = r);
      _navigateToGame(r);
    });

    socket.on('player_left', (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Un joueur a quitté la partie 😢'),
          backgroundColor: Colors.orange,
        ));
        setState(() => room = null);
      }
    });

    socket.onConnectError((_) {
      if (mounted) setState(() => errorMessage = 'Impossible de se connecter au serveur');
    });
  }

  void _navigateToGame(Map<String, dynamic> r) {
    Widget page;
    switch (widget.gameType) {
      case 'morpion':
        page = MorpionPage(socket: socket, room: r, playerName: widget.playerName);
        break;
      case 'action_verite':
        page = ActionVeritePage(socket: socket, room: r, playerName: widget.playerName);
        break;
      default:
        page = QuizPage(socket: socket, room: r, playerName: widget.playerName);
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  void dispose() { _pulseCtrl.dispose(); socket.disconnect(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final rose   = context.watch<ThemeProvider>().color1;
    final violet = context.watch<ThemeProvider>().color2;

    final players = (room?['players'] as List?) ?? [];
    final bool ready = players.length >= 2;

    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        title: const Text('Salle d\'attente', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white, foregroundColor: _ink, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () { socket.disconnect(); Navigator.pop(context); },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [rose, violet],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_gameTitle(), style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 6),
                const Text('Invitez votre ami et préparez-vous à jouer ✨',
                    style: TextStyle(fontSize: 13, color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 22),

            if (errorMessage != null)
              Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.red[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red[200]!)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13))),
                ]),
              ),

            Container(
              width: double.infinity, padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 18)]),
              child: Column(children: [
                Text('Code de la room', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) => Transform.scale(
                      scale: ready ? 1 : _pulseAnim.value, child: child),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [rose.withOpacity(0.08), violet.withOpacity(0.08)]),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: rose.withOpacity(0.20)),
                    ),
                    child: Text(widget.roomId,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900,
                            color: rose, letterSpacing: 5)),
                  ),
                ),
                const SizedBox(height: 10),
                Text('Partage ce code avec ton ami',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ]),
            ),
            const SizedBox(height: 18),

            Container(
              width: double.infinity, padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 18)]),
              child: Column(children: [
                Row(children: [
                  const Text('Joueurs connectés',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                        color: rose.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('${players.length} / 2',
                        style: TextStyle(color: rose, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ]),
                const SizedBox(height: 18),
                Row(children: [
                  _PlayerSlot(
                    name: players.isNotEmpty ? players[0]['name'] : null,
                    symbol: 'X', isReady: players.isNotEmpty,
                    isMe: players.isNotEmpty ? players[0]['name'] == widget.playerName : false,
                    rose: rose,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('VS', style: TextStyle(
                        fontWeight: FontWeight.w900, color: rose, fontSize: 18)),
                  ),
                  _PlayerSlot(
                    name: players.length > 1 ? players[1]['name'] : null,
                    symbol: 'O', isReady: players.length > 1,
                    isMe: players.length > 1 ? players[1]['name'] == widget.playerName : false,
                    rose: rose,
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 22),

            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ready
                    ? _green.withOpacity(0.08)
                    : rose.withOpacity(0.08),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: ready ? _green.withOpacity(0.25) : rose.withOpacity(0.15),
                ),
              ),
              child: Column(children: [
                if (!ready) ...[
                  SizedBox(width: 28, height: 28,
                      child: CircularProgressIndicator(strokeWidth: 3, color: rose)),
                  const SizedBox(height: 14),
                  Text('En attente d\'un adversaire...',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: rose)),
                  const SizedBox(height: 6),
                  Text('La partie démarre dès que 2 joueurs sont présents.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12.5)),
                ] else ...[
                  const Icon(Icons.check_circle_rounded, color: _green, size: 48),
                  const SizedBox(height: 12),
                  const Text('Tous les joueurs sont là !',
                      style: TextStyle(color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w800, fontSize: 17)),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _gameTitle() {
    switch (widget.gameType) {
      case 'morpion':       return 'Morpion ❌⭕';
      case 'action_verite': return 'Action ou Vérité 🎭';
      case 'quiz':          return 'Quiz Bien-être 🧠';
      default:              return 'Jeu';
    }
  }
}

// ══════════════════════════════════════════════════════════════
// MORPION
// ══════════════════════════════════════════════════════════════
class MorpionPage extends StatefulWidget {
  final IO.Socket socket;
  final Map<String, dynamic> room;
  final String playerName;
  const MorpionPage({super.key, required this.socket,
    required this.room, required this.playerName});

  @override
  State<MorpionPage> createState() => _MorpionPageState();
}

class _MorpionPageState extends State<MorpionPage>
    with SingleTickerProviderStateMixin {
  // ── Accesseurs thème dynamique ─────────────────────────────────────────
  Color get _rose   => context.read<ThemeProvider>().color1;
  Color get _violet => context.read<ThemeProvider>().color2;

  List<String?> board = List.filled(9, null);
  String? currentTurnName;
  String? winner;
  late String mySymbol;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    final state   = Map<String, dynamic>.from(widget.room['state'] ?? {});
    board         = List<String?>.from(state['board'] ?? List.filled(9, null));
    winner        = state['winner'];

    final players = widget.room['players'] as List;
    final me      = players.firstWhere(
          (p) => p['name'] == widget.playerName,
      orElse: () => players[0],
    );
    mySymbol = me['symbol'];
    currentTurnName = state['currentTurn'] ?? (players.isNotEmpty ? players[0]['name'] : '');

    widget.socket.on('morpion_update', (data) {
      if (!mounted) return;
      setState(() {
        board           = List<String?>.from(data['board']);
        currentTurnName = data['currentTurn']?.toString() ?? currentTurnName;
        winner          = data['winner'];
      });
    });
  }

  bool get _isMyTurn => currentTurnName == widget.playerName;

  void _play(int index) {
    if (board[index] != null || winner != null) return;
    if (!_isMyTurn) return;
    widget.socket.emit('morpion_play', {
      'roomId':     widget.room['id'],
      'index':      index,
      'playerName': widget.playerName,
    });
  }

  void _reset() =>
      widget.socket.emit('morpion_reset', {'roomId': widget.room['id']});

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final rose   = context.watch<ThemeProvider>().color1;
    final violet = context.watch<ThemeProvider>().color2;

    final players = widget.room['players'] as List;
    final opponent = players.firstWhere(
          (p) => p['name'] != widget.playerName,
      orElse: () => {'name': 'Adversaire'},
    );

    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        title: const Text('Morpion ❌⭕', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white, foregroundColor: _ink, elevation: 0,
        actions: [
          if (winner != null)
            IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _reset,
                color: rose),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Row(children: [
            Expanded(child: _PlayerBadge(
                name: widget.playerName, symbol: mySymbol,
                isActive: _isMyTurn && winner == null, isMe: true, rose: rose)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('VS', style: TextStyle(
                  fontWeight: FontWeight.w900, color: rose, fontSize: 18)),
            ),
            Expanded(child: _PlayerBadge(
                name: opponent['name'],
                symbol: mySymbol == 'X' ? 'O' : 'X',
                isActive: !_isMyTurn && winner == null, isMe: false, rose: rose)),
          ]),
          const SizedBox(height: 20),

          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: winner != null
                  ? (winner == 'draw'
                  ? Colors.orange.withOpacity(0.10)
                  : _green.withOpacity(0.10))
                  : (_isMyTurn ? rose.withOpacity(0.10) : Colors.grey[100]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              winner != null
                  ? (winner == 'draw' ? '🤝 Match nul !' : '🎉 $winner a gagné !')
                  : (_isMyTurn ? '👆 C\'est ton tour ! ($mySymbol)' : '⏳ Tour de ${opponent['name']}...'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: winner != null
                    ? (winner == 'draw' ? Colors.orange : const Color(0xFF16A34A))
                    : (_isMyTurn ? rose : Colors.grey[700]),
              ),
            ),
          ),
          const SizedBox(height: 24),

          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(
                scale: (_isMyTurn && winner == null) ? _pulseAnim.value : 1, child: child),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20)],
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemCount: 9,
                  itemBuilder: (_, i) {
                    final cell    = board[i];
                    final canPlay = cell == null && winner == null && _isMyTurn;
                    return GestureDetector(
                      onTap: () => _play(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        decoration: BoxDecoration(
                          color: cell == null ? Colors.grey[50] : null,
                          gradient: cell != null
                              ? LinearGradient(colors: cell == 'X'
                              ? [_indigo.withOpacity(0.10), _indigo.withOpacity(0.04)]
                              : [rose.withOpacity(0.10), rose.withOpacity(0.04)])
                              : null,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: cell != null
                                ? (cell == 'X'
                                ? _indigo.withOpacity(0.30)
                                : rose.withOpacity(0.30))
                                : (canPlay ? rose.withOpacity(0.40) : Colors.grey[200]!),
                            width: canPlay ? 2 : 1.8,
                          ),
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(scale: anim,
                                    child: FadeTransition(opacity: anim, child: child)),
                            child: Text(cell ?? '',
                                key: ValueKey(cell ?? 'empty_$i'),
                                style: TextStyle(
                                    fontSize: 42, fontWeight: FontWeight.w900,
                                    color: cell == 'X' ? _indigo : rose)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (winner != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Rejouer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: rose, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ACTION OU VÉRITÉ
// ══════════════════════════════════════════════════════════════
class ActionVeritePage extends StatefulWidget {
  final IO.Socket socket;
  final Map<String, dynamic> room;
  final String playerName;
  const ActionVeritePage({super.key, required this.socket,
    required this.room, required this.playerName});

  @override
  State<ActionVeritePage> createState() => _ActionVeritePageState();
}

class _ActionVeritePageState extends State<ActionVeritePage> {
  // ── Accesseurs thème dynamique ─────────────────────────────────────────
  Color get _rose   => context.read<ThemeProvider>().color1;
  Color get _violet => context.read<ThemeProvider>().color2;

  Map<String, dynamic>? gameState;
  Map<String, dynamic>? currentRoom;

  @override
  void initState() {
    super.initState();
    currentRoom = widget.room;

    widget.socket.on('action_verite_update', (data) {
      if (mounted) setState(() {
        gameState   = Map<String, dynamic>.from(data['state']);
        if (data['room'] != null)
          currentRoom = Map<String, dynamic>.from(data['room']);
      });
    });
  }

  void _draw() {
    widget.socket.emit('action_verite_draw', {
      'roomId':     widget.room['id'],
      'playerName': widget.playerName,
    });
  }

  @override
  Widget build(BuildContext context) {
    final rose   = context.watch<ThemeProvider>().color1;
    final violet = context.watch<ThemeProvider>().color2;

    final players    = (currentRoom?['players'] as List?) ?? [];
    final currentIdx = gameState?['currentPlayerIndex'] ?? 0;
    final currentPlayer = (gameState == null || players.isEmpty)
        ? ''
        : players[currentIdx % players.length]['name'] as String;

    final isMyTurn = currentPlayer.isNotEmpty && currentPlayer == widget.playerName;
    final card     = gameState?['currentCard'];
    final isAction = card?['type'] == 'action';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Action ou Vérité 🎭',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Row(children: players.map((p) {
            final isActive = p['name'] == currentPlayer && currentPlayer.isNotEmpty;
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive ? rose.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive ? rose : Colors.grey[200]!, width: isActive ? 2 : 1),
                ),
                child: Column(children: [
                  Text(p['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  if (isActive)
                    Text('▶ Son tour', style: TextStyle(fontSize: 10, color: rose)),
                ]),
              ),
            ));
          }).toList()),
          const SizedBox(height: 32),

          if (card != null)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isAction ? [_indigo, violet] : [rose, rose.withOpacity(0.7)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(
                  color: (isAction ? _indigo : rose).withOpacity(0.4),
                  blurRadius: 24, offset: const Offset(0, 10),
                )],
              ),
              child: Column(children: [
                Text(isAction ? '💪' : '🤔', style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text(isAction ? 'ACTION' : 'VÉRITÉ',
                    style: const TextStyle(color: Colors.white70,
                        fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 3)),
                const SizedBox(height: 16),
                Text(card['text'], textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 18, fontWeight: FontWeight.w700, height: 1.5)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    currentPlayer.isNotEmpty ? 'Pour : $currentPlayer' : '',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            )
          else
            Container(
              width: double.infinity, height: 240,
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('🎴', style: TextStyle(fontSize: 60)),
                SizedBox(height: 12),
                Text('Appuie sur le bouton\npour tirer une carte !',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
              ]),
            ),

          const SizedBox(height: 32),

          if (currentPlayer.isEmpty)
            Text('En attente du premier tirage...',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]))
          else
            Text(isMyTurn ? '🎯 C\'est ton tour !' : '⏳ Tour de $currentPlayer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    color: isMyTurn ? rose : Colors.grey[600])),

          const SizedBox(height: 20),

          if (isMyTurn)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _draw,
                icon: const Text('🎴', style: TextStyle(fontSize: 18)),
                label: const Text('Tirer une carte',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: rose, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            )
          else
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
              child: Text(
                currentPlayer.isNotEmpty
                    ? 'Attends que $currentPlayer tire une carte...'
                    : 'En attente...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// QUIZ
// ══════════════════════════════════════════════════════════════
class QuizPage extends StatefulWidget {
  final IO.Socket socket;
  final Map<String, dynamic> room;
  final String playerName;
  const QuizPage({super.key, required this.socket,
    required this.room, required this.playerName});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage>
    with SingleTickerProviderStateMixin {
  // ── Accesseurs thème dynamique ─────────────────────────────────────────
  Color get _rose   => context.read<ThemeProvider>().color1;
  Color get _violet => context.read<ThemeProvider>().color2;

  Map<String, dynamic>? state;
  Map<String, dynamic>? currentQuestion;
  List<dynamic> players = [];
  String? selectedAnswer;
  bool answered = false;
  bool waiting  = false;
  String? endWinner;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  final List<Map<String, dynamic>> _questions = [
    {'question': 'Quelle vitamine est synthétisée grâce au soleil ?',
      'options': ['Vitamine A', 'Vitamine B12', 'Vitamine D', 'Vitamine C'],
      'correct': 'Vitamine D'},
    {'question': "Combien d'heures de sommeil sont recommandées ?",
      'options': ['5-6h', '7-9h', '10-12h', '4-5h'],
      'correct': '7-9h'},
    {'question': 'Quel sport renforce le plus le dos ?',
      'options': ['Course', 'Natation', 'Football', 'Tennis'],
      'correct': 'Natation'},
    {'question': "Combien de litres d'eau boire par jour ?",
      'options': ['1L', '1.5L', '2L', '3L'],
      'correct': '2L'},
    {'question': 'Quel aliment est riche en oméga-3 ?',
      'options': ['Poulet', 'Saumon', 'Pain', 'Riz'],
      'correct': 'Saumon'},
  ];

  @override
  void initState() {
    super.initState();
    players         = List.from(widget.room['players'] ?? []);
    currentQuestion = _questions[0];

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();

    widget.socket.on('quiz_update', (data) {
      if (mounted) setState(() {
        state           = Map<String, dynamic>.from(data['state']);
        currentQuestion = Map<String, dynamic>.from(data['question']);
        players         = List.from(data['players'] ?? players);
        answered        = false;
        selectedAnswer  = null;
        waiting         = false;
      });
      _animCtrl.forward(from: 0);
    });

    widget.socket.on('quiz_waiting', (_) {
      if (mounted) setState(() => waiting = true);
    });

    widget.socket.on('quiz_end', (data) {
      if (mounted) setState(() {
        endWinner = data['winner'];
        players   = List.from(data['players'] ?? players);
      });
    });
  }

  void _answer(String answer) {
    if (answered) return;
    setState(() { selectedAnswer = answer; answered = true; waiting = false; });
    widget.socket.emit('quiz_answer', {
      'roomId':     widget.room['id'],
      'answer':     answer,
      'playerName': widget.playerName,
    });
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final rose   = context.watch<ThemeProvider>().color1;
    final violet = context.watch<ThemeProvider>().color2;

    if (endWinner != null) {
      return Scaffold(
        backgroundColor: _bgPage,
        body: Center(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🏆', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            Text('$endWinner a gagné !',
                style: const TextStyle(fontSize: 26,
                    fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 24),
            ...players.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(p['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: _green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('${p['score']} pts',
                      style: const TextStyle(color: _green, fontWeight: FontWeight.w700)),
                ),
              ]),
            )),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: rose, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Retour aux jeux', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ]),
        )),
      );
    }

    if (currentQuestion == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q          = currentQuestion!;
    final options    = q['options'] as List;
    final currentIdx = state?['currentQuestion'] ?? 0;

    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        title: const Text('Quiz Bien-être 🧠'),
        backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Row(children: players.map((p) => Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!)),
                child: Column(children: [
                  Text(p['name'],
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${p['score'] ?? 0} pts',
                      style: const TextStyle(fontSize: 16,
                          fontWeight: FontWeight.w800, color: _green)),
                ]),
              ),
            ))).toList()),
            const SizedBox(height: 16),

            LinearProgressIndicator(
              value: (currentIdx + 1) / _questions.length,
              color: _green, backgroundColor: Colors.grey[200], minHeight: 6,
            ),
            const SizedBox(height: 6),
            Text('Question ${currentIdx + 1} / ${_questions.length}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 16),

            Container(
              width: double.infinity, padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [rose, violet]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(children: [
                const Text('❓', style: TextStyle(fontSize: 30)),
                const SizedBox(height: 10),
                Text(q['question'], textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 24),

            ...options.map((opt) {
              final isCorrect  = opt == q['correct'];
              final isSelected = opt == selectedAnswer;
              Color bg        = Colors.white;
              Color border    = Colors.grey[200]!;
              Color textColor = Colors.black;

              if (answered) {
                if (isCorrect) {
                  bg        = _green.withOpacity(0.1);
                  border    = _green;
                  textColor = _green;
                } else if (isSelected) {
                  bg        = Colors.red.withOpacity(0.1);
                  border    = Colors.red;
                  textColor = Colors.red;
                }
              }

              return GestureDetector(
                onTap: () => _answer(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: border, width: 2)),
                  child: Row(children: [
                    Expanded(child: Text(opt,
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w600, color: textColor))),
                    if (answered && isCorrect) const Icon(Icons.check, color: _green),
                    if (answered && isSelected && !isCorrect) const Icon(Icons.close, color: Colors.red),
                  ]),
                ),
              );
            }),

            if (answered && waiting)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
                  SizedBox(width: 12),
                  Text('En attente de l\'autre joueur...',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                ]),
              ),

            if (answered && !waiting)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selectedAnswer == q['correct']
                      ? _green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  selectedAnswer == q['correct'] ? '✅ Bonne réponse !' : '❌ Mauvaise réponse',
                  style: TextStyle(
                    color: selectedAnswer == q['correct'] ? _green : Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS UTILITAIRES
// ══════════════════════════════════════════════════════════════
class _HowToStep extends StatelessWidget {
  final String number, text;
  final bool isLast;
  final Color rose;
  const _HowToStep({required this.number, required this.text,
    this.isLast = false, required this.rose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(children: [
        Container(width: 30, height: 30,
            decoration: BoxDecoration(
                color: rose.withOpacity(0.1), shape: BoxShape.circle),
            child: Center(child: Text(number,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: rose)))),
        const SizedBox(width: 12),
        Expanded(child: Text(text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.3))),
      ]),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String emoji, title, description, players, difficulty;
  final Color color;
  final VoidCallback onTap;
  const _GameCard({required this.emoji, required this.title,
    required this.description, required this.players,
    required this.difficulty, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color.withOpacity(0.08), Colors.white],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(children: [
          Container(width: 64, height: 64,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(18)),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 30)))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(children: [
              _Tag(text: players, color: color),
              const SizedBox(width: 6),
              _Tag(text: difficulty, color: Colors.grey[600]!),
            ]),
          ])),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(14)),
            child: const Text('Jouer',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(
        fontSize: 10, color: color, fontWeight: FontWeight.w700)),
  );
}

class _PlayerSlot extends StatelessWidget {
  final String? name;
  final String symbol;
  final bool isReady, isMe;
  final Color rose;
  const _PlayerSlot({this.name, required this.symbol,
    required this.isReady, required this.isMe, required this.rose});

  @override
  Widget build(BuildContext context) {
    final color = symbol == 'X' ? _indigo : rose;
    return Expanded(child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReady ? null : Colors.grey[50],
        gradient: isReady ? LinearGradient(
            colors: [color.withOpacity(0.10), Colors.white],
            begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isReady ? color.withOpacity(0.28) : Colors.grey[200]!,
            width: 1.5),
      ),
      child: Column(children: [
        Container(width: 46, height: 46,
            decoration: BoxDecoration(
                color: isReady ? color.withOpacity(0.12) : Colors.grey[200],
                shape: BoxShape.circle),
            child: Center(child: Text(symbol,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                    color: isReady ? color : Colors.grey[400])))),
        const SizedBox(height: 10),
        Text(name ?? 'En attente...', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13,
                fontWeight: name != null ? FontWeight.w700 : FontWeight.w500,
                color: name != null ? _ink : Colors.grey[400])),
        const SizedBox(height: 6),
        if (isMe && name != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: rose.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
            child: Text('Toi', style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: rose)),
          )
        else
          Text(name != null ? 'Prêt' : 'Libre',
              style: TextStyle(fontSize: 10.5,
                  color: name != null ? color : Colors.grey[400],
                  fontWeight: FontWeight.w600)),
      ]),
    ));
  }
}

class _PlayerBadge extends StatelessWidget {
  final String name, symbol;
  final bool isActive, isMe;
  final Color rose;
  const _PlayerBadge({required this.name, required this.symbol,
    required this.isActive, required this.isMe, required this.rose});

  @override
  Widget build(BuildContext context) {
    final color = symbol == 'X' ? _indigo : rose;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive ? null : Colors.white,
        gradient: isActive ? LinearGradient(
            colors: [color.withOpacity(0.12), Colors.white],
            begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isActive ? color : Colors.grey[200]!,
            width: isActive ? 2 : 1.3),
      ),
      child: Column(children: [
        Container(width: 46, height: 46,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Center(child: Text(symbol,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)))),
        const SizedBox(height: 10),
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 6),
        if (isMe)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: rose.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
            child: Text('Toi', style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: rose)),
          )
        else
          Text(isActive ? 'Son tour' : 'En jeu',
              style: TextStyle(fontSize: 10.5,
                  color: isActive ? color : Colors.grey[500],
                  fontWeight: FontWeight.w600)),
      ]),
    );
  }
}