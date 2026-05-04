import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wejoy/models/mood_option.dart';
import 'package:wejoy/screens/service/api_service.dart';

// ── Catégories disponibles ─────────────────────────────────
const List<Map<String, String>> kCategories = [
  {'label': 'Famille',  'icon': '❤️'},
  {'label': 'Travail',  'icon': '💼'},
  {'label': 'Amis',     'icon': '👥'},
  {'label': 'Amour',    'icon': '💕'},
  {'label': 'Santé',    'icon': '🏃'},
  {'label': 'Fatigue',  'icon': '😴'},
  {'label': 'Réussite', 'icon': '🏆'},
  {'label': 'Musique',  'icon': '🎵'},
  {'label': 'Sport',    'icon': '⚽'},
  {'label': 'Voyage',   'icon': '✈️'},
];

class JournalEntryPage extends StatefulWidget {
  final MoodOption mood;

  // ── NOUVEAU : paramètres optionnels depuis JournalHomePage ────────────────
  final String? prefillContent;      // texte tapé dans le champ rapide
  final String? detectedSentiment;   // mood détecté par Gemini (badge)

  const JournalEntryPage({
    super.key,
    required this.mood,
    this.prefillContent,
    this.detectedSentiment,
  });

  @override
  State<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage>
    with TickerProviderStateMixin {

  final TextEditingController _textCtrl  = TextEditingController();
  final FocusNode             _focusNode = FocusNode();
  final ScrollController      _scroll    = ScrollController();

  final Set<String> _selectedTags = {};

  bool    _isSaving       = false;
  bool    _isAnalyzing    = false;
  String? _sentimentResult;
  String? _sentimentEmoji;
  double? _sentimentScore;
  int     _wordCount      = 0;

  Timer? _debounceTimer;

  late AnimationController _joyaCtrl;
  late Animation<double>   _joyaFloat;
  late AnimationController _sentimentCtrl;
  late Animation<double>   _sentimentFade;
  late Animation<Offset>   _sentimentSlide;

  static const Color _bgTop    = Color(0xFFFFF0F5);
  static const Color _bgBot    = Color(0xFFF3EEFF);
  static const Color _purple   = Color(0xFFA855F7);
  static const Color _pink     = Color(0xFFF472B6);
  static const Color _textDark = Color(0xFF2D1B69);
  static const Color _textGrey = Color(0xFF9B8FC4);

  static const _btnGrad = LinearGradient(
    colors: [_purple, _pink],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();

    _joyaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _joyaFloat = Tween<double>(begin: 0, end: -7).animate(
      CurvedAnimation(parent: _joyaCtrl, curve: Curves.easeInOut),
    );

    _sentimentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _sentimentFade = CurvedAnimation(
      parent: _sentimentCtrl,
      curve: Curves.easeOut,
    );

    _sentimentSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _sentimentCtrl,
      curve: Curves.easeOut,
    ));

    // ── NOUVEAU : pré-remplir le champ si on vient de JournalHomePage ────────
    if (widget.prefillContent != null && widget.prefillContent!.isNotEmpty) {
      _textCtrl.text = widget.prefillContent!;
      // Compter les mots immédiatement
      _wordCount = _textCtrl.text
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .length;
    }

