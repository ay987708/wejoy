import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;
   static String _baseUrl = 'http://10.0.2.2:5000';

  void connect() {
    if (socket != null && socket!.connected) return;
    socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['polling', 'websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build(),
    );
    socket!.connect();
    socket!.onConnect((_) => print('✅ Socket connecté: ${socket!.id}'));
    socket!.onDisconnect((_) => print('🔴 Socket déconnecté'));
    socket!.onConnectError((d) => print('❌ Erreur connexion: $d'));
    socket!.onError((d) => print('❌ Erreur socket: $d'));
  }

  // ─── XO ───────────────────────────────────────────────
  void createRoom() => socket?.emit('create_room');
  void joinRoom(String roomId) => socket?.emit('join_room', {'roomId': roomId});
  void playMove(int index) => socket?.emit('play', {'index': index});
  void restart() => socket?.emit('restart');

  // ─── LOBBY GÉNÉRIQUE ──────────────────────────────────
  void createGameRoom(String game, String playerName) =>
      socket?.emit('create_game_room', {'game': game, 'playerName': playerName});

  void joinGameRoom(String roomId, String playerName) =>
      socket?.emit('join_game_room', {'roomId': roomId, 'playerName': playerName});

  void leaveGameRoom(String roomId) =>
      socket?.emit('leave_game_room', {'roomId': roomId});

  // ─── QUIZ ─────────────────────────────────────────────
  void startQuiz(String roomId) =>
      socket?.emit('quiz_start', {'roomId': roomId});

  void answerQuiz(String roomId, String playerName, int questionIndex, int answerIndex) =>
      socket?.emit('quiz_answer', {
        'roomId': roomId,
        'playerName': playerName,
        'questionIndex': questionIndex,
        'answerIndex': answerIndex,
      });

  // ─── CE QUE JE PRÉFÈRE ───────────────────────────────
  void startWyr(String roomId) =>
      socket?.emit('wyr_start', {'roomId': roomId});

  void voteWyr(String roomId, String playerName, String choice) =>
      socket?.emit('wyr_vote', {
        'roomId': roomId,
        'playerName': playerName,
        'choice': choice,
      });

  // ─── ACTION OU VÉRITÉ ────────────────────────────────
  void startTod(String roomId) =>
      socket?.emit('tod_start', {'roomId': roomId});

  // Le joueur désigné choisit Action ou Vérité
  void chooseTod(String roomId, String mode) =>
      socket?.emit('tod_choose', {'roomId': roomId, 'mode': mode});

  // Le joueur désigné envoie sa réponse en temps réel (Vérité uniquement)
  void answerTod(String roomId, String answer) =>
      socket?.emit('tod_answer', {'roomId': roomId, 'answer': answer});

  // Le joueur désigné signale qu'il a terminé son défi → tour suivant immédiat
  void doneTod(String roomId) =>
      socket?.emit('tod_done', {'roomId': roomId});

  // ─── MEMORY ───────────────────────────────────────────
  void flipMemoryCard(String roomId, int cardIndex, String playerName) =>
      socket?.emit('memory_flip', {
        'roomId': roomId,
        'cardIndex': cardIndex,
        'playerName': playerName,
      });

  void resetMemory(String roomId) =>
      socket?.emit('memory_reset', {'roomId': roomId});

  // ─── UTILS ────────────────────────────────────────────
  void on(String event, Function(dynamic) handler) => socket?.on(event, handler);
  void off(String event) => socket?.off(event);

  void disconnect() {
    socket?.disconnect();
    socket = null;
  }

  bool get isConnected => socket?.connected ?? false;
}