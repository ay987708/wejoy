import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const String _baseUrl = 'http://localhost:5000';
const Color _rose   = Color(0xFFD63FBF);
const Color _violet = Color(0xFF7C3AED);
const Color _ink    = Color(0xFF0F0F1A);
const Color _slate  = Color(0xFF64748B);
const Color _snow   = Color(0xFFF8FAFC);
const Color _border = Color(0xFFEEEEF5);
const Color _green  = Color(0xFF10B981);
const List<String> _emojis = ['👍', '❤️', '😂', '😮', '😢', '🔥'];

class ChatTab extends StatefulWidget {
  final String activityId;
  final List<dynamic> members;
  final bool isGroupAdmin;
  final Function(String) onDeleteMessage;

  const ChatTab({
    super.key,
    required this.activityId,
    required this.members,
    required this.isGroupAdmin,
    required this.onDeleteMessage,
  });

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  List<dynamic> _messages    = [];
  List<dynamic> _onlineUsers = [];
  Map<String, dynamic>? _pinned;
  bool _loading     = true;
  bool _loadingMore = false;
  bool _hasMore     = true;
  int  _page        = 1;
  Timer? _timer;
  Map<String, dynamic>? _replyTo;
  String? _editingId;
  List<String> _suggestions = [];
  final _ctrl   = TextEditingController();
  final _scroll  = ScrollController();
  final _picker  = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadChat();
    _pingOnline();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadChat(silent: true);
      _pingOnline();
    });
    _scroll.addListener(_onScroll);
    _ctrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<String?> _tok() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('auth_token');
  }

  void _onScroll() {
    if (_scroll.position.pixels <= 80 && _hasMore && !_loadingMore) _loadMore();
  }

  void _onTextChanged() {
    final text = _ctrl.text;
    final match = RegExp(r'@(\w*)$').firstMatch(text);
    if (match != null) {
      final query = match.group(1)!.toLowerCase();
      setState(() {
        _suggestions = widget.members
            .map((m) => m['username'].toString())
            .where((u) => u.toLowerCase().startsWith(query))
            .take(5)
            .toList();
      });
    } else if (_suggestions.isNotEmpty) {
      setState(() => _suggestions = []);
    }
  }

  Future<void> _pingOnline() async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/activities/${widget.activityId}/online'),
        headers: {'Authorization': 'Bearer ${await _tok()}'},
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() => _onlineUsers = List.from(data['onlineUsers'] ?? []));
      }
    } catch (_) {}
  }

  Future<void> _loadChat({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/activities/${widget.activityId}?page=1&limit=30'),
        headers: {'Authorization': 'Bearer ${await _tok()}'},
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _messages    = List.from(data['chat'] ?? []);
          _hasMore     = data['chatHasMore'] == true;
          _pinned      = data['pinnedMessage'];
          _onlineUsers = List.from(data['onlineUsers'] ?? []);
          _page = 1;
        });
        if (!silent) _scrollToBottom();
      }
    } catch (_) {} finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/activities/${widget.activityId}?page=${_page + 1}&limit=30'),
        headers: {'Authorization': 'Bearer ${await _tok()}'},
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _messages = [...List.from(data['chat'] ?? []), ..._messages];
          _hasMore  = data['chatHasMore'] == true;
          _page++;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String?> _uploadImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return null;
    final token = await _tok();
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/api/upload'));
    request.headers['Authorization'] = 'Bearer $token';
    if (kIsWeb) {
      final bytes    = await picked.readAsBytes();
      final filename = picked.name.isNotEmpty ? picked.name : 'photo.jpg';
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename));
    } else {
      request.files.add(await http.MultipartFile.fromPath('image', picked.path));
    }
    final response = await request.send();
    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      return jsonDecode(body)['url'];
    }
    return null;
  }

  Future<void> _sendWithImage() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Row(children: [
        SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
        SizedBox(width: 12),
        Text('Envoi de la photo...'),
      ]),
      backgroundColor: _violet,
      duration: Duration(seconds: 10),
    ));
    final url = await _uploadImage();
    if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (url == null) return;
    await _sendMsg(imageUrl: url);
  }

  Future<void> _sendMsg({String? imageUrl}) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty && imageUrl == null) return;
    final token = await _tok();
    if (_editingId != null) {
      await http.put(
        Uri.parse('$_baseUrl/api/activities/${widget.activityId}/chat/$_editingId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );
      setState(() => _editingId = null);
    } else {
      await http.post(
        Uri.parse('$_baseUrl/api/activities/${widget.activityId}/chat'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text.isEmpty ? '📷' : text,
          if (imageUrl != null) 'imageUrl': imageUrl,
          if (_replyTo != null) 'replyTo': _replyTo,
        }),
      );
      setState(() => _replyTo = null);
    }
    _ctrl.clear();
    setState(() => _suggestions = []);
    await _loadChat();
    _scrollToBottom();
  }

  Future<void> _deleteMsg(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce message ?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await http.delete(
      Uri.parse('$_baseUrl/api/activities/${widget.activityId}/chat/$id'),
      headers: {'Authorization': 'Bearer ${await _tok()}'},
    );
    _loadChat(silent: true);
  }

  Future<void> _react(String msgId, String emoji) async {
    await http.post(
      Uri.parse('$_baseUrl/api/activities/${widget.activityId}/chat/$msgId/react'),
      headers: {'Authorization': 'Bearer ${await _tok()}', 'Content-Type': 'application/json'},
      body: jsonEncode({'emoji': emoji}),
    );
    _loadChat(silent: true);
  }

  Future<void> _pinMsg(String msgId) async {
    await http.post(
      Uri.parse('$_baseUrl/api/activities/${widget.activityId}/chat/$msgId/pin'),
      headers: {'Authorization': 'Bearer ${await _tok()}'},
    );
    _loadChat(silent: true);
  }

  // ✅ CORRIGÉ : méthode DANS la classe
  Future<void> _blockMember(String userId, String username) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Bloquer $username ?',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: const Text('Cet utilisateur sera exclu de cette activité.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Bloquer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final tok = await _tok();
    await http.post(
      Uri.parse('$_baseUrl/api/activities/${widget.activityId}/block/$userId'),
      headers: {'Authorization': 'Bearer $tok'},
    );
    _loadChat(silent: true);
  }

  // ✅ CORRIGÉ : méthode DANS la classe
  Widget _opt(IconData icon, String label, Color color, VoidCallback onTap) =>
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(label,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: color)),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  // ✅ CORRIGÉ : méthode DANS la classe avec isGroupAdmin utilisé
  void _showOptions(Map<String, dynamic> m) {
    final isOwn    = m['isOwn'] == true;
    final msgId    = m['id']?.toString() ?? '';
    final userId   = m['userId']?.toString() ?? '';
    final username = m['username'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Poignée
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),

          // ── Emojis rapides ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _emojis.map((e) => GestureDetector(
              onTap: () { Navigator.pop(context); _react(msgId, e); },
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: _snow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border)),
                child: Center(
                    child: Text(e, style: const TextStyle(fontSize: 22)))),
            )).toList(),
          ),
          const SizedBox(height: 8),
          const Divider(),

          // ── Répondre (tout le monde) ───────────────────────────────
          _opt(Icons.reply_rounded, 'Répondre', _violet, () {
            Navigator.pop(context);
            setState(() => _replyTo = {
              'messageId': msgId,
              'username':  username,
              'text':      m['text'],
            });
          }),

          // ── Épingler (admin/créateur seulement) ────────────────────
          if (widget.isGroupAdmin)
            _opt(Icons.push_pin_rounded, 'Épingler',
                const Color(0xFFF59E0B), () {
              Navigator.pop(context);
              _pinMsg(msgId);
            }),

          // ── Modifier (son propre message) ──────────────────────────
          if (isOwn)
            _opt(Icons.edit_rounded, 'Modifier', _rose, () {
              Navigator.pop(context);
              setState(() {
                _editingId = msgId;
                _ctrl.text = m['text'] ?? '';
              });
            }),

          // ── Retirer son propre message ─────────────────────────────
          if (isOwn)
            _opt(Icons.delete_outline_rounded, 'Retirer mon message',
                Colors.red, () {
              Navigator.pop(context);
              _deleteMsg(msgId);
            }),

          // ── Supprimer message d'un autre (admin/créateur) ──────────
          if (!isOwn && widget.isGroupAdmin)
            _opt(Icons.delete_forever_rounded, 'Supprimer (modération)',
                Colors.red, () {
              Navigator.pop(context);
              widget.onDeleteMessage(msgId);
              _loadChat(silent: true);
            }),

          // ── Bloquer le membre (admin/créateur, pas soi-même) ───────
          if (!isOwn && widget.isGroupAdmin)
            _opt(Icons.block_rounded, 'Bloquer $username', Colors.orange, () {
              Navigator.pop(context);
              _blockMember(userId, username);
            }),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _rose));
    }
    return Container(color: _snow, child: Column(children: [
      if (_onlineUsers.isNotEmpty) _buildOnlineBar(),
      if (_pinned != null) _buildPinnedBar(),
      Expanded(child: _messages.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _messages.length +
                  (_loadingMore ? 1 : 0) +
                  (_hasMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (_hasMore && i == 0) return _buildLoadMoreBtn();
                if (_loadingMore && i == (_hasMore ? 1 : 0)) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: _rose, strokeWidth: 2)));
                }
                final offset = (_hasMore ? 1 : 0) + (_loadingMore ? 1 : 0);
                final mi   = i - offset;
                final m    = _messages[mi];
                final prev = mi > 0 ? _messages[mi - 1] : null;
                return Column(children: [
                  if (_shouldShowDate(m, prev)) _buildDateSep(m['createdAt']),
                  _buildBubble(m),
                ]);
              },
            )),
      if (_suggestions.isNotEmpty) _buildMentionSuggestions(),
      if (_replyTo != null) _buildReplyPreview(),
      if (_editingId != null) _buildEditPreview(),
      _buildInputBar(),
    ]));
  }

  Widget _buildOnlineBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    color: Colors.white,
    child: Row(children: [
      Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text('${_onlineUsers.length} en ligne',
          style: const TextStyle(
              fontSize: 12, color: _green, fontWeight: FontWeight.w600)),
      const SizedBox(width: 8),
      Expanded(
          child: Text(
        _onlineUsers.map((u) => u['username']).join(', '),
        style: TextStyle(fontSize: 11, color: _slate.withOpacity(0.7)),
        overflow: TextOverflow.ellipsis,
      )),
    ]),
  );

  Widget _buildPinnedBar() => Container(
    margin: const EdgeInsets.all(8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: _violet.withOpacity(0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border(left: BorderSide(color: _violet, width: 3)),
    ),
    child: Row(children: [
      const Icon(Icons.push_pin_rounded, size: 16, color: _violet),
      const SizedBox(width: 8),
      Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Message épinglé',
            style: TextStyle(
                fontSize: 10, color: _violet, fontWeight: FontWeight.w600)),
        Text(_pinned!['text'] ?? '',
            style: TextStyle(fontSize: 12, color: _slate.withOpacity(0.8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ])),
    ]),
  );

  Widget _buildEmpty() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: _rose.withOpacity(0.08), shape: BoxShape.circle),
        child: Icon(Icons.chat_bubble_outline_rounded,
            size: 40, color: _rose.withOpacity(0.4)),
      ),
      const SizedBox(height: 16),
      const Text('Commencez la conversation !',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _slate)),
      const SizedBox(height: 6),
      Text('Soyez le premier à écrire',
          style: TextStyle(fontSize: 13, color: _slate.withOpacity(0.5))),
    ]),
  );

  Widget _buildLoadMoreBtn() => TextButton(
      onPressed: _loadMore,
      child: Text('Charger les anciens messages',
          style: TextStyle(fontSize: 12, color: _slate.withOpacity(0.7))));

  bool _shouldShowDate(Map m, Map? prev) {
    if (prev == null) return true;
    try {
      final d1 = DateTime.parse(m['createdAt'].toString()).toLocal();
      final d2 = DateTime.parse(prev['createdAt'].toString()).toLocal();
      return d1.day != d2.day || d1.month != d2.month;
    } catch (_) {
      return false;
    }
  }

  String _dateLbl(dynamic dateStr) {
    try {
      final d    = DateTime.parse(dateStr.toString()).toLocal();
      final now  = DateTime.now();
      final diff = now.difference(d);
      if (diff.inDays == 0) return "Aujourd'hui";
      if (diff.inDays == 1) return "Hier";
      return '${d.day} ${[
        'Jan','Fév','Mars','Avr','Mai','Juin',
        'Juil','Août','Sep','Oct','Nov','Déc'
      ][d.month - 1]}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildDateSep(dynamic dateStr) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(children: [
      Expanded(child: Divider(color: _border)),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border)),
        child: Text(_dateLbl(dateStr),
            style: TextStyle(
                fontSize: 11,
                color: _slate.withOpacity(0.7),
                fontWeight: FontWeight.w500)),
      ),
      Expanded(child: Divider(color: _border)),
    ]),
  );

  Widget _buildBubble(Map<String, dynamic> m) {
    final isOwn     = m['isOwn'] == true;
    final deleted   = m['deleted'] == true;
    final edited    = m['edited'] == true;
    final pinned    = m['pinned'] == true;
    final replyTo   = m['replyTo'];
    final reactions = List<dynamic>.from(m['reactions'] ?? []);
    final readBy    = m['readBy'] ?? 0;
    final mentions  = List<String>.from(m['mentions'] ?? []);
    final msgId     = m['id']?.toString() ?? '';
    String? timeStr;
    try {
      final d = DateTime.parse(m['createdAt'].toString()).toLocal();
      timeStr = '${d.hour}h${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    return GestureDetector(
      onLongPress:    deleted ? null : () => _showOptions(m),
      onSecondaryTap: deleted ? null : () => _showOptions(m),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isOwn) ...[
              CircleAvatar(
                  radius: 15,
                  backgroundColor: _rose.withOpacity(0.12),
                  child: Text((m['username'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _rose))),
              const SizedBox(width: 8),
            ],
            Flexible(
                child: Column(
              crossAxisAlignment:
                  isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isOwn)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(m['username'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: _ink)),
                      if (_onlineUsers
                          .any((u) => u['username'] == m['username'])) ...[
                        const SizedBox(width: 4),
                        Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                color: _green, shape: BoxShape.circle)),
                      ],
                    ]),
                  ),
                // Bulle
                Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: deleted
                        ? Colors.grey[100]
                        : isOwn
                            ? _rose
                            : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(16),
                      topRight:    const Radius.circular(16),
                      bottomLeft:  Radius.circular(isOwn ? 16 : 4),
                      bottomRight: Radius.circular(isOwn ? 4 : 16),
                    ),
                    boxShadow: deleted
                        ? []
                        : [
                            BoxShadow(
                                color: (isOwn ? _rose : Colors.black)
                                    .withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                  ),
                  child:
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (pinned)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.push_pin_rounded,
                              size: 11,
                              color: isOwn ? Colors.white60 : _violet),
                          const SizedBox(width: 3),
                          Text('Épinglé',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: isOwn ? Colors.white60 : _violet,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    if (replyTo != null && replyTo['username'] != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 7),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isOwn
                              ? Colors.white.withOpacity(0.2)
                              : _rose.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                              left: BorderSide(
                                  color: isOwn ? Colors.white54 : _rose,
                                  width: 2)),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(replyTo['username'],
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isOwn ? Colors.white70 : _rose)),
                              Text(replyTo['text'] ?? '',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: isOwn
                                          ? Colors.white60
                                          : _slate.withOpacity(0.7)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ]),
                      ),
                    if (deleted)
                      Text('🚫 Message supprimé',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[400],
                              fontStyle: FontStyle.italic))
                    else
                      _buildTextWithMentions(m['text'] ?? '', isOwn, mentions),
                    if (!deleted &&
                        m['imageUrl'] != null &&
                        m['imageUrl'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(m['imageUrl'],
                              width: 220,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox()),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      if (edited)
                        Text('modifié  ',
                            style: TextStyle(
                                fontSize: 9,
                                color: isOwn
                                    ? Colors.white54
                                    : _slate.withOpacity(0.4),
                                fontStyle: FontStyle.italic)),
                      Text(timeStr ?? '',
                          style: TextStyle(
                              fontSize: 10,
                              color: isOwn
                                  ? Colors.white60
                                  : _slate.withOpacity(0.4))),
                      if (isOwn && readBy > 0) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.done_all_rounded,
                            size: 12,
                            color: readBy > 1 ? _green : Colors.white60),
                      ],
                    ]),
                  ]),
                ),
                // Réactions
                if (reactions.where((r) => r['count'] > 0).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                        spacing: 4,
                        children: reactions
                            .where((r) => r['count'] > 0)
                            .map<Widget>((r) => GestureDetector(
                                  onTap: () => _react(msgId, r['emoji']),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: r['reactedByMe'] == true
                                          ? _rose.withOpacity(0.1)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: r['reactedByMe'] == true
                                              ? _rose
                                              : _border),
                                    ),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(r['emoji'],
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                          const SizedBox(width: 3),
                                          Text('${r['count']}',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: r['reactedByMe'] ==
                                                          true
                                                      ? _rose
                                                      : _slate)),
                                        ]),
                                  ),
                                ))
                            .toList()),
                  ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTextWithMentions(
      String text, bool isOwn, List<String> mentions) {
    if (mentions.isEmpty) {
      return Text(text,
          style: TextStyle(
              fontSize: 13,
              color: isOwn ? Colors.white : _ink,
              height: 1.4));
    }
    final spans = <TextSpan>[];
    final parts = text.split(RegExp(r'(@\w+)'));
    for (final part in parts) {
      if (part.startsWith('@') && mentions.contains(part.substring(1))) {
        spans.add(TextSpan(
            text: part,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isOwn ? Colors.yellow[200] : _violet)));
      } else {
        spans.add(TextSpan(
            text: part,
            style: TextStyle(
                fontSize: 13,
                color: isOwn ? Colors.white : _ink,
                height: 1.4)));
      }
    }
    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildMentionSuggestions() => Container(
    color: Colors.white,
    constraints: const BoxConstraints(maxHeight: 160),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: _suggestions
          .map((u) => ListTile(
                dense: true,
                leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: _rose.withOpacity(0.12),
                    child: Text(u[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12,
                            color: _rose,
                            fontWeight: FontWeight.w700))),
                title: Text('@$u',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                onTap: () {
                  final text    = _ctrl.text;
                  final newText = text.replaceAll(RegExp(r'@\w*$'), '@$u ');
                  _ctrl.text   = newText;
                  _ctrl.selection = TextSelection.fromPosition(
                      TextPosition(offset: newText.length));
                  setState(() => _suggestions = []);
                },
              ))
          .toList(),
    ),
  );

  Widget _buildReplyPreview() => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
        color: _rose.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: _rose, width: 3))),
    child: Row(children: [
      const Icon(Icons.reply_rounded, size: 15, color: _rose),
      const SizedBox(width: 8),
      Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Répondre à ${_replyTo!['username']}',
            style: const TextStyle(
                fontSize: 11, color: _rose, fontWeight: FontWeight.w600)),
        Text(_replyTo!['text'] ?? '',
            style:
                TextStyle(fontSize: 11, color: _slate.withOpacity(0.7)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ])),
      GestureDetector(
          onTap: () => setState(() => _replyTo = null),
          child: Icon(Icons.close_rounded,
              size: 15, color: _slate.withOpacity(0.5))),
    ]),
  );

  Widget _buildEditPreview() => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
        color: _violet.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: _violet, width: 3))),
    child: Row(children: [
      const Icon(Icons.edit_rounded, size: 14, color: _violet),
      const SizedBox(width: 8),
      const Expanded(
          child: Text('Modification en cours',
              style: TextStyle(
                  fontSize: 12,
                  color: _violet,
                  fontWeight: FontWeight.w600))),
      GestureDetector(
          onTap: () => setState(() { _editingId = null; _ctrl.clear(); }),
          child: Icon(Icons.close_rounded,
              size: 15, color: _slate.withOpacity(0.5))),
    ]),
  );

  Widget _buildInputBar() => Container(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
    decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ]),
    child: Row(children: [
      GestureDetector(
        onTap: _sendWithImage,
        child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: _snow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border)),
            child: const Icon(Icons.image_rounded, color: _rose, size: 20)),
      ),
      const SizedBox(width: 8),
      Expanded(
          child: TextField(
        controller: _ctrl,
        style: const TextStyle(fontSize: 13, color: _ink),
        maxLines: 3,
        minLines: 1,
        decoration: InputDecoration(
          hintText: _editingId != null
              ? 'Modifier...'
              : 'Message... (@username pour mentionner)',
          hintStyle:
              TextStyle(color: _slate.withOpacity(0.4), fontSize: 12),
          filled: true,
          fillColor: _snow,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: _rose, width: 1.5)),
        ),
      )),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () => _sendMsg(),
        child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                gradient:
                    const LinearGradient(colors: [_rose, _violet]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: _rose.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]),
            child: Icon(
                _editingId != null
                    ? Icons.check_rounded
                    : Icons.send_rounded,
                color: Colors.white,
                size: 18)),
      ),
    ]),
  );
} // ← FIN de _ChatTabState