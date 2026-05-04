import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wejoy/screens/service/api_service.dart';
import 'package:wejoy/models/mood_option.dart';

// ═══════════════════════════════════════════════════════════
//  JOURNAL TIMELINE PAGE  –  Mes entrées
// ═══════════════════════════════════════════════════════════

// ✅ Stickers PNG — identiques à la home page
const _moodStickers = [
  'assets/images/moods/mood_1_mal.png',
  'assets/images/moods/mood_2_pas_bien.png',
  'assets/images/moods/mood_3_pas_mal.png',
  'assets/images/moods/mood_4_bien.png',
  'assets/images/moods/mood_5_tres_bien.png',
];

// Fallback emoji si l'image ne charge pas
const _moodEmojiFallback = {
  1: '😢', 2: '😰', 3: '😐', 4: '🙂', 5: '🤩',
};

/// Retourne le widget sticker PNG pour une valeur d'humeur (1–5)
Widget _moodStickerWidget(int? moodValue, {double size = 40}) {
  final idx = (moodValue ?? 3) - 1;
  if (idx < 0 || idx >= _moodStickers.length) {
    return Text(_moodEmojiFallback[moodValue] ?? '😐',
        style: TextStyle(fontSize: size * 0.65));
  }
  return Image.asset(
    _moodStickers[idx],
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (_, __, ___) => Text(
      _moodEmojiFallback[moodValue] ?? '😐',
      style: TextStyle(fontSize: size * 0.65),
    ),
  );
}

class JournalTimelinePage extends StatefulWidget {
  const JournalTimelinePage({super.key});

  @override
  State<JournalTimelinePage> createState() => _JournalTimelinePageState();
}

class _JournalTimelinePageState extends State<JournalTimelinePage> {

  // ── palette ────────────────────────────────────────────
  static const Color _bg       = Color(0xFFF9EFF7);
  static const Color _purple   = Color(0xFFA855F7);
  static const Color _pink     = Color(0xFFF472B6);
  static const Color _text     = Color(0xFF2D1B69);
  static const Color _sub      = Color(0xFF9B8FC4);
  static const Color _white    = Colors.white;

  // ── state ──────────────────────────────────────────────
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _entries   = [];
  List<Map<String, dynamic>> _filtered  = [];
  bool    _loading   = true;
  String? _error;
  int     _page      = 1;
  bool    _hasMore   = true;
  bool    _loadingMore = false;

  // ── calendrier ─────────────────────────────────────────
  DateTime _selectedDay = DateTime.now();
  Set<String> _daysWithEntry = {};

  // ── recherche ──────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';

  // ── filtre humeur ──────────────────────────────────────
  int? _filterMood;

  final ScrollController _scrollCtrl = ScrollController();

  // ── mood colors (barre latérale) ───────────────────────
  static const _moodColors = {
    1: Color(0xFF6B8EAD),
    2: Color(0xFFF59E0B),
    3: Color(0xFF9B8FC4),
    4: Color(0xFF10B981),
    5: Color(0xFFF472B6),
  };

  static const _moodLabels = {
    1: 'Triste', 2: 'Anxieux', 3: 'Neutre', 4: 'Bien', 5: 'Euphorique',
  };

