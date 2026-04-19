import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;

  // ⚠️ Pour Flutter Web → utilise POLLING en premier
  // Pour téléphone réel → remplace localhost par l'IP du PC
  static const String serverUrl = 'http://localhost:5000';

  void connect() {
    // Éviter double connexion
    if (socket != null && socket!.connected) return;

    socket = IO.io(serverUrl, IO.OptionBuilder()
      .setTransports(['polling', 'websocket']) // ✅ polling d'abord pour Flutter Web
      .disableAutoConnect()
      .enableReconnection()
      .setReconnectionAttempts(5)
      .setReconnectionDelay(1000)
      .build(),
    );

    socket!.connect();

    socket!.onConnect((_) {
      print('✅ Connecté au serveur: ${socket!.id}');
    });

    socket!.onDisconnect((_) {
      print('🔴 Déconnecté du serveur');
    });

    socket!.onConnectError((data) {
      print('❌ Erreur connexion: $data');
    });

    socket!.onError((data) {
      print('❌ Erreur socket: $data');
    });
  }

  void createRoom() {
    socket?.emit('create_room');
  }

  void joinRoom(String roomId) {
    socket?.emit('join_room', {'roomId': roomId});
  }

  void playMove(int index) {
    socket?.emit('play', {'index': index});
  }

  void restart() {
    socket?.emit('restart');
  }

  void on(String event, Function(dynamic) handler) {
    socket?.on(event, handler);
  }

  void off(String event) {
    socket?.off(event);
  }

  void disconnect() {
    socket?.disconnect();
    socket = null;
  }
}