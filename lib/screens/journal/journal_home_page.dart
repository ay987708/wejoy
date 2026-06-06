import 'dart:async';
 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wejoy/models/mood_option.dart';
import 'package:wejoy/screens/journal/journal_entry_page.dart';
import 'package:wejoy/screens/journal/journal_stats_page.dart';
import 'package:wejoy/screens/journal/journal_timeline_page.dart';
import 'package:wejoy/screens/service/api_service.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
// Modèle JournalEntry
// ─────────────────────────────────────────────────────────────────────────────
class JournalEntry {
  final String id;
  final String content;
  final int moodValue;
  final List<String> tags;
  final String sentiment;
  final DateTime createdAt;
 
  const JournalEntry({
    required this.id,
    required this.content,
    required this.moodValue,
    required this.tags,
    required this.sentiment,
    required this.createdAt,
  });
 
  MoodOption get mood => kMoods.firstWhere(
        (m) => m.value == moodValue,
        orElse: () => kMoods[2],
      );
 
  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['_id'] ?? '',
        content: json['content'] ?? '',
        moodValue: json['moodValue'] ?? 3,
        tags: List<String>.from(json['tags'] ?? []),
        sentiment: json['sentiment'] ?? 'Neutre',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}
 
// ─────────────────────────────────────────────────────────────────────────────
// Widget principal
// ─────────────────────────────────────────────────────────────────────────────
class JournalHomePage extends StatefulWidget {
  const JournalHomePage({super.key});
 
  @override
  State<JournalHomePage> createState() => _JournalHomePageState();
}
 
