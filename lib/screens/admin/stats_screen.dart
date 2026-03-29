import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const String _base = 'http://localhost:5001';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _data;
  bool _loading = true;

  late AnimationController _animCtrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _load();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await SharedPreferences.getInstance();
      final t = p.getString('token') ?? '';
      final res = await http.get(Uri.parse('$_base/api/stats'),
        headers: {'Authorization': 'Bearer $t'});
      if (res.statusCode == 200) {
        setState(() => _data = jsonDecode(res.body));
        _animCtrl.forward();
      }
    } catch (e) { debugPrint('❌ $e'); }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFFA855F7)));
    if (_data == null) return Center(child: Text('Erreur de chargement', style: GoogleFonts.poppins()));

    final croissance   = (_data!['croissanceUtilisateurs'] as List?) ?? [];
    final engagement   = (_data!['repartitionEngagement']  as List?) ?? [];
    final categories   = (_data!['activitesParCategorie']  as List?) ?? [];
    final hebdo        = (_data!['activiteHebdomadaire']   as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Titre ────────────────────────────────────────────────────────────
        Text('Statistiques et analytics',
          style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
        Text("Suivez l'activité et l'engagement des utilisateurs",
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
        const SizedBox(height: 28),

        // ── KPI Cards ─────────────────────────────────────────────────────────
        Wrap(spacing: 16, runSpacing: 16, children: [
          _kpi('Utilisateurs actifs', '${_data!['utilisateursActifs']}', 'Total inscrits non bloqués', Icons.people_outline_rounded, const Color(0xFF6366F1)),
          _kpi('Taux d\'engagement', '${_data!['tauxEngagement']}%', 'Users avec ≥1 activité', Icons.trending_up_rounded, const Color(0xFFA855F7)),
          _kpi('Activités créées', '${_data!['activitesCrees']}', '+${_data!['activitesCeMois'] ?? 0} ce mois', Icons.calendar_today_outlined, const Color(0xFF14B8A6)),
          _kpi('Badges débloqués', '${_data!['badgesDebloques']}', 'Total tous utilisateurs', Icons.emoji_events_outlined, const Color(0xFFF59E0B)),
        ]),
        const SizedBox(height: 24),

        // ── Croissance + Engagement ───────────────────────────────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _card(
            title: 'Croissance des utilisateurs',
            subtitle: 'Évolution du nombre d\'utilisateurs',
            child: SizedBox(height: 200, child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => CustomPaint(
                painter: _LinePainter(croissance, _anim.value),
                size: const Size(double.infinity, 200),
              ),
            )),
          )),
          const SizedBox(width: 20),
          SizedBox(width: 340, child: _card(
            title: 'Répartition de l\'engagement',
            subtitle: 'Niveau d\'activité des utilisateurs',
            child: SizedBox(height: 200, child: Row(children: [
              Expanded(child: AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => CustomPaint(
                  painter: _PiePainter(engagement, _anim.value),
                  size: const Size(double.infinity, 200),
                ),
              )),
              const SizedBox(width: 12),
              Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                children: engagement.map<Widget>((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(
                      color: Color(int.parse('0xFF${(e['couleur'] as String).replaceAll('#', '')}')),
                      shape: BoxShape.circle,
                    )),
                    const SizedBox(width: 6),
                    Text('${e['label']} ${e['valeur']}%',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700])),
                  ]),
                )).toList()),
            ])),
          )),
        ]),
        const SizedBox(height: 20),

        // ── Activités par catégorie ────────────────────────────────────────────
        _card(
          title: 'Activités par catégorie',
          subtitle: 'Répartition des services proposés',
          child: SizedBox(height: 200, child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => CustomPaint(
              painter: _BarPainter(categories, _anim.value, const Color(0xFFEC4899)),
              size: const Size(double.infinity, 200),
            ),
          )),
        ),
        const SizedBox(height: 20),

        // ── Activité hebdomadaire ─────────────────────────────────────────────
        _card(
          title: 'Activité hebdomadaire',
          subtitle: 'Activités et participants par jour',
          child: SizedBox(height: 200, child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => CustomPaint(
              painter: _GroupedBarPainter(hebdo, _anim.value),
              size: const Size(double.infinity, 200),
            ),
          )),
        ),
        const SizedBox(height: 20),

        // ── Métriques bas ─────────────────────────────────────────────────────
        Row(children: [
          Expanded(child: _metricCard('Taux de rétention', '${_data!['tauxRetention']}%',
            'Les utilisateurs reviennent régulièrement', const Color(0xFF10B981))),
          const SizedBox(width: 16),
          Expanded(child: _metricCard('Temps moyen/session', '${_data!['tempsMoyenSession']} min',
            'Durée moyenne d\'utilisation', const Color(0xFF6366F1))),
          const SizedBox(width: 16),
          Expanded(child: _metricCard('Satisfaction', '${_data!['satisfaction']}/5',
            'Note moyenne des utilisateurs', const Color(0xFFF59E0B))),
        ]),
      ]),
    );
  }

  // ── Widgets helpers ───────────────────────────────────────────────────────

  Widget _kpi(String label, String value, String sub, IconData icon, Color color) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          Text(sub, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400])),
        ])),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
      ]),
    );
  }

  Widget _card({required String title, required String subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E))),
        Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400])),
        const SizedBox(height: 20),
        child,
      ]),
    );
  }

  Widget _metricCard(String title, String value, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 4),
        Text(desc, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400])),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════

