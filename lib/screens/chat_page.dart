import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wejoy/screens/service/api_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MODÈLE MESSAGE
// ══════════════════════════════════════════════════════════════════════════════
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({required this.text, required this.isUser, DateTime? time})
      : time = time ?? DateTime.now();
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE CHAT
// ══════════════════════════════════════════════════════════════════════════════
class ChatPage extends StatefulWidget {
  final UserProfile? user;
  const ChatPage({super.key, this.user});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _api = ApiService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  final List<String> _suggestions = [
    '💆 Comment méditer ?',
    '🏃 Exercice pour débutants',
    '😴 Mieux dormir',
    '🥗 Conseils nutrition',
    '😰 Gérer le stress',
    '🎯 Fixer des objectifs',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text: 'Bonjour ${widget.user?.username ?? ''} ! 👋\n\nJe suis Joya, votre assistant bien-être personnel. Je suis là pour vous aider à améliorer votre santé, votre humeur et votre qualité de vie. 🌟\n\nComment puis-je vous aider aujourd\'hui ?',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text.trim(), isUser: true));
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final token = await _api.getToken();

      final history = _messages
          .where((m) => m.text != text.trim())
          .take(10)
          .map((m) => {'role': m.isUser ? 'user' : 'model', 'text': m.text})
          .toList();

      final response = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': text.trim(),
          'history': history,
          'userProfile': widget.user != null ? {
            'username': widget.user!.username,
            'memberSince': widget.user!.memberSince,
            'points': widget.user!.points,
            'interests': widget.user!.interests,
          } : null,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add(ChatMessage(text: data['reply'], isUser: false));
          _isTyping = false;
        });
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Désolé, je rencontre un problème technique. Veuillez réessayer. 🙏',
          isUser: false,
        ));
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Parser le markdown **gras** ───────────────────────────────────────────
  Widget _buildFormattedText(String text, bool isUser) {
    final List<TextSpan> spans = [];
    final Color baseColor = isUser ? Colors.white : Colors.black87;
    final Color boldColor = isUser ? Colors.white : Colors.black;

    text.splitMapJoin(
      RegExp(r'\*\*(.*?)\*\*'),
      onMatch: (m) {
        spans.add(TextSpan(
          text: m.group(1),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: boldColor,
          ),
        ));
        return '';
      },
      onNonMatch: (s) {
        if (s.isNotEmpty) {
          spans.add(TextSpan(
            text: s,
            style: TextStyle(color: baseColor),
          ));
        }
        return '';
      },
    );

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, height: 1.6),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFD63FBF), Color(0xFF9C27B0)]),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Joya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text('En ligne', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(ChatMessage(
                  text: 'Conversation effacée. Comment puis-je vous aider ? 😊',
                  isUser: false,
                ));
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages ───────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (_isTyping && i == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessage(_messages[i]);
              },
            ),
          ),

          // ── Suggestions rapides ────────────────────────────────────
          if (_messages.length <= 1)
            Container(
              height: 44,
              color: Colors.white,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _sendMessage(_suggestions[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD63FBF).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD63FBF).withOpacity(0.3)),
                    ),
                    child: Text(
                      _suggestions[i],
                      style: const TextStyle(fontSize: 12, color: Color(0xFFD63FBF), fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ),

          // ── Input ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Posez votre question...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        hintStyle: TextStyle(fontSize: 14),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_controller.text),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFFD63FBF), Color(0xFF9C27B0)]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFD63FBF), Color(0xFF9C27B0)]),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: message.isUser ? const Color(0xFFD63FBF) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(message.isUser ? 18 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 18),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormattedText(message.text, message.isUser),
                  const SizedBox(height: 4),
                  Text(
                    '${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: message.isUser ? Colors.white60 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: Center(
                child: Text(
                  widget.user?.avatarUrl?.isNotEmpty == true ? widget.user!.avatarUrl! : '👤',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFD63FBF), Color(0xFF9C27B0)]),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                const SizedBox(width: 4),
                _TypingDot(delay: 200),
                const SizedBox(width: 4),
                _TypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animation point typing ────────────────────────────────────────────────────
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _anim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Color.lerp(Colors.grey[300], const Color(0xFFD63FBF), _anim.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}