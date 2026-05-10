import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wejoy/screens/login_page.dart';

// ── Particle model ──────────────────────────────────────────────────────────
class _Particle {
  double x, y, radius, opacity, speed, angle;
  _Particle({required this.x, required this.y, required this.radius,
    required this.opacity, required this.speed, required this.angle});
}

// ── Particle painter ─────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.radius,
        Paint()..color = Colors.white.withOpacity(p.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ── SplashScreen ─────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _logoController;
  late AnimationController _glowController;
  late AnimationController _gradientController;
  late AnimationController _textController;
  late AnimationController _subtitleController;
  late AnimationController _particleController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _glowRadius;
  late Animation<double> _glowOpacity;
  late Animation<double> _gradientShift;
  late Animation<double> _subtitleFade;

  final String _title = "WEJOY";
  final List<Animation<double>> _letterFades = [];
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _buildParticles();

    // 1. Gradient background slow shift
    _gradientController = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _gradientShift =
        Tween<double>(begin: 0.0, end: 1.0).animate(_gradientController);

    // 2. Logo zoom + fade
    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    // 3. Glow pulse
    _glowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _glowRadius = Tween<double>(begin: 20, end: 50).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _glowOpacity = Tween<double>(begin: 0.25, end: 0.6).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    // 4. Letters W-E-J-O-Y one by one
    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    for (int i = 0; i < _title.length; i++) {
      _letterFades.add(Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _textController,
          curve: Interval(
              i / _title.length, (i + 1) / _title.length,
              curve: Curves.easeOut),
        ),
      ));
    }

    // 5. Subtitle fade
    _subtitleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _subtitleController, curve: Curves.easeIn));

    // 6. Particles
    _particleController = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _particleController.addListener(_updateParticles);

    // ── Sequence ──────────────────────────────────────────────────
    _logoController.forward();

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) _subtitleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginPage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 700),
        ));
      }
    });
  }

  void _buildParticles() {
    final rng = Random();
    for (int i = 0; i < 28; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(), y: rng.nextDouble(),
        radius: rng.nextDouble() * 3 + 1,
        opacity: rng.nextDouble() * 0.5 + 0.15,
        speed: rng.nextDouble() * 0.0015 + 0.0005,
        angle: rng.nextDouble() * 2 * pi,
      ));
    }
  }

  void _updateParticles() {
    setState(() {
      for (final p in _particles) {
        p.y -= p.speed;
        p.x += sin(p.angle) * 0.0005;
        if (p.y < -0.05) p.y = 1.05;
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    _gradientController.dispose();
    _textController.dispose();
    _subtitleController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientShift,
        builder: (context, child) {
          final t = _gradientShift.value;
          final topColor =
              Color.lerp(const Color(0xFFE040FB), const Color(0xFF9C27B0), t)!;
          final bottomColor =
              Color.lerp(const Color(0xFFAD1457), const Color(0xFF6A1B9A), t)!;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [topColor, const Color(0xFFCE93D8), bottomColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            // Floating particles
            CustomPaint(
                painter: _ParticlePainter(_particles), size: Size.infinite),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo: glow + zoom + fade
                  AnimatedBuilder(
                    animation:
                        Listenable.merge([_logoController, _glowController]),
                    builder: (_, __) => FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulsing glow behind logo
                            Container(
                              width: 110 + _glowRadius.value,
                              height: 110 + _glowRadius.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white
                                        .withOpacity(_glowOpacity.value),
                                    blurRadius: _glowRadius.value * 2,
                                    spreadRadius: _glowRadius.value * 0.5,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFE040FB).withOpacity(
                                        _glowOpacity.value * 0.7),
                                    blurRadius: _glowRadius.value * 3,
                                    spreadRadius: _glowRadius.value,
                                  ),
                                ],
                              ),
                            ),
                            // Your logo
                            ClipOval(
                              child: Image.asset(
                                'assets/images/logowejoy.png',
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // W E J O Y letter by letter
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_title.length, (i) {
                      return AnimatedBuilder(
                        animation: _letterFades[i],
                        builder: (_, __) => Opacity(
                          opacity: _letterFades[i].value,
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1 - _letterFades[i].value)),
                            child: Text(
                              _title[i],
                              style: const TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 4,
                                shadows: [
                                  Shadow(
                                    color: Color(0x88000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 14),

                  // Subtitle
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: const Text(
                      "Ensemble contre l'isolement",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}