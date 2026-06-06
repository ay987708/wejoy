import 'package:flutter/material.dart';
import 'package:wejoy/screens/service/socket_service.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SocketService _socket = SocketService();
  final TextEditingController _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  static const _bg = Color.fromARGB(255, 243, 212, 234);
  static const _card = Color.fromARGB(255, 187, 8, 148);
  static const _xCol = Color.fromARGB(255, 215, 59, 246);
  static const _oCol = Color.fromARGB(255, 238, 121, 218);

  @override
  void initState() {
    super.initState();
    _socket.connect();

    _socket.on('room_created', (data) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => GameScreen(roomId: data['roomId'], symbol: data['symbol']),
      ));
    });

    _socket.on('room_joined', (data) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => GameScreen(roomId: data['roomId'], symbol: data['symbol']),
      ));
    });

    _socket.on('error', (data) {
      if (!mounted) return;
      setState(() { _error = data['message']; _loading = false; });
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _create() { setState(() { _loading = true; _error = null; }); _socket.createRoom(); }

  void _join() {
    final id = _ctrl.text.trim().toUpperCase();
    if (id.isEmpty) { setState(() => _error = 'Entre un code de salle.'); return; }
    setState(() { _loading = true; _error = null; });
    _socket.joinRoom(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _SymTile('X', _xCol),
                const SizedBox(width: 14),
                _SymTile('O', _oCol),
              ]),
              const SizedBox(height: 28),
              const Text('Jeu XO', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              const Text('Multijoueur en temps réel', style: TextStyle(fontSize: 15, color: Colors.white38)),

              const Spacer(flex: 2),

              // Créer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _create,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _xCol, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Créer une partie', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),

              const SizedBox(height: 18),

              Row(children: [
                Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text('ou', style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13)),
                ),
                Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
              ]),

              const SizedBox(height: 18),

              // Input code
              TextField(
                controller: _ctrl,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 5, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'CODE',
                  hintStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 3, color: Colors.white.withOpacity(0.18)),
                  filled: true,
                  fillColor: _card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _oCol.withOpacity(0.5), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _loading ? null : _join,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _oCol,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    side: BorderSide(color: _oCol.withOpacity(0.45), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Rejoindre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFEA580C).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Text(_error!, style: const TextStyle(color: Color(0xFFF97316), fontSize: 13)),
                ),
              ],

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _SymTile extends StatelessWidget {
  final String sym;
  final Color color;
  const _SymTile(this.sym, this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: 64, height: 64,
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.25), width: 1.5),
    ),
    alignment: Alignment.center,
    child: Text(sym, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color)),
  );
}
