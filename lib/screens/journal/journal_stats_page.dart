// journal_stats_page.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wejoy/screens/service/api_service.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _rose   = Color(0xFFE84C88);
const _violet = Color(0xFF7C4DFF);
const _bg     = Color(0xFFFFF0F5);
const _bg2    = Color(0xFFF3EEFF);
const _ink    = Color(0xFF2D1B69);
const _slate  = Color(0xFF9B8FC4);
const _white  = Color(0xFFFFFFFF);
const _border = Color(0xFFF1E6DD);
const _green  = Color(0xFF10B981);

// ─── Stickers ─────────────────────────────────────────────────────────────────
const _stickers = [
  'assets/images/moods/mood_1_mal.png',
  'assets/images/moods/mood_2_pas_bien.png',
  'assets/images/moods/mood_3_pas_mal.png',
  'assets/images/moods/mood_4_bien.png',
  'assets/images/moods/mood_5_tres_bien.png',
];

class _Sticker extends StatelessWidget {
  final int index;
  final double size;
  const _Sticker({required this.index, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final i = index.clamp(0, 4);
    return Image.asset(
      _stickers[i],
      width: size, height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Text(
        ['😞','😔','😐','😊','🤩'][i],
        style: TextStyle(fontSize: size * 0.7),
      ),
    );
  }
}

// ─── Modèles ──────────────────────────────────────────────────────────────────
class MoodPoint {
  final String day;
  final double value;
  final bool   hasEntry;
  const MoodPoint({required this.day, required this.value, this.hasEntry = false});

  factory MoodPoint.fromJson(Map<String, dynamic> j) => MoodPoint(
    day:      j['day']      as String? ?? '',
    value:    (j['value']   as num?)?.toDouble() ?? 3.0,
    hasEntry: j['hasEntry'] as bool?   ?? false,
  );
}

class JournalStats {
  final double averageMood;
  final String dominantMood;
  final int    entriesCount;
  final String trend;
  final String insight;
  final String insightNeutral;
  final List<MoodPoint>           moodHistory;
  final int    wellnessScore;
  final int    streak;
  final double sentimentRatio;
  final int    positiveCount;
  final int    negativeCount;
  final int    neutralCount;
  final List<Map<String,dynamic>> moodDistribution;

  const JournalStats({
    required this.averageMood,
    required this.dominantMood,
    required this.entriesCount,
    required this.trend,
    required this.insight,
    required this.insightNeutral,
    required this.moodHistory,
    this.wellnessScore    = 0,
    this.streak           = 0,
    this.sentimentRatio   = 0.5,
    this.positiveCount    = 0,
    this.negativeCount    = 0,
    this.neutralCount     = 0,
    this.moodDistribution = const [],
  });

  factory JournalStats.fromJson(Map<String, dynamic> j) => JournalStats(
    averageMood:      (j['averageMood']    as num?)?.toDouble() ?? 0.0,
    dominantMood:     j['dominantMood']    as String? ?? 'Neutre',
    entriesCount:     j['entriesCount']    as int?    ?? 0,
    trend:            j['trend']           as String? ?? 'stable',
    insight:          j['insight']         as String? ?? '',
    insightNeutral:   j['insightNeutral']  as String? ?? '',
    moodHistory:      (j['moodHistory']    as List<dynamic>? ?? [])
        .map((e) => MoodPoint.fromJson(e as Map<String, dynamic>)).toList(),
    wellnessScore:    j['wellnessScore']   as int?    ?? 0,
    streak:           j['streak']          as int?    ?? 0,
    sentimentRatio:   (j['sentimentRatio'] as num?)?.toDouble() ?? 0.5,
    positiveCount:    j['positiveCount']   as int?    ?? 0,
    negativeCount:    j['negativeCount']   as int?    ?? 0,
    neutralCount:     j['neutralCount']    as int?    ?? 0,
    moodDistribution: (j['moodDistribution'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map)).toList(),
  );
}

// ─── Service ──────────────────────────────────────────────────────────────────
class JournalStatsService {
  static const String _baseUrl = 'http://localhost:5000/api/journal';