class _JournalHomePageState extends State<JournalHomePage>
    with TickerProviderStateMixin {
 
  int    _selectedMood  = -1;
  bool   _isLoading     = true;
  int    _streak        = 0;
  String _avgMood       = 'Bien';
  int    _totalEntries  = 0;
  List<JournalEntry> _entries = [];
 
  final String _userName = 'Sirine';
 
  late AnimationController _mascotCtrl;
  late Animation<double>   _mascotFloat;
 
  final TextEditingController _textCtrl = TextEditingController();
 
  Timer?  _debounce;
  String? _detectedMood;
  String? _detectedEmoji;
  bool    _isAnalyzing = false;
 
  String? _joyaResponse;
  bool    _isJoyaLoading = false;
 
  static const Color _bgTop    = Color(0xFFFFF0F5);
  static const Color _bgBot    = Color(0xFFF3EEFF);
  static const Color _purple   = Color(0xFFA855F7);
  static const Color _pink     = Color(0xFFF472B6);
  static const Color _textDark = Color(0xFF2D1B69);
  static const Color _textGrey = Color(0xFF9B8FC4);
 
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }
 
  @override
  void initState() {
    super.initState();
    _mascotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
 
    _mascotFloat = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _mascotCtrl, curve: Curves.easeInOut),
    );
 
    _loadData();
  }
 
  @override
  void dispose() {
    _mascotCtrl.dispose();
    _textCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }
 
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api   = ApiService();
      final res   = await api.getJournalEntries(limit: 20);
      final stats = await api.getJournalStats();
 
      final entriesJson   = res['entries'] as List<dynamic>? ?? [];
      final loadedEntries =
          entriesJson.map((e) => JournalEntry.fromJson(e)).toList();
 
      if (!mounted) return;
      setState(() {
        _entries      = loadedEntries;
        _totalEntries = stats['totalEntries'] ?? loadedEntries.length;
        _streak       = stats['streak'] ?? 0;
        _avgMood      = stats['avgMoodLabel'] ?? 'Neutre';
      });
    } catch (e) {
      debugPrint('Erreur loadData: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
 
  void _onTextChanged(String text) {
    _debounce?.cancel();
    if (text.trim().length < 10) {
      if (_detectedMood != null) {
        setState(() {
          _detectedMood  = null;
          _detectedEmoji = null;
        });
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _analyzeMood(text);
    });
  }
 
  Future<void> _analyzeMood(String text) async {
    if (!mounted) return;
    setState(() => _isAnalyzing = true);
    try {
      final data = await ApiService().analyzeMood(text);
      if (!mounted) return;
      setState(() {
        _detectedMood  = data['mood']  as String?;
        _detectedEmoji = data['emoji'] as String?;
      });
    } catch (e) {
      debugPrint('Erreur analyzeMood: $e');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }
 
  void _onEnregistrer() {
    final text = _textCtrl.text.trim();
 
    if (_selectedMood == -1) {
      _showSnack('Choisis ton humeur d\'abord 😊');
      return;
    }
    if (text.isEmpty) {
      _showSnack('Écris quelque chose d\'abord ✍️');
      return;
    }
 
    final moodLabel = kMoods[_selectedMood].label;
    _fetchJoyaResponse(text, moodLabel);
 
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JournalEntryPage(
          mood: kMoods[_selectedMood],
          prefillContent: text,
          detectedSentiment: _detectedMood,
        ),
      ),
    ).then((saved) {
      if (saved == true) {
        _textCtrl.clear();
        setState(() {
          _detectedMood  = null;
          _detectedEmoji = null;
          _joyaResponse  = null;
          _selectedMood  = -1;
        });
        _loadData();
      }
    });
  }
 
  Future<void> _fetchJoyaResponse(String text, String moodLabel) async {
    if (!mounted) return;
    setState(() {
      _isJoyaLoading = true;
      _joyaResponse  = null;
    });
    try {
      final response = await ApiService().getJoyaResponse(
        text: text,
        moodLabel: moodLabel,
      );
      if (!mounted) return;
      setState(() => _joyaResponse = response);
    } catch (e) {
      debugPrint('Erreur joyaResponse: $e');
    } finally {
      if (mounted) setState(() => _isJoyaLoading = false);
    }
  }
 
  void _goToWrite() {
    if (_selectedMood == -1) {
      _showSnack('Choisis ton humeur d\'abord 😊');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JournalEntryPage(mood: kMoods[_selectedMood]),
      ),
    ).then((saved) {
      if (saved == true) _loadData();
    });
  }
 
  void _goToStats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JournalStatsPage()),
    );
  }
 
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
 
  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgTop,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgTop, _bgBot],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _purple))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: _purple,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 28),
                        _buildMascot(),
                        const SizedBox(height: 20),
                        // ── Pill "Pensée du moment" style C ──
                        _buildPenseePill(),
                        const SizedBox(height: 20),
                        _buildMoodRow(),
                        const SizedBox(height: 20),
                        _buildMoodDetectorBadge(),
                        const SizedBox(height: 16),
                        _buildQuickTextField(),
                        if (_isJoyaLoading || _joyaResponse != null) ...[
                          const SizedBox(height: 16),
                          _buildJoyaResponse(),
                        ],
                        const SizedBox(height: 16),
                        _buildStatsRow(),
                        const SizedBox(height: 24),
                        _buildWriteButton(),
                        const SizedBox(height: 28),
                        if (_entries.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Dernière entrée',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _textDark,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const JournalTimelinePage()),
                                ),
                                child: const Text(
                                  'voir tout →',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _purple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildLastEntry(_entries.first),
                        ] else
                          _buildEmptyState(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
 
  // ── PILL "PENSÉE DU MOMENT" — Style C ────────────────────────────────────
  Widget _buildPenseePill() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEDE0FF), Color(0xFFFFD6EE)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFC9A0F5), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '💫 PENSÉE DU MOMENT',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: Color(0xFF9B6DE0),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _getPensee(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: Color(0xFF9B3DBF),
                height: 1.4,
              ),
            ),
          ],
        ),
      );
 
  String _getPensee() {
    if (_selectedMood == -1) return 'Même les petits élans comptent.';
    const pensees = [
      'Chaque larme est une preuve de ta force.',
      'L\'anxiété est juste une vague, elle passe.',
      'Même les jours calmes ont leur beauté.',
      'Ta bonne énergie est contagieuse.',
      'L\'euphorie mérite d\'être capturée !',
    ];
    return pensees[_selectedMood];
  }
 
  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_purple, _pink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                _userName[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting,
                  style: const TextStyle(fontSize: 13, color: _textGrey)),
              Row(
                children: [
                  Text(_userName,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textDark)),
                  const SizedBox(width: 4),
                  const Text('🌸', style: TextStyle(fontSize: 16)),
                ],
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _goToStats,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.12),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: _purple.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  color: _purple, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _purple.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: _textGrey, size: 20),
          ),
        ],
      );
 
  // ── MASCOT ────────────────────────────────────────────────────────────────
  Widget _buildMascot() => AnimatedBuilder(
        animation: _mascotFloat,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _mascotFloat.value),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFB97CF8), _purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Text('^_^',
                        style: TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: _purple.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: const Text(
                  'Comment tu te sens aujourd\'hui ?',
                  style: TextStyle(
                      fontSize: 15,
                      color: _textDark,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
 
  // ── MOOD ROW ──────────────────────────────────────────────────────────────
  Widget _buildMoodRow() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(kMoods.length, (i) {
          final mood     = kMoods[i];
          final selected = _selectedMood == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedMood = i),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? mood.color.withOpacity(0.18)
                        : Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Center(
                    child: Text(mood.emoji,
                        style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  mood.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? mood.color : _textGrey,
                  ),
                ),
              ],
            ),
          );
        }),
      );
 
  // ── BADGE DÉTECTEUR MOOD IA ───────────────────────────────────────────────
  Widget _buildMoodDetectorBadge() {
    if (_textCtrl.text.trim().length < 10 &&
        _detectedMood == null &&
        !_isAnalyzing) {
      return const SizedBox.shrink();
    }
 
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isAnalyzing
          ? Container(
              key: const ValueKey('analyzing'),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _purple.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _purple.withOpacity(0.7)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Joya analyse ton humeur…',
                    style: TextStyle(
                        fontSize: 13,
                        color: _purple.withOpacity(0.8),
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : _detectedMood != null
              ? Container(
                  key: const ValueKey('detected'),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      _purple.withOpacity(0.08),
                      _pink.withOpacity(0.06),
                    ]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _purple.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text('Gemini détecte : ',
                          style: TextStyle(fontSize: 13, color: _textGrey)),
                      Text(
                        '${_detectedEmoji ?? ''} ${_detectedMood ?? ''}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: _purple,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }
 
  // ── CHAMP TEXTE RAPIDE ────────────────────────────────────────────────────
  Widget _buildQuickTextField() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  const Text('✦',
                      style: TextStyle(color: _purple, fontSize: 12)),
                  const SizedBox(width: 6),
                  Text(
                    'Prends ton temps, je suis là 💙',
                    style: TextStyle(
                        fontSize: 13,
                        color: _purple.withOpacity(0.8),
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            TextField(
              controller: _textCtrl,
              onChanged: _onTextChanged,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Qu\'est-ce qui pèse sur ton cœur ?',
                hintStyle: TextStyle(
                    color: _textGrey.withOpacity(0.7), fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                counterStyle: TextStyle(
                    color: _textGrey.withOpacity(0.6), fontSize: 11),
              ),
              style: const TextStyle(fontSize: 14, color: _textDark),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: GestureDetector(
                onTap: _onEnregistrer,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_purple, _pink],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                          color: _purple.withOpacity(0.30),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Enregistrer mon moment ✨',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
 
  // ── RÉPONSE JOYA ──────────────────────────────────────────────────────────
  Widget _buildJoyaResponse() => AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _isJoyaLoading
            ? Container(
                key: const ValueKey('joya-loading'),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _purple.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    _joyaAvatar(),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _purple.withOpacity(0.6)),
                    ),
                    const SizedBox(width: 10),
                    Text('Joya réfléchit…',
                        style: TextStyle(
                            fontSize: 13,
                            color: _purple.withOpacity(0.7),
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              )
            : _joyaResponse != null
                ? Container(
                    key: const ValueKey('joya-response'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        _purple.withOpacity(0.06),
                        _pink.withOpacity(0.04),
                      ]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _purple.withOpacity(0.18)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _joyaAvatar(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Joya',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _purple)),
                              const SizedBox(height: 4),
                              Text(
                                _joyaResponse!,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: _textDark,
                                    height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('joya-empty')),
      );
 
  Widget _joyaAvatar() => Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [Color(0xFFB97CF8), _purple]),
        ),
        child: const Center(
          child: Text('^_^',
              style: TextStyle(fontSize: 12, color: Colors.white)),
        ),
      );
 
  // ── STATS ROW ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow() => Row(
        children: [
          Expanded(
            child: _statCard(
              icon: Icons.local_fire_department_rounded,
              iconBg: const Color(0xFFFF6B35),
              label: 'Streak',
              value: '$_streak jours',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              icon: Icons.trending_up_rounded,
              iconBg: const Color(0xFF22C55E),
              label: 'Humeur',
              value: _avgMood,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              icon: Icons.edit_rounded,
              iconBg: _purple,
              label: 'Entrées',
              value: '$_totalEntries',
            ),
          ),
        ],
      );
 
  Widget _statCard({
    required IconData icon,
    required Color iconBg,
    required String label,
    required String value,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration:
                  BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(fontSize: 12, color: _textGrey)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _textDark)),
          ],
        ),
      );
 
  // ── WRITE BUTTON ──────────────────────────────────────────────────────────
  Widget _buildWriteButton() {
    final active = _selectedMood != -1;
    return GestureDetector(
      onTap: _goToWrite,
      child: AnimatedOpacity(
        opacity: active ? 1.0 : 0.55,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_purple, _pink],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: _purple.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ]
                : [],
          ),
          child: const Center(
            child: Text(
              'Écrire dans mon journal →',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3),
            ),
          ),
        ),
      ),
    );
  }
 
  // ── EMPTY STATE ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: const Column(
          children: [
            Text('📖', style: TextStyle(fontSize: 40)),
            SizedBox(height: 12),
            Text(
              'Ton journal est vide pour l\'instant',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textDark),
            ),
            SizedBox(height: 6),
            Text(
              'Choisis ton humeur et écris ta première entrée !',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _textGrey),
            ),
          ],
        ),
      );
   // ── LAST ENTRY ────────────────────────────────────────────────────────────
  Widget _buildLastEntry(JournalEntry entry) {
    final dateStr =
        DateFormat('EEEE d MMMM', 'fr_FR').format(entry.createdAt);
    final timeStr = DateFormat('HH:mm').format(entry.createdAt);

    Color sentimentColor;
    switch (entry.sentiment.toLowerCase()) {
      case 'positif':
        sentimentColor = const Color(0xFF22C55E);
        break;
      case 'négatif':
      case 'negatif':
        sentimentColor = const Color(0xFFEF4444);
        break;
      default:
        sentimentColor = _textGrey;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _purple.withOpacity(0.14),
            _pink.withOpacity(0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(23),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -20,
              child: _decorCircle(70, _pink.withOpacity(0.12)),
            ),
            Positioned(
              right: 28,
              bottom: -22,
              child: _decorCircle(46, _purple.withOpacity(0.10)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: entry.mood.color.withOpacity(0.14),
                        boxShadow: [
                          BoxShadow(
                            color: entry.mood.color.withOpacity(0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          entry.mood.emoji,
                          style: const TextStyle(fontSize: 25),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _capitalize(dateStr),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _textDark,
                        ),
                      ),
                    ),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7FF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    entry.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _textDark,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: sentimentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text(
                        'Sentiment : ${entry.sentiment}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sentimentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorCircle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      );

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