    // ── NOUVEAU : pré-remplir le sentiment détecté si disponible ─────────────
    if (widget.detectedSentiment != null &&
        widget.detectedSentiment!.isNotEmpty) {
      // On mappe le mot détecté (ex "mélancolie") vers Positif/Négatif/Neutre
      final detected = widget.detectedSentiment!.toLowerCase();
      if (['joie', 'gratitude', 'sérénité', 'espoir', 'bonheur']
          .contains(detected)) {
        _sentimentResult = 'Positif';
      } else if (['tristesse', 'mélancolie', 'anxiété', 'frustration',
            'colère', 'peur', 'stress']
          .contains(detected)) {
        _sentimentResult = 'Négatif';
      } else {
        _sentimentResult = 'Neutre';
      }
      _sentimentEmoji = _emojiForSentiment(_sentimentResult!);
      // Lancer l'animation d'entrée
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sentimentCtrl.forward();
      });
    }

    _textCtrl.addListener(() {
      final words = _textCtrl.text
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .length;
      setState(() => _wordCount = words);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textCtrl.dispose();
    _focusNode.dispose();
    _scroll.dispose();
    _joyaCtrl.dispose();
    _sentimentCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyzeSentiment() async {
    if (_textCtrl.text.trim().length < 10) return;

    setState(() {
      _isAnalyzing     = true;
      _sentimentResult = null;
    });

    _sentimentCtrl.reset();

    try {
      final res = await ApiService().analyzeSentiment(_textCtrl.text.trim());

      if (!mounted) return;

      final label = res['sentiment'] ?? 'Neutre';
      final score = (res['score'] is num)
          ? (res['score'] as num).toDouble()
          : 0.5;

      setState(() {
        _sentimentResult = label;
        _sentimentScore  = score;
        _sentimentEmoji  = _emojiForSentiment(label);
        _isAnalyzing     = false;
      });

      _sentimentCtrl.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
    }
  }

  String _emojiForSentiment(String s) {
    switch (s) {
      case 'Positif': return '🌿';
      case 'Négatif': return '⚡';
      default:        return '💭';
    }
  }

  Color _colorForSentiment(String s) {
    switch (s) {
      case 'Positif': return const Color(0xFF10B981);
      case 'Négatif': return const Color(0xFFEF4444);
      default:        return const Color(0xFF9B8FC4);
    }
  }

  Color _bgForSentiment(String s) {
    switch (s) {
      case 'Positif': return const Color(0xFFD1FAE5);
      case 'Négatif': return const Color(0xFFFFE4E6);
      default:        return const Color(0xFFF3F4F6);
    }
  }

  Future<void> _saveEntry() async {
    if (_textCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Écris quelque chose d\'abord 📝'),
          backgroundColor: _purple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ApiService().createJournalEntry(
        content:        _textCtrl.text.trim(),
        moodValue:      widget.mood.value,
        tags:           _selectedTags.toList(),
        sentiment:      _sentimentResult ?? 'Neutre',
        sentimentScore: _sentimentScore,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Entrée sauvegardée ✅'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgTop, _bgBot],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateMoodRow(),
                      const SizedBox(height: 20),
                      _buildJoyaTip(),
                      const SizedBox(height: 16),
                      _buildTextArea(),
                      const SizedBox(height: 10),
                      _buildWordCount(),
                      const SizedBox(height: 20),
                      _buildSentimentBanner(),
                      const SizedBox(height: 24),
                      _buildCategoriesSection(),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── WIDGETS (inchangés) ───────────────────────────────────────────────────

  Widget _buildTopBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: _textDark),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mon Journal',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textDark),
                  ),
                  Text(
                    _cap(DateFormat('EEEE d MMMM yyyy', 'fr_FR')
                        .format(DateTime.now())),
                    style: const TextStyle(fontSize: 12, color: _textGrey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildDateMoodRow() => Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: widget.mood.color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.mood.color.withOpacity(0.35),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.mood.emoji,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'Je me sens ${widget.mood.label}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.mood.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildJoyaTip() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft:     Radius.circular(16),
                  bottomLeft:  Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _purple.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _tipForMood(widget.mood.value),
                      style: const TextStyle(
                          fontSize: 13, color: _textDark, height: 1.4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _pink.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Joya t\'écoute 💜',
                      style: TextStyle(fontSize: 10, color: _pink),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedBuilder(
            animation: _joyaFloat,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _joyaFloat.value),
              child: child,
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_purple, _pink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _purple.withOpacity(0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text('·_·',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      );

  String _tipForMood(int v) {
    switch (v) {
      case 1:  return 'C\'est okay de ne pas aller bien. Écris ce que tu ressens, sans jugement.';
      case 2:  return 'Prends une grande respiration. Raconte-moi ce qui t\'inquiète.';
      case 3:  return 'Une journée neutre, c\'est déjà de la stabilité. Qu\'est-ce qui s\'est passé ?';
      case 4:  return 'Super ! Raconte ta journée pour garder cette énergie positive 🌟';
      default: return 'Waouh, quelle énergie ! Partage ce bonheur avec moi ✨';
    }
  }

  Widget _buildTextArea() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _textCtrl,
          focusNode: _focusNode,
          maxLines: 8,
          minLines: 6,
          style: const TextStyle(
              fontSize: 14, color: _textDark, height: 1.6),
          decoration: const InputDecoration(
            hintText: 'Raconte ta journée... Joya t\'écoute 💜',
            hintStyle: TextStyle(
                color: _textGrey, fontSize: 14, height: 1.6),
            contentPadding: EdgeInsets.all(18),
            border: InputBorder.none,
          ),
          onChanged: (_) {
            if (_sentimentResult != null) {
              setState(() => _sentimentResult = null);
            }
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(seconds: 3), () {
              if (mounted &&
                  _textCtrl.text.trim().length > 20 &&
                  !_isAnalyzing) {
                _analyzeSentiment();
              }
            });
          },
        ),
      );

  Widget _buildWordCount() => Align(
        alignment: Alignment.centerRight,
        child: Text(
          '$_wordCount mots',
          style: const TextStyle(fontSize: 12, color: _textGrey),
        ),
      );

  Widget _buildSentimentBanner() {
    if (_isAnalyzing) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _purple.withOpacity(0.12),
              _pink.withOpacity(0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _purple),
            ),
            const SizedBox(width: 12),
            const Text(
              '✨ Joya analyse ton humeur...',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textDark),
            ),
          ],
        ),
      );
    }

    if (_sentimentResult != null) {
      return FadeTransition(
        opacity: _sentimentFade,
        child: SlideTransition(
          position: _sentimentSlide,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _bgForSentiment(_sentimentResult!),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _colorForSentiment(_sentimentResult!)
                    .withOpacity(0.30),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(_sentimentEmoji ?? '💭',
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analyse de Joya',
                        style: TextStyle(
                            fontSize: 11,
                            color: _textGrey,
                            fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _messageForSentiment(_sentimentResult!),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _colorForSentiment(_sentimentResult!),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _isAnalyzing ? null : _analyzeSentiment,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: _colorForSentiment(_sentimentResult!),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _purple.withOpacity(0.08),
            _pink.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Text('✨', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Commence à écrire et Joya analysera ton humeur automatiquement...',
              style: TextStyle(
                  fontSize: 13, color: _textGrey, height: 1.4),
            ),
          ),
          if (_wordCount >= 3)
            GestureDetector(
              onTap: _isAnalyzing ? null : _analyzeSentiment,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_purple, _pink]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Analyser',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _messageForSentiment(String s) {
    switch (s) {
      case 'Positif': return 'Ton texte dégage de la sérénité 🌿';
      case 'Négatif': return 'Je sens de la tension dans tes mots ⚡';
      default:        return 'Une humeur équilibrée aujourd\'hui 💭';
    }
  }

  Widget _buildCategoriesSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catégories',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _textDark),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kCategories.map((cat) {
              final selected = _selectedTags.contains(cat['label']);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedTags.remove(cat['label']);
                    } else {
                      _selectedTags.add(cat['label']!);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? _purple.withOpacity(0.12)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? _purple.withOpacity(0.50)
                          : Colors.grey.withOpacity(0.20),
                      width: 1.5,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: _purple.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cat['icon']!,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        cat['label']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected ? _purple : _textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );

  Widget _buildSaveButton() => GestureDetector(
        onTap: _isSaving ? null : _saveEntry,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: _isSaving
                ? const LinearGradient(
                    colors: [Color(0xFFD1C4E9), Color(0xFFF8BBD9)],
                  )
                : _btnGrad,
            borderRadius: BorderRadius.circular(28),
            boxShadow: _isSaving
                ? []
                : [
                    BoxShadow(
                      color: _purple.withOpacity(0.42),
                      blurRadius: 22,
                      offset: const Offset(0, 9),
                    ),
                  ],
          ),
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Sauvegarder 💾',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}