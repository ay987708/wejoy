import 'package:flutter/material.dart';

enum Mood { excellent, bien, neutre, triste, besoinSoutien }

enum MoodFaceType {
  excellent,
  bien,
  neutre,
  triste,
  besoinSoutien,
}

class MoodSelector extends StatelessWidget {
  final Mood? selectedMood;
  final ValueChanged<Mood> onMoodSelected;

  const MoodSelector({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  static const List<Map<String, dynamic>> moods = [
    {
      'label': 'Mal',
      'color': Color(0xFFFF5B6E),
      'lightColor': Color(0xFFFFE3E7),
      'mood': Mood.besoinSoutien,
      'face': MoodFaceType.besoinSoutien,
      'quote': "Tu as le droit de ralentir et de prendre soin de toi.",
      'subtitle': "Chaque émotion mérite d’être accueillie avec douceur.",
      'icon': Icons.favorite_rounded,
    },
    {
      'label': 'Pas bien',
      'color': Color(0xFF8C7BFF),
      'lightColor': Color(0xFFE9E5FF),
      'mood': Mood.triste,
      'face': MoodFaceType.triste,
      'quote': "Respire doucement, demain peut être plus léger.",
      'subtitle': "Les jours lourds passent, un pas à la fois.",
      'icon': Icons.auto_awesome_rounded,
    },
    {
      'label': 'Pas mal',
      'color': Color(0xFF44B8FF),
      'lightColor': Color(0xFFE2F5FF),
      'mood': Mood.neutre,
      'face': MoodFaceType.neutre,
      'quote': "Même les petits élans comptent.",
      'subtitle': "Tu avances peut-être plus que tu ne le crois.",
      'icon': Icons.wb_twilight_rounded,
    },
    {
      'label': 'Bien',
      'color': Color(0xFF79C94B),
      'lightColor': Color(0xFFEAF8E0),
      'mood': Mood.bien,
      'face': MoodFaceType.bien,
      'quote': "Tu avances mieux que tu ne le penses.",
      'subtitle': "Continue avec confiance, tu es sur une belle lancée.",
      'icon': Icons.eco_rounded,
    },
    {
      'label': 'Très bien',
      'color': Color(0xFFFFD93D),
      'lightColor': Color(0xFFFFF6CC),
      'mood': Mood.excellent,
      'face': MoodFaceType.excellent,
      'quote': "Je mérite une vie incroyable.",
      'subtitle': "Savoure cette énergie et laisse-la illuminer ta journée.",
      'icon': Icons.wb_sunny_rounded,
    },
  ];

  Map<String, dynamic>? get selectedMoodData {
    if (selectedMood == null) return null;
    try {
      return moods.firstWhere((m) => m['mood'] == selectedMood);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedData = selectedMoodData;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            transitionBuilder: (child, animation) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.08),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
            child: selectedData != null
                ? PremiumQuoteCard(
                    key: ValueKey(selectedData['mood']),
                    title: "Pensée du moment",
                    quote: selectedData['quote'] as String,
                    subtitle: selectedData['subtitle'] as String,
                    color: selectedData['color'] as Color,
                    lightColor: selectedData['lightColor'] as Color,
                    icon: selectedData['icon'] as IconData,
                  )
                : const SizedBox.shrink(),
          ),
          if (selectedData != null) const SizedBox(height: 22),
          const Text(
            "Prends un instant : comment te sens-tu ?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF222222),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Choisis l’émotion qui te correspond le mieux aujourd’hui.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: moods.map((m) {
              final mood = m['mood'] as Mood;
              final isSelected = selectedMood == mood;
              final color = m['color'] as Color;
              final lightColor = m['lightColor'] as Color;
              final face = m['face'] as MoodFaceType;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onMoodSelected(mood),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? lightColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              "Choisi",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: color,
                                letterSpacing: 0.2,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 18),
                        AnimatedScale(
                          scale: isSelected ? 1.18 : 1.0,
                          duration: const Duration(milliseconds: 220),
                          child: MoodFace(
                            color: color,
                            type: face,
                            size: isSelected ? 60 : 50,
                            selected: isSelected,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          m['label'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? color : const Color(0xFF222222),
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class PremiumQuoteCard extends StatelessWidget {
  final String title;
  final String quote;
  final String subtitle;
  final Color color;
  final Color lightColor;
  final IconData icon;

  const PremiumQuoteCard({
    super.key,
    required this.title,
    required this.quote,
    required this.subtitle,
    required this.color,
    required this.lightColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            lightColor,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            quote,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: Color(0xFF222222),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class MoodFace extends StatelessWidget {
  final Color color;
  final MoodFaceType type;
  final double size;
  final bool selected;

  const MoodFace({
    super.key,
    required this.color,
    required this.type,
    required this.size,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.28, -0.35),
          radius: 1.0,
          colors: [
            Colors.white.withOpacity(0.40),
            color,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(selected ? 0.42 : 0.28),
            blurRadius: selected ? 20 : 10,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.16,
            left: size * 0.18,
            child: Container(
              width: size * 0.24,
              height: size * 0.12,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          if (type == MoodFaceType.excellent)
            Positioned(
              top: size * 0.10,
              child: Text(
                '✨',
                style: TextStyle(fontSize: size * 0.15),
              ),
            ),
          if (type == MoodFaceType.neutre)
            Positioned(
              top: size * 0.12,
              child: Text(
                '...',
                style: TextStyle(
                  fontSize: size * 0.11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black26,
                ),
              ),
            ),
          CustomPaint(
            size: Size(size, size),
            painter: MoodFacePainter(type: type),
          ),
        ],
      ),
    );
  }
}

class MoodFacePainter extends CustomPainter {
  final MoodFaceType type;

  MoodFacePainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFF1D1D1D)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0xFF1D1D1D)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.6;

    final blushPaint = Paint()
      ..color = const Color(0xFFFF9AAE).withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final leftEye = Offset(size.width * 0.35, size.height * 0.43);
    final rightEye = Offset(size.width * 0.65, size.height * 0.43);
    final leftCheek = Offset(size.width * 0.28, size.height * 0.58);
    final rightCheek = Offset(size.width * 0.72, size.height * 0.58);

    switch (type) {
      case MoodFaceType.excellent:
        _drawClosedHappyEye(canvas, leftEye, linePaint);
        _drawClosedHappyEye(canvas, rightEye, linePaint);
        canvas.drawCircle(leftCheek, size.width * 0.065, blushPaint);
        canvas.drawCircle(rightCheek, size.width * 0.065, blushPaint);
        _drawBigSmile(canvas, size, linePaint);
        break;

      case MoodFaceType.bien:
        canvas.drawCircle(leftEye, size.width * 0.035, fillPaint);
        canvas.drawCircle(rightEye, size.width * 0.035, fillPaint);
        canvas.drawCircle(leftCheek, size.width * 0.055, blushPaint);
        canvas.drawCircle(rightCheek, size.width * 0.055, blushPaint);
        _drawSoftSmile(canvas, size, linePaint);
        break;

      case MoodFaceType.neutre:
        canvas.drawCircle(leftEye, size.width * 0.035, fillPaint);
        canvas.drawCircle(rightEye, size.width * 0.035, fillPaint);
        _drawNeutralMouth(canvas, size, linePaint);
        break;

      case MoodFaceType.triste:
        _drawSadEye(canvas, leftEye, linePaint);
        _drawSadEye(canvas, rightEye, linePaint);
        _drawSadMouth(canvas, size, linePaint);
        break;

      case MoodFaceType.besoinSoutien:
        _drawAngryLeftEye(canvas, leftEye, linePaint);
        _drawAngryRightEye(canvas, rightEye, linePaint);
        canvas.drawCircle(leftCheek, size.width * 0.045, blushPaint);
        canvas.drawCircle(rightCheek, size.width * 0.045, blushPaint);
        _drawWorriedMouth(canvas, size, linePaint);
        break;
    }
  }

  void _drawClosedHappyEye(Canvas canvas, Offset c, Paint paint) {
    final path = Path()
      ..moveTo(c.dx - 4, c.dy)
      ..quadraticBezierTo(c.dx, c.dy + 3, c.dx + 4, c.dy);
    canvas.drawPath(path, paint);
  }

  void _drawSadEye(Canvas canvas, Offset c, Paint paint) {
    final path = Path()
      ..moveTo(c.dx - 4, c.dy + 1)
      ..quadraticBezierTo(c.dx, c.dy - 3, c.dx + 4, c.dy + 1);
    canvas.drawPath(path, paint);
  }

  void _drawAngryLeftEye(Canvas canvas, Offset c, Paint paint) {
    final path = Path()
      ..moveTo(c.dx - 5, c.dy - 2)
      ..lineTo(c.dx + 4, c.dy + 2);
    canvas.drawPath(path, paint);
  }

  void _drawAngryRightEye(Canvas canvas, Offset c, Paint paint) {
    final path = Path()
      ..moveTo(c.dx - 4, c.dy + 2)
      ..lineTo(c.dx + 5, c.dy - 2);
    canvas.drawPath(path, paint);
  }

  void _drawBigSmile(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.34, size.height * 0.64)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.77,
        size.width * 0.66,
        size.height * 0.64,
      );
    canvas.drawPath(path, paint);
  }

  void _drawSoftSmile(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.37, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.72,
        size.width * 0.63,
        size.height * 0.65,
      );
    canvas.drawPath(path, paint);
  }

  void _drawNeutralMouth(Canvas canvas, Size size, Paint paint) {
    canvas.drawLine(
      Offset(size.width * 0.40, size.height * 0.67),
      Offset(size.width * 0.60, size.height * 0.67),
      paint,
    );
  }

  void _drawSadMouth(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.38, size.height * 0.70)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.60,
        size.width * 0.62,
        size.height * 0.70,
      );
    canvas.drawPath(path, paint);
  }

  void _drawWorriedMouth(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.40, size.height * 0.70)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.62,
        size.width * 0.60,
        size.height * 0.70,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MoodFacePainter oldDelegate) {
    return oldDelegate.type != type;
  }
}