// ── Line Chart ────────────────────────────────────────────────
class _LinePainter extends CustomPainter {
  final List data;
  final double progress;
  _LinePainter(this.data, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = (data.map((d) => (d['valeur'] as num).toDouble()).reduce(max) * 1.2);
    final padL = 40.0, padB = 30.0, padR = 16.0, padT = 10.0;
    final w = size.width - padL - padR;
    final h = size.height - padB - padT;

    // Grid lines
    final gridPaint = Paint()..color = Colors.grey.withOpacity(0.08)..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = padT + h - (h * i / 4);
      canvas.drawLine(Offset(padL, y), Offset(size.width - padR, y), gridPaint);
      final val = (maxVal * i / 4).round();
      _drawText(canvas, '$val', Offset(padL - 6, y - 6), 9, Colors.grey[400]!, TextAlign.right, 36);
    }

    // Points
    final pts = List.generate(data.length, (i) {
      final x = padL + (i / (data.length - 1)) * w;
      final y = padT + h - (h * (data[i]['valeur'] as num) / maxVal);
      return Offset(x, y);
    });

    // Gradient fill
    final fillPath = Path()..moveTo(pts.first.dx, padT + h);
    for (final p in pts) fillPath.lineTo(p.dx, p.dy);
    fillPath..lineTo(pts.last.dx, padT + h)..close();
    canvas.drawPath(fillPath, Paint()..shader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [const Color(0xFFA855F7).withOpacity(0.2), const Color(0xFFA855F7).withOpacity(0)],
    ).createShader(Rect.fromLTWH(0, padT, size.width, h)));

    // Line (animated)
    final linePaint = Paint()..color = const Color(0xFFA855F7)..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final animPts = pts.take(max(2, (pts.length * progress).round())).toList();
    if (animPts.length >= 2) {
      final path = Path()..moveTo(animPts.first.dx, animPts.first.dy);
      for (int i = 1; i < animPts.length; i++) {
        final cp1 = Offset((animPts[i-1].dx + animPts[i].dx) / 2, animPts[i-1].dy);
        final cp2 = Offset((animPts[i-1].dx + animPts[i].dx) / 2, animPts[i].dy);
        path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, animPts[i].dx, animPts[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Dots + labels
    for (int i = 0; i < animPts.length; i++) {
      canvas.drawCircle(animPts[i], 5, Paint()..color = const Color(0xFFA855F7));
      canvas.drawCircle(animPts[i], 3, Paint()..color = Colors.white);
      _drawText(canvas, data[i]['mois'], Offset(animPts[i].dx, padT + h + 6), 10, Colors.grey[500]!, TextAlign.center, 30);
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, double size, Color color, TextAlign align, double maxW) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, color: color)),
      textAlign: align, textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxW);
    tp.paint(canvas, offset - Offset(align == TextAlign.center ? tp.width / 2 : align == TextAlign.right ? tp.width : 0, 0));
  }

  @override bool shouldRepaint(covariant _LinePainter old) => old.progress != progress;
}

