import 'package:flutter/material.dart';
import 'package:wejoy/screens/service/api_service.dart';


class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}


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
  bool _isSendPressed = false;

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
    _messages.add(
      ChatMessage(
        text:
            'Salut ${widget.user?.username ?? ''} ! 😊\n\n'
            'Je suis Joya, ton assistant bien-être 💜\n\n'
            'Je suis là pour t\'aider à améliorer ta santé, ton humeur et ton quotidien. '
            'On commence quand tu veux 🌟',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final trimmedText = text.trim();

    setState(() {
      _messages.add(ChatMessage(text: trimmedText, isUser: true));
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final history = _messages
          .where((m) => m.text != trimmedText)
          .take(10)
          .map((m) => {
                'role': m.isUser ? 'user' : 'model',
                'text': m.text,
              })
          .toList();

      final data = await _api.sendChatMessage(
        message: trimmedText,
        history: history,
        userProfile: widget.user != null
            ? {
                'username': widget.user!.username,
                'memberSince': widget.user!.memberSince,
                'points': widget.user!.points,
                'interests': widget.user!.interests,
              }
            : null,
      );

      setState(() {
        _messages.add(
          ChatMessage(
            text: data['reply'] ?? 'Je n\'ai pas pu générer une réponse.',
            isUser: false,
          ),
        );
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'Oups, je rencontre un petit problème technique 😅\n\nRéessaie dans quelques secondes.',
            isUser: false,
          ),
        );
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  void _clearConversation() {
    setState(() {
      _messages.clear();
      _messages.add(
        ChatMessage(
          text:
              'Conversation réinitialisée ✨\n\nJe suis prête à t\'aider à nouveau.',
          isUser: false,
        ),
      );
    });
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

  Widget _buildFormattedText(String text, bool isUser) {
    final List<TextSpan> spans = [];
    final Color baseColor = isUser ? Colors.white : const Color(0xFF1F2937);
    final Color boldColor = isUser ? Colors.white : const Color(0xFF111827);

    text.splitMapJoin(
      RegExp(r'\*\*(.*?)\*\*'),
      onMatch: (m) {
        spans.add(
          TextSpan(
            text: m.group(1),
            style: TextStyle(fontWeight: FontWeight.w700, color: boldColor),
          ),
        );
        return '';
      },
      onNonMatch: (s) {
        if (s.isNotEmpty) {
          spans.add(TextSpan(text: s, style: TextStyle(color: baseColor)));
        }
        return '';
      },
    );

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14.5, height: 1.6),
        children: spans,
      ),
    );
  }

  Widget _reactionButton(String emoji) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () => _sendMessage(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFD63FBF).withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD63FBF).withOpacity(0.25)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFFD63FBF),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final bool isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Avatar Joya : 36×36 au lieu de 150×150 ──
          if (!isUser) ...[
            SizedBox(
              width: 70,
              height: 70,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/joyaai.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // ── Bulle limitée en largeur ──
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? const LinearGradient(
                              colors: [Color(0xFFE94057), Color(0xFF8A2BE2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isUser ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 20 : 6),
                        bottomRight: Radius.circular(isUser ? 6 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: isUser
                          ? null
                          : Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormattedText(message.text, isUser),
                        const SizedBox(height: 6),
                        Text(
                          '${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isUser ? Colors.white70 : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isUser) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _reactionButton('👍'),
                        _reactionButton('💜'),
                        _reactionButton('🔥'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          // ── Avatar utilisateur ──
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Center(
                child: Text(
                  widget.user?.avatarUrl?.isNotEmpty == true
                      ? widget.user!.avatarUrl!
                      : '👤',
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Avatar Joya dans le typing indicator : 36×36 ──
          SizedBox(
            width: 70,
            height: 70,
            child: ClipOval(
              child: Image.asset(
                'assets/images/joyaai.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                SizedBox(width: 4),
                _TypingDot(delay: 200),
                SizedBox(width: 4),
                _TypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Pose ta question...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTapDown: (_) => setState(() => _isSendPressed = true),
              onTapUp: (_) => setState(() => _isSendPressed = false),
              onTapCancel: () => setState(() => _isSendPressed = false),
              onTap: () => _sendMessage(_controller.text),
              child: AnimatedScale(
                scale: _isSendPressed ? 0.92 : 1,
                duration: const Duration(milliseconds: 120),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE94057), Color(0xFF8A2BE2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8A2BE2).withOpacity(0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsBar() {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _buildSuggestionChip(_suggestions[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        scrolledUnderElevation: 0,
        // ── titleSpacing corrigé : 0 au lieu de -50 ──
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Avatar AppBar : 38×38 au lieu de 150×150 ──
            SizedBox(
              width: 70,
              height: 70,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/joyaai.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Joya',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'En ligne',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _clearConversation,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
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
          if (_messages.length <= 1) _buildSuggestionsBar(),
          _buildInputArea(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ANIMATION POINT TYPING
// ══════════════════════════════════════════════════════════════════════════════
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

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
          color: Color.lerp(
            Colors.grey[300],
            const Color(0xFFD63FBF),
            _anim.value,
          ),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}