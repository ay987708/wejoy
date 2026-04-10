import 'package:flutter/material.dart';
import 'package:wejoy/screens/service/api_service.dart';

class WelcomeCard extends StatefulWidget {
  final UserProfile? user;
  final bool loading;
  const WelcomeCard({super.key, this.user, required this.loading});

  @override
  State<WelcomeCard> createState() => _WelcomeCardState();
}

class _WelcomeCardState extends State<WelcomeCard>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;

  late final AnimationController _sparkCtrl;
  late final Animation<double> _sparkAnim;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _sparkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _sparkAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _sparkCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _sparkCtrl.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.loading ? '...' : (widget.user?.username ?? 'toi');
    final firstName = name.split(' ').first;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF6F1), Color(0xFFFFF0FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE84C88).withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Texte ──────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE84C88).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.auto_awesome_rounded,
                          size: 12, color: Color(0xFFE84C88)),
                      SizedBox(width: 5),
                      Text(
                        'Bienvenue sur WeJoy',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE84C88),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${_greeting()}, $firstName ! 🌸',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1A24),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Prends soin de toi aujourd\'hui.\nTon compagnon est là pour toi 💜',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6E6A78),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _chip(
                      Icons.local_fire_department_rounded,
                      '${widget.user?.points ?? 0} pts',
                      const Color(0xFFFF6B35),
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      Icons.favorite_rounded,
                      'Bien-être',
                      const Color(0xFF7C4DFF),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Logo animé ─────────────────────────────────────
          SizedBox(
            width: 110,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ombre douce en bas
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: 70,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE84C88).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
                // Sparkle haut droite
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedBuilder(
                    animation: _sparkAnim,
                    builder: (_, __) => Opacity(
                      opacity: _sparkAnim.value,
                      child: const Icon(Icons.auto_awesome,
                          size: 14, color: Color(0xFFFFD93D)),
                    ),
                  ),
                ),
                // Sparkle gauche
                Positioned(
                  top: 30,
                  left: 2,
                  child: AnimatedBuilder(
                    animation: _sparkAnim,
                    builder: (_, __) => Opacity(
                      opacity: 1 - _sparkAnim.value + 0.3,
                      child: const Icon(Icons.star_rounded,
                          size: 10, color: Color(0xFF7C4DFF)),
                    ),
                  ),
                ),
                // Logo flottant
                AnimatedBuilder(
                  animation: _floatAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _floatAnim.value),
                    child: child,
                  ),
                  child: Image.asset(
                    'assets/images/joya.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}