  static Future<JournalStats> fetch() async {
    final token = await ApiService().getToken();
    final res = await http.get(
      Uri.parse('$_baseUrl/stats'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      return JournalStats.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Erreur ${res.statusCode}');
  }
}

// ─── Page principale ──────────────────────────────────────────────────────────
class JournalStatsPage extends StatefulWidget {
  const JournalStatsPage({super.key});

  @override
  State<JournalStatsPage> createState() => _JournalStatsPageState();
}

class _JournalStatsPageState extends State<JournalStatsPage>
    with TickerProviderStateMixin {
  late Future<JournalStats> _future;
  late AnimationController  _fadeCtrl;
  bool _showEmotional = true;

  @override
  void initState() {
    super.initState();
    _future   = JournalStatsService.fetch();
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bg, _bg2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<JournalStats>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) return const _Loader();
            if (snap.hasError) return _ErrorScreen(snap.error.toString());
            final stats = snap.data!;

            return FadeTransition(
              opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(context),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        
                        // 2. Cercle wellness animé
                        _WellnessCircle(
                          score: stats.wellnessScore,
                          averageMood: stats.averageMood,
                        ),
                        const SizedBox(height: 14),
                        // 3. Répartition des humeurs
                        if (stats.moodDistribution.isNotEmpty) ...[
                          _MoodBubbles(
                            distribution: stats.moodDistribution,
                            totalCount: stats.entriesCount,
                          ),
                          const SizedBox(height: 14),
                        ],
                        // 4. Barres 7 jours avec stickers
                        _WeekBars(moodHistory: stats.moodHistory),
                        const SizedBox(height: 14),
                        // 5. Résumé de la semaine
                        _ResumeCard(
                          text: _showEmotional ? stats.insight : stats.insightNeutral,
                          isEmotional: _showEmotional,
                          onToggle: () =>
                              setState(() => _showEmotional = !_showEmotional),
                        ),
                        const SizedBox(height: 14),
                        // 6. 3 tuiles stats
                        _StatsRow(stats: stats),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) => SliverAppBar(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    pinned: true,
    expandedHeight: 86,
    leading: GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
          boxShadow: [BoxShadow(color: _rose.withOpacity(0.10), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: _slate, size: 16),
      ),
    ),
    flexibleSpace: FlexibleSpaceBar(
      titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [_bg, _bg2], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
      ),
      title: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(colors: [_rose, _violet]).createShader(b),
            child: const Text(
              'Mes émotions',
              style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.4),
            ),
          ),
          Text('7 derniers jours', style: TextStyle(color: _slate.withOpacity(0.7), fontSize: 11)),
        ],
      ),
    ),
  );
}

// ─── Cercle Wellness animé ────────────────────────────────────────────────────
class _WellnessCircle extends StatefulWidget {
  final int    score;
  final double averageMood;
  const _WellnessCircle({required this.score, required this.averageMood});

  @override
  State<_WellnessCircle> createState() => _WellnessCircleState();
}

class _WellnessCircleState extends State<_WellnessCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 200), _ctrl.forward);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String _label(int score) {
    if (score >= 80) return 'Tu te sens très bien 🌟';
    if (score >= 60) return 'Tu te sens bien la plupart du temps ☀️';
    if (score >= 40) return 'Semaine mitigée, tu tiens bon 🌿';
    if (score >= 20) return 'Semaine difficile, prends soin de toi 💙';
    return 'Commence à écrire pour voir tes stats 🌱';
  }

  int _stickerIndex(int score) {
    if (score >= 80) return 4;
    if (score >= 60) return 3;
    if (score >= 40) return 2;
    if (score >= 20) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final safe = widget.score.clamp(0, 100);
// cercle du stat
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [BoxShadow(color: _violet.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        // Cercle
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            final progress = (safe / 100) * _anim.value;
            final displayed = (safe * _anim.value).round();
            return SizedBox(
              width: 170, height: 170,
              child: Stack(alignment: Alignment.center, children: [
                CustomPaint(
                  size: const Size(170, 170),
                  painter: _CirclePainter(progress: progress),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    '$displayed%',
                    style: const TextStyle(
                      color: _ink, fontSize: 38,
                      fontWeight: FontWeight.w900, letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bien-être',
                    style: TextStyle(color: _slate.withOpacity(0.7), fontSize: 12),
                  ),
                ]),
              ]),
            );
          },
        ),
        const SizedBox(height: 18),
        // Label + sticker
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _Sticker(index: _stickerIndex(safe), size: 28),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _label(safe),
              style: const TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
        ]),
      ]),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  const _CirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final c       = Offset(size.width / 2, size.height / 2);
    final r       = size.width / 2 - 14;
    const stroke  = 14.0;

    // Fond
    canvas.drawCircle(c, r, Paint()
      ..color      = const Color(0xFFEDE8FF)
      ..style      = PaintingStyle.stroke
      ..strokeWidth = stroke);

    if (progress <= 0) return;

    // Arc gradient
    final rect   = Rect.fromCircle(center: c, radius: r);
    final shader = SweepGradient(
      colors:     [_violet, _rose, _violet],
      stops:      const [0.0, 0.7, 1.0],
      startAngle: -math.pi / 2,
      endAngle:    3 * math.pi / 2,
    ).createShader(rect);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader      = shader
        ..style       = PaintingStyle.stroke
        ..strokeWidth  = stroke
        ..strokeCap   = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CirclePainter o) => o.progress != progress;
}