// ── Pie Chart ─────────────────────────────────────────────────
class _PiePainter extends CustomPainter {
  final List data;
  final double progress;
  _PiePainter(this.data, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final cx = size.width / 2, cy = size.height / 2;
    final r = min(cx, cy) - 10;
    double startAngle = -pi / 2;
    final total = data.fold<double>(0, (s, e) => s + (e['valeur'] as num));

    for (final e in data) {
      final sweep = 2 * pi * ((e['valeur'] as num) / total) * progress;
      final hex = (e['couleur'] as String).replaceAll('#', '');
      final color = Color(int.parse('0xFF$hex'));
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle, sweep, true,
        Paint()..color = color..style = PaintingStyle.fill,
      );
      // gap
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle, sweep, true,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2,
      );
      startAngle += sweep;
    }
    // Center hole
    canvas.drawCircle(Offset(cx, cy), r * 0.55, Paint()..color = Colors.white);
  }

  @override bool shouldRepaint(covariant _PiePainter old) => old.progress != progress;
}

// ── Bar Chart ─────────────────────────────────────────────────
class _BarPainter extends CustomPainter {
  final List data;
  final double progress;
  final Color color;
  _BarPainter(this.data, this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = (data.map((d) => (d['nombre'] as num).toDouble()).reduce(max) * 1.2);
    final padL = 10.0, padB = 28.0, padT = 10.0, padR = 10.0;
    final w = size.width - padL - padR;
    final h = size.height - padB - padT;
    final barW = (w / data.length) * 0.5;
    final gap   = w / data.length;

    for (int i = 0; i < data.length; i++) {
      final x = padL + gap * i + (gap - barW) / 2;
      final barH = (h * (data[i]['nombre'] as num) / maxVal) * progress;
      final y = padT + h - barH;

      final rr = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, barW, barH), const Radius.circular(6));
      canvas.drawRRect(rr, Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.9), color.withOpacity(0.5)],
      ).createShader(Rect.fromLTWH(x, y, barW, barH)));

      // label
      final tp = TextPainter(
        text: TextSpan(text: data[i]['categorie'], style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        textDirection: TextDirection.ltr, textAlign: TextAlign.center,
      )..layout(maxWidth: gap);
      tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, padT + h + 6));
    }
  }

  @override bool shouldRepaint(covariant _BarPainter old) => old.progress != progress;
}

// ── Grouped Bar Chart (hebdo) ─────────────────────────────────
class _GroupedBarPainter extends CustomPainter {
  final List data;
  final double progress;
  _GroupedBarPainter(this.data, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final allVals = data.expand((d) => [(d['activites'] as num).toDouble(), (d['participants'] as num).toDouble()]);
    final maxVal = allVals.reduce(max) * 1.2;
    final padL = 10.0, padB = 28.0, padT = 10.0, padR = 10.0;
    final w = size.width - padL - padR;
    final h = size.height - padB - padT;
    final groupW = w / data.length;
    final barW   = groupW * 0.3;

    for (int i = 0; i < data.length; i++) {
      final groupX = padL + groupW * i;

      // Bar 1 — activités (violet)
      final h1 = (h * (data[i]['activites'] as num) / maxVal) * progress;
      final x1 = groupX + groupW * 0.1;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x1, padT + h - h1, barW, h1), const Radius.circular(4)),
        Paint()..color = const Color(0xFFA855F7).withOpacity(0.85),
      );

      // Bar 2 — participants (rose)
      final h2 = (h * (data[i]['participants'] as num) / maxVal) * progress;
      final x2 = x1 + barW + 3;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x2, padT + h - h2, barW, h2), const Radius.circular(4)),
        Paint()..color = const Color(0xFFEC4899).withOpacity(0.85),
      );

      // Jour label
      final tp = TextPainter(
        text: TextSpan(text: data[i]['jour'], style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(groupX + groupW / 2 - tp.width / 2, padT + h + 6));
    }

    // Légende
    _legend(canvas, size, 'Activités', const Color(0xFFA855F7), size.width - 200);
    _legend(canvas, size, 'Participants', const Color(0xFFEC4899), size.width - 110);
  }

  void _legend(Canvas canvas, Size size, String text, Color color, double x) {
    canvas.drawCircle(Offset(x, 8), 5, Paint()..color = color);
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x + 9, 2));
  }

  @override bool shouldRepaint(covariant _GroupedBarPainter old) => old.progress != progress;
}