  @override
  void initState() {
    super.initState();
    _loadEntries(reset: true);
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
      _applyFilter();
    });
  }

  Future<void> _loadEntries({bool reset = false}) async {
    if (reset) {
      setState(() { _loading = true; _error = null; _page = 1; _hasMore = true; });
    }

    try {
      final data = await _api.getJournalEntries(page: _page, limit: 15);
      final list = List<Map<String, dynamic>>.from(
          (data['entries'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)));

      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
      final hasMore = pagination['hasMore'] == true;

      final days = <String>{};
      for (final e in list) {
        final d = _parseDate(e['createdAt']);
        if (d != null) days.add(_dayKey(d));
      }

      if (!mounted) return;
      setState(() {
        if (reset) {
          _entries = list;
          _daysWithEntry = days;
        } else {
          _entries.addAll(list);
          _daysWithEntry.addAll(days);
        }
        _hasMore = hasMore;
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() { _loadingMore = true; _page++; });
    await _loadEntries();
    if (mounted) setState(() => _loadingMore = false);
  }

  void _applyFilter() {
    final selectedKey = _dayKey(_selectedDay);

    setState(() {
      _filtered = _entries.where((e) {
        final d = _parseDate(e['createdAt']);
        final dayMatch = d != null && _dayKey(d) == selectedKey;

        final content = (e['content'] ?? '').toString().toLowerCase();
        final searchMatch = _searchQuery.isEmpty ||
            content.contains(_searchQuery);

        final moodMatch = _filterMood == null ||
            e['moodValue'] == _filterMood;

        final now = DateTime.now();
        final isToday = _dayKey(_selectedDay) == _dayKey(now);

        return (isToday || dayMatch) && searchMatch && moodMatch;
      }).toList();
    });
  }

  Future<void> _deleteEntry(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer cette entrée ?',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: Color(0xFF2D1B69))),
        content: const Text(
            'Cette action est irréversible.',
            style: TextStyle(color: Color(0xFF9B8FC4))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF9B8FC4))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _api.deleteJournalEntry(id);
      setState(() {
        _entries.removeWhere((e) => e['_id'] == id);
        _filtered.removeWhere((e) => e['_id'] == id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Entrée supprimée 🗑️'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _editEntry(Map<String, dynamic> entry) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _EditEntryPage(entry: entry, api: _api),
      ),
    );
    if (result == true) _loadEntries(reset: true);
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Color _moodColor(int? v) => _moodColors[v] ?? _sub;

  String _sentimentBg(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'positif':      return '🌿';
      case 'très positif': return '🌟';
      case 'négatif':      return '⚡';
      default:             return '💭';
    }
  }

  Color _sentimentColor(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'positif':
      case 'très positif': return const Color(0xFF10B981);
      case 'négatif':      return const Color(0xFFEF4444);
      default:             return _sub;
    }
  }

  Color _sentimentBgColor(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'positif':
      case 'très positif': return const Color(0xFFD1FAE5);
      case 'négatif':      return const Color(0xFFFFE4E6);
      default:             return const Color(0xFFF3F4F6);
    }
  }

  // ══════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildWeekCalendar(),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            const Text('Mes entrées',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: _text)),
            const Spacer(),
            // ✅ filtre humeur avec sticker PNG
            GestureDetector(
              onTap: _showMoodFilter,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _filterMood != null
                      ? _moodColor(_filterMood).withOpacity(0.15)
                      : _white,
                  borderRadius: BorderRadius.circular(12),
                  border: _filterMood != null
                      ? Border.all(color: _moodColor(_filterMood), width: 1.5)
                      : null,
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Center(
                  child: _filterMood != null
                      ? _moodStickerWidget(_filterMood, size: 32)
                      : const Icon(Icons.filter_list_rounded,
                          size: 20, color: _purple),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Container(
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(fontSize: 14, color: _text),
            decoration: InputDecoration(
              hintText: 'Rechercher...',
              hintStyle: const TextStyle(color: _sub, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: _sub, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                        _applyFilter();
                      },
                      child: const Icon(Icons.close_rounded,
                          color: _sub, size: 18),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 16),
            ),
          ),
        ),
      );

  Widget _buildWeekCalendar() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final day        = days[i];
          final isSelected = _dayKey(day) == _dayKey(_selectedDay);
          final isToday    = _dayKey(day) == _dayKey(now);
          final hasEntry   = _daysWithEntry.contains(_dayKey(day));
          final isFuture   = day.isAfter(now);

          return GestureDetector(
            onTap: isFuture ? null : () {
              setState(() => _selectedDay = day);
              _applyFilter();
            },
            child: Column(
              children: [
                Text(dayLabels[i],
                    style: TextStyle(
                        fontSize: 12, color: _sub,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [_purple, _pink],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight)
                        : null,
                    color: isSelected
                        ? null
                        : isToday
                            ? _purple.withOpacity(0.10)
                            : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected || isToday
                            ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected
                            ? _white
                            : isFuture
                                ? _sub.withOpacity(0.4)
                                : _text,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasEntry
                        ? (isSelected ? _white : _purple)
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: _purple));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 42, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _text)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadEntries(reset: true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _purple, foregroundColor: _white),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final list = _searchQuery.isEmpty && _filterMood == null
        ? _entries
        : _filtered;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _moodStickerWidget(3, size: 72),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Aucun résultat pour "$_searchQuery"'
                  : 'Aucune entrée pour ce jour',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _sub, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _purple,
      onRefresh: () => _loadEntries(reset: true),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        itemCount: list.length + (_loadingMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == list.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                  child: CircularProgressIndicator(color: _purple)),
            );
          }
          return _buildEntryCard(list[i]);
        },
      ),
    );
  }

  // ── entry card ─────────────────────────────────────────
  Widget _buildEntryCard(Map<String, dynamic> entry) {
    final id        = entry['_id']?.toString() ?? '';
    final content   = entry['content']?.toString() ?? '';
    final moodValue = entry['moodValue'] as int?;
    final sentiment = entry['sentiment']?.toString();
    final tags      = List<String>.from(entry['tags'] ?? []);
    final date      = _parseDate(entry['createdAt']);
    final color     = _moodColor(moodValue);

    final dateStr = date != null
        ? DateFormat('EEEE d MMMM', 'fr_FR').format(date)
        : '';
    final timeStr = date != null
        ? DateFormat('HH:mm').format(date)
        : '';

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded,
            color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        await _deleteEntry(id);
        return false;
      },
      child: GestureDetector(
        onTap: () => _editEntry(entry),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // barre latérale colorée
              Container(
                width: 5,
                height: 130,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ header : sticker PNG + date + heure
                      Row(
                        children: [
                          _moodStickerWidget(moodValue, size: 44),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _cap(dateStr),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _text),
                                ),
                                Text(timeStr,
                                    style: const TextStyle(
                                        fontSize: 12, color: _sub)),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _editEntry(entry);
                              if (v == 'delete') _deleteEntry(id);
                            },
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [
                                  Icon(Icons.edit_rounded,
                                      size: 18, color: Color(0xFFA855F7)),
                                  SizedBox(width: 10),
                                  Text('Modifier'),
                                ]),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  Icon(Icons.delete_rounded,
                                      size: 18, color: Colors.red),
                                  SizedBox(width: 10),
                                  Text('Supprimer',
                                      style: TextStyle(color: Colors.red)),
                                ]),
                              ),
                            ],
                            icon: const Icon(Icons.more_horiz_rounded,
                                color: _sub, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: _sub, height: 1.5),
                      ),
                      const SizedBox(height: 10),
                      if (tags.isNotEmpty)
                        Wrap(
                          spacing: 6, runSpacing: 4,
                          children: tags.map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F0F7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(t,
                                style: const TextStyle(
                                    fontSize: 11, color: _sub,
                                    fontWeight: FontWeight.w500)),
                          )).toList(),
                        ),
                      const SizedBox(height: 8),
                      if (sentiment != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _sentimentBgColor(sentiment),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_sentimentBg(sentiment)} Sentiment: $sentiment',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _sentimentColor(sentiment)),
                          ),
                        ),
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

  // ── filtre humeur — ✅ stickers PNG dans le bottom sheet ──
  void _showMoodFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrer par humeur',
                style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D1B69))),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => _filterMood = null);
                    _applyFilter();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _filterMood == null
                          ? _purple.withOpacity(0.12)
                          : const Color(0xFFF3F0F7),
                      borderRadius: BorderRadius.circular(20),
                      border: _filterMood == null
                          ? Border.all(color: _purple, width: 1.5)
                          : null,
                    ),
                    child: const Text('Tous',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D1B69))),
                  ),
                ),
                ...List.generate(5, (i) {
                  final v = i + 1;
                  final selected = _filterMood == v;
                  final mColor = _moodColor(v);
                  return GestureDetector(
                    onTap: () {
                      setState(() => _filterMood = v);
                      _applyFilter();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? mColor.withOpacity(0.12)
                            : const Color(0xFFF3F0F7),
                        borderRadius: BorderRadius.circular(20),
                        border: selected
                            ? Border.all(color: mColor, width: 1.5)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ✅ Sticker PNG au lieu d'emoji
                          _moodStickerWidget(v, size: 28),
                          const SizedBox(width: 6),
                          Text(_moodLabels[v]!,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: mColor)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ═══════════════════════════════════════════════════════════
//  EDIT ENTRY PAGE
// ═══════════════════════════════════════════════════════════

class _EditEntryPage extends StatefulWidget {
  final Map<String, dynamic> entry;
  final ApiService api;

  const _EditEntryPage({required this.entry, required this.api});

  @override
  State<_EditEntryPage> createState() => _EditEntryPageState();
}

class _EditEntryPageState extends State<_EditEntryPage> {
  static const Color _purple   = Color(0xFFA855F7);
  static const Color _pink     = Color(0xFFF472B6);
  static const Color _text     = Color(0xFF2D1B69);
  static const Color _sub      = Color(0xFF9B8FC4);
  static const Color _bgTop    = Color(0xFFFFF0F5);
  static const Color _bgBot    = Color(0xFFF3EEFF);

  late TextEditingController _ctrl;
  Set<String> _selectedTags = {};
  bool _isSaving = false;

  static const List<Map<String, String>> _categories = [
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

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.entry['content']?.toString() ?? '');
    _selectedTags = Set<String>.from(
        List<String>.from(widget.entry['tags'] ?? []));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    try {
      await widget.api.updateJournalEntry(
        widget.entry['_id']?.toString() ?? '',
        content: _ctrl.text.trim(),
        tags: _selectedTags.toList(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Entrée modifiée ✅'),
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
        SnackBar(content: Text('Erreur: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 20, color: _text),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text('Modifier l\'entrée',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _text)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16, offset: const Offset(0, 4))],
                        ),
                        child: TextField(
                          controller: _ctrl,
                          maxLines: 8, minLines: 5,
                          style: const TextStyle(
                              fontSize: 14, color: _text, height: 1.6),
                          decoration: const InputDecoration(
                            hintText: 'Modifie ton entrée...',
                            hintStyle: TextStyle(color: _sub),
                            contentPadding: EdgeInsets.all(18),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Catégories',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600,
                              color: _text)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _categories.map((cat) {
                          final sel = _selectedTags.contains(cat['label']);
                          return GestureDetector(
                            onTap: () => setState(() => sel
                                ? _selectedTags.remove(cat['label'])
                                : _selectedTags.add(cat['label']!)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel
                                    ? _purple.withOpacity(0.12)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel
                                      ? _purple.withOpacity(0.50)
                                      : Colors.grey.withOpacity(0.20),
                                  width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(cat['icon']!,
                                      style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Text(cat['label']!,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: sel
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: sel ? _purple : _text)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: _isSaving ? null : _save,
                        child: Container(
                          width: double.infinity, height: 56,
                          decoration: BoxDecoration(
                            gradient: _isSaving
                                ? const LinearGradient(colors: [
                                    Color(0xFFD1C4E9),
                                    Color(0xFFF8BBD9)])
                                : const LinearGradient(
                                    colors: [_purple, _pink]),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: _isSaving ? [] : [BoxShadow(
                              color: _purple.withOpacity(0.42),
                              blurRadius: 22,
                              offset: const Offset(0, 9))],
                          ),
                          child: Center(
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.save_rounded,
                                          color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text('Sauvegarder les modifications',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
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
}