// ─── Répartition des humeurs (bulles) ────────────────────────────────────────
class _MoodBubbles extends StatefulWidget {
  final List<Map<String, dynamic>> distribution;
  final int totalCount;
  const _MoodBubbles({required this.distribution, required this.totalCount});

  @override
  State<_MoodBubbles> createState() => _MoodBubblesState();
}

class _MoodBubblesState extends State<_MoodBubbles>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    Future.delayed(const Duration(milliseconds: 500), _ctrl.forward);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Color _color(int v) {
    switch (v) {
      case 5: return const Color(0xFFFFD166);
      case 4: return _green;
      case 3: return _violet.withOpacity(0.75);
      case 2: return _rose.withOpacity(0.75);
      default: return _slate.withOpacity(0.55);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.distribution]
      ..sort((a, b) => (b['percentage'] as int).compareTo(a['percentage'] as int));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [BoxShadow(color: _violet.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _rose.withOpacity(0.10), borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.pie_chart_rounded, size: 15, color: _rose),
          ),
          const SizedBox(width: 10),
          const Text('Répartition des humeurs',
              style: TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 20),
        // Bulles
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: sorted.map((item) {
              final pct      = item['percentage'] as int?    ?? 0;
              final moodVal  = item['moodValue']  as int?    ?? 3;
              final label    = item['moodLabel']  as String? ?? '';
              final bubbleSize = (48 + pct * 1.3).clamp(48.0, 120.0) * _anim.value;
              final color    = _color(moodVal);
              final idx      = (moodVal - 1).clamp(0, 4);

              return Column(mainAxisSize: MainAxisSize.min, children: [
                Transform.scale(
                  scale: _anim.value,
                  child: Container(
                    width: bubbleSize, height: bubbleSize,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.35), width: 2),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _Sticker(index: idx, size: bubbleSize * 0.40),
                      const SizedBox(height: 2),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          color: color,
                          fontSize: bubbleSize * 0.17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(color: _slate, fontSize: 10, fontWeight: FontWeight.w600)),
              ]);
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

// ─── Barres 7 jours avec stickers ────────────────────────────────────────────
class _WeekBars extends StatefulWidget {
  final List<MoodPoint> moodHistory;
  const _WeekBars({required this.moodHistory});

  @override
  State<_WeekBars> createState() => _WeekBarsState();
}

class _WeekBarsState extends State<_WeekBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 400), _ctrl.forward);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  int _idx(double v) => (v.round().clamp(1, 5) - 1);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [BoxShadow(color: _violet.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _violet.withOpacity(0.10), borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_today_rounded, size: 15, color: _violet),
          ),
          const SizedBox(width: 10),
          const Text('7 derniers jours',
              style: TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => LayoutBuilder(
            builder: (ctx, constraints) {
              final barMaxW = constraints.maxWidth - 34 - 10; // 34 = label width

              return Column(
                children: widget.moodHistory.map((pt) {
                  final ratio  = ((pt.value - 1) / 4).clamp(0.0, 1.0) * _anim.value;
                  final active = pt.hasEntry;
                  final barW   = active ? (barMaxW * ratio).clamp(40.0, barMaxW) : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      // Label jour
                      SizedBox(
                        width: 24,
                        child: Text(
                          pt.day.isNotEmpty ? pt.day.substring(0, 1) : '?',
                          style: TextStyle(
                            color: active ? _ink : _slate.withOpacity(0.35),
                            fontSize: 13, fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Barre
                      Expanded(
                        child: Stack(children: [
                          // Fond
                          Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3EEFF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          // Barre colorée
                          if (active)
                            Container(
                              width: barW,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_violet, _rose],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          // Sticker aligné à la fin de la barre
                          if (active && barW >= 40)
                            Positioned(
                              left: (barW - 38).clamp(0.0, barMaxW - 38),
                              top: 1,
                              child: _Sticker(index: _idx(pt.value), size: 36),
                            ),
                          // Pas d'entrée
                          if (!active)
                            Positioned(
                              right: 12,
                              top: 0, bottom: 0,
                              child: Center(
                                child: Text('—',
                                    style: TextStyle(color: _slate.withOpacity(0.4), fontSize: 13)),
                              ),
                            ),
                        ]),
                      ),
                    ]),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ─── Résumé de la semaine (insight IA renommé) ────────────────────────────────
class _ResumeCard extends StatefulWidget {
  final String       text;
  final bool         isEmotional;
  final VoidCallback onToggle;

  const _ResumeCard({
    required this.text,
    required this.isEmotional,
    required this.onToggle,
  });

  @override
  State<_ResumeCard> createState() => _ResumeCardState();
}

class _ResumeCardState extends State<_ResumeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late Animation<double>   _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [_violet.withOpacity(0.07), _rose.withOpacity(0.04)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _violet.withOpacity(0.20), width: 1.5),
      boxShadow: [BoxShadow(
        color: _violet.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8),
      )],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        // Avatar Joya animé ↕
        AnimatedBuilder(
          animation: _bounceAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _bounceAnim.value),
            child: child,
          ),
          child: Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFFB97CF8), _violet]),
            ),
            child: const Center(
              child: Text('^_^', style: TextStyle(fontSize: 13, color: Colors.white)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Résumé de la semaine',
          style: TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        GestureDetector(
          onTap: widget.onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _rose.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _rose.withOpacity(0.20)),
            ),
            child: Text(
              widget.isEmotional ? '💜 Émotionnel' : '📊 Neutre',
              style: const TextStyle(color: _rose, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: Text(
          widget.text.isNotEmpty ? widget.text : 'Aucun résumé disponible pour le moment.',
          key: ValueKey(widget.text),
          softWrap: true,
          style: const TextStyle(color: _ink, fontSize: 14.5, height: 1.65, letterSpacing: 0.1),
        ),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Container(width: 5, height: 5,
            decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('Généré par Gemini AI',
            style: TextStyle(color: _slate.withOpacity(0.5), fontSize: 10)),
      ]),
    ]),
  );
}

// ─── 3 Tuiles stats ───────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final JournalStats stats;
  const _StatsRow({required this.stats});

  int _avgIdx(double avg) {
    if (avg >= 4.5) return 4;
    if (avg >= 3.5) return 3;
    if (avg >= 2.5) return 2;
    if (avg >= 1.5) return 1;
    return 0;
  }

  int _domIdx(String d) {
    final l = d.toLowerCase();
    if (l.contains('très mal')  || l.contains('tres mal'))  return 0;
    if (l.contains('pas bien')  || (l.contains('mal') && !l.contains('pas'))) return 1;
    if (l.contains('neutre')    || l.contains('pas mal'))   return 2;
    if (l.contains('bien')      && !l.contains('très') && !l.contains('tres')) return 3;
    if (l.contains('excellent') || l.contains('très bien') || l.contains('tres bien')) return 4;
    return 2;
  }

  @override
  Widget build(BuildContext context) => Row(children: [
    _tile(idx: _avgIdx(stats.averageMood),
        value: stats.averageMood.toStringAsFixed(1), label: 'Humeur moy.', accent: _violet),
    const SizedBox(width: 10),
    _tile(idx: _domIdx(stats.dominantMood),
        value: stats.dominantMood, label: 'Dominant', accent: _green),
    const SizedBox(width: 10),
    _tileIcon(icon: Icons.edit_rounded,
        value: '${stats.entriesCount}', label: 'Entrées', accent: _rose),
  ]);

  Widget _tile({
    required int idx, required String value,
    required String label, required Color accent,
  }) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: _white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [BoxShadow(color: accent.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Sticker(index: idx, size: 50),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w800),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: _slate.withOpacity(0.6), fontSize: 10)),
      ]),
    ),
  );

  Widget _tileIcon({
    required IconData icon, required String value,
    required String label, required Color accent,
  }) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: _white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [BoxShadow(color: accent.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.10), borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: accent, size: 26),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: _slate.withOpacity(0.6), fontSize: 10)),
      ]),
    ),
  );
}

// ─── Loading / Error ──────────────────────────────────────────────────────────
class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(color: _violet, strokeWidth: 2),
      SizedBox(height: 16),
      Text('Analyse en cours…', style: TextStyle(color: _slate, fontSize: 13)),
    ]),
  );
}

class _ErrorScreen extends StatelessWidget {
  final String msg;
  const _ErrorScreen(this.msg);

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline_rounded, color: _rose, size: 44),
        const SizedBox(height: 14),
        const Text('Impossible de charger',
            style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(msg, style: TextStyle(color: _slate.withOpacity(0.6), fontSize: 11),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}