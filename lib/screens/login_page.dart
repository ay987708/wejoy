import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:wejoy/screens/service/admin_api_service.dart';
import 'package:wejoy/screens/service/api_service.dart';
import 'package:wejoy/screens/admin/admin_shell.dart';
import 'package:wejoy/screens/auth/otp_reset_screen.dart';
import 'dart:convert';
import 'package:wejoy/screens/home_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ── Changez selon votre environnement ─────────────────────────────────────────
// Émulateur Android  → http://10.0.2.2:5000
// Appareil physique  → http://192.168.X.X:5000
// Web / iOS          → http://localhost:5000
const String _baseUrl = 'http://localhost:5000';

// ═══════════════════════════════════════════════════════════════════════════════
// TOAST
// ═══════════════════════════════════════════════════════════════════════════════

enum ToastType { success, error, warning, info }

class ModernToast {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    required ToastType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    _currentEntry?.remove();
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        title: title,
        message: message,
        type: type,
        onDismiss: () {
          entry.remove();
          _currentEntry = null;
        },
        duration: duration,
      ),
    );
    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String title, message;
  final ToastType type;
  final VoidCallback onDismiss;
  final Duration duration;

  const _ToastWidget({
    required this.title,
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5)));
    _controller.forward();
    Future.delayed(widget.duration, () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() async {
    if (!mounted) return;
    _controller.duration = const Duration(milliseconds: 300);
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _ToastConfig get _config {
    switch (widget.type) {
      case ToastType.success:
        return _ToastConfig(
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF00C853),
            accentColor: const Color(0xFF00C853),
            bgColor: const Color(0xFF1A2E1A),
            progressColor: const Color(0xFF00C853));
      case ToastType.error:
        return _ToastConfig(
            icon: Icons.cancel_rounded,
            iconColor: const Color(0xFFFF1744),
            accentColor: const Color(0xFFFF1744),
            bgColor: const Color(0xFF2E1A1A),
            progressColor: const Color(0xFFFF1744));
      case ToastType.warning:
        return _ToastConfig(
            icon: Icons.warning_rounded,
            iconColor: const Color(0xFFFFAB00),
            accentColor: const Color(0xFFFFAB00),
            bgColor: const Color(0xFF2E2A1A),
            progressColor: const Color(0xFFFFAB00));
      case ToastType.info:
        return _ToastConfig(
            icon: Icons.info_rounded,
            iconColor: const Color(0xFF2979FF),
            accentColor: const Color(0xFF2979FF),
            bgColor: const Color(0xFF1A1A2E),
            progressColor: const Color(0xFF2979FF));
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 24,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: _dismiss,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: config.bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: config.accentColor.withOpacity(0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                        color: config.accentColor.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8)),
                    BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                  color: config.accentColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(config.icon,
                                  color: config.iconColor, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.title,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15)),
                                    const SizedBox(height: 3),
                                    Text(widget.message,
                                        style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 13,
                                            height: 1.4)),
                                  ]),
                            ),
                            GestureDetector(
                                onTap: _dismiss,
                                child: Icon(Icons.close_rounded,
                                    color: Colors.white.withOpacity(0.4),
                                    size: 18)),
                          ]),
                    ),
                    _ProgressBar(
                        duration: widget.duration, color: config.progressColor),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatefulWidget {
  final Duration duration;
  final Color color;

  const _ProgressBar({required this.duration, required this.color});

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => LinearProgressIndicator(
          value: 1 - _ctrl.value,
          minHeight: 3,
          backgroundColor: widget.color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation(widget.color.withOpacity(0.8)),
        ),
      );
}

class _ToastConfig {
  final IconData icon;
  final Color iconColor, accentColor, bgColor, progressColor;

  _ToastConfig({
    required this.icon,
    required this.iconColor,
    required this.accentColor,
    required this.bgColor,
    required this.progressColor,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOADING OVERLAY
// ═══════════════════════════════════════════════════════════════════════════════

class ModernLoadingOverlay {
  static OverlayEntry? _entry;

  static void show(BuildContext context, {String? message}) {
    _entry?.remove();
    _entry = OverlayEntry(builder: (_) => _ModernLoadingWidget(message: message));
    Overlay.of(context).insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class _ModernLoadingWidget extends StatelessWidget {
  final String? message;

  const _ModernLoadingWidget({this.message});

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: Center(
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              builder: (context, double value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.5), blurRadius: 40)
                  ],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(children: [
                      const CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation(Color(0xFFAB47BC))),
                      Center(
                          child: Icon(Icons.favorite,
                              color: const Color(0xFFAB47BC).withOpacity(0.5),
                              size: 20)),
                    ]),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(message!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ],
                ]),
              ),
            ),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODERN TEXT FIELD
// ═══════════════════════════════════════════════════════════════════════════════

class ModernTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final VoidCallback? toggleObscure;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final Color? accentColor;

  const ModernTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.toggleObscure,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.accentColor,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField> {
  late FocusNode _focusNode;
  bool _hasError = false;
  String? _errorText;

  Color get accent => widget.accentColor ?? const Color(0xFFE91E8C);

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _validate(String value) {
    if (widget.validator != null) {
      final error = widget.validator!(value);
      setState(() {
        _hasError = error != null;
        _errorText = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: _focusNode.hasFocus
              ? [
                  BoxShadow(
                      color: accent.withOpacity(0.15),
                      blurRadius: 8,
                      spreadRadius: 2)
                ]
              : [],
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscure,
          keyboardType: widget.keyboardType,
          onChanged: _validate,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(widget.icon,
                color: _focusNode.hasFocus ? accent : Colors.grey.shade400,
                size: 20),
            suffixIcon: widget.toggleObscure != null
                ? IconButton(
                    icon: Icon(
                      widget.obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _focusNode.hasFocus ? accent : Colors.grey.shade400,
                      size: 20,
                    ),
                    onPressed: widget.toggleObscure)
                : null,
            filled: true,
            fillColor: _hasError ? const Color(0xFFFEE7E7) : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accent, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFF5252), width: 2),
            ),
          ),
        ),
      ),
      if (_hasError)
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 6),
          child: Text(_errorText ?? '',
              style: const TextStyle(
                  color: Color(0xFFFF5252),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VALIDATORS
// ═══════════════════════════════════════════════════════════════════════════════

class Validators {
  static String? validateEmail(String? v) {
    if (v == null || v.isEmpty) return "L'email est requis";
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v))
      return "Format d'email invalide";
    return null;
  }

  static String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return "Le mot de passe est requis";
    if (v.length < 6) return "Minimum 6 caractères";
    return null;
  }

  static String? validateName(String? v) {
    if (v == null || v.isEmpty) return "Le nom est requis";
    if (v.length < 2) return "Nom trop court";
    return null;
  }

  static String? validateConfirmPassword(String? v, String p) {
    if (v == null || v.isEmpty) return "Confirmation requise";
    if (v != p) return "Les mots de passe ne correspondent pas";
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SOCIAL AUTH SERVICE — Google uniquement
// ═══════════════════════════════════════════════════════════════════════════════

class SocialAuthService {
  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      ModernLoadingOverlay.show(context, message: "Connexion Google...");
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            '1029141415382-bamssovk0894aq5us0qoaobt6gh3b7eb.apps.googleusercontent.com',
        scopes: ['email'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        ModernLoadingOverlay.hide();
        return;
      }
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/social-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': 'google',
          'name': account.displayName,
          'email': account.email,
          'avatar': account.photoUrl,
          'socialId': account.id,
        }),
      );
      final data = jsonDecode(response.body);
      ModernLoadingOverlay.hide();
      if (response.statusCode == 200) {
        final api = ApiService();
        await api.saveToken(data['token']);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomePage()));
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      ModernLoadingOverlay.hide();
      ModernToast.show(context,
          title: "Erreur Google",
          message: e.toString(),
          type: ToastType.error);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LEFT PANEL
// ═══════════════════════════════════════════════════════════════════════════════

class _LeftPanel extends StatelessWidget {
  const _LeftPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3E8FF), Color(0xFFFCE4EC), Color(0xFFEDE7F6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(children: [
        Positioned(
            top: -40,
            left: -40,
            child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFAB47BC).withOpacity(0.08)))),
        Positioned(
            bottom: 80,
            right: -30,
            child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE91E8C).withOpacity(0.07)))),
        LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Logo ──────────────────────────────────────────
                      Row(children: [
                        Image.asset(
                          'assets/images/logowejoy.png',
                          width: 80,
                          height: 80,
                          // FIX: fallback si l'image est absente
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7B2FBE), Color(0xFFE91E8C)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.favorite_rounded,
                                color: Colors.white, size: 38),
                          ),
                        ),
                        const SizedBox(width: 10),
                        RichText(
                          text: const TextSpan(children: [
                            TextSpan(
                                text: 'WE',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1A1A2E),
                                    letterSpacing: 1)),
                            TextSpan(
                                text: 'JOY',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFE91E8C),
                                    letterSpacing: 1)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 40),
                      const Text('Organize.',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A2E),
                              height: 1.2)),
                      const Text('Connect.',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A2E),
                              height: 1.2)),
                      RichText(
                          text: const TextSpan(children: [
                        TextSpan(
                            text: 'Enjoy ',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFE91E8C),
                                height: 1.2)),
                        TextSpan(
                            text: 'together.',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A1A2E),
                                height: 1.2)),
                      ])),
                      const SizedBox(height: 12),
                      Text(
                        'WEJOY helps you plan activities,\nshare moments and enjoy life\nwith the people you care about.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.6),
                      ),
                      const SizedBox(height: 24),
                      const _GroupIllustration(),
                      const Spacer(),
                      Text('© 2024 WEJOY. All rights reserved.',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade400)),
                      const SizedBox(height: 3),
                      Text('v1.0.0',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _GroupIllustration extends StatelessWidget {
  const _GroupIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 155,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: LinearGradient(colors: [
                  const Color(0xFFE91E8C).withOpacity(0.15),
                  const Color(0xFFAB47BC).withOpacity(0.10),
                ]),
              ),
            )),
        Positioned(
            top: 8,
            left: 0,
            child: _IconBubble(
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFFAB47BC))),
        Positioned(
            top: 0,
            left: 48,
            child: _IconBubble(
                icon: Icons.group_rounded, color: const Color(0xFF7C3AED))),
        Positioned(
            top: 6,
            right: 8,
            child: _IconBubble(
                icon: Icons.sports_esports_rounded,
                color: const Color(0xFFE91E8C))),
        Positioned(
          bottom: 6,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _PersonAvatar(
                  bodyColor: const Color(0xFF7C3AED),
                  skinColor: const Color(0xFFC084FC),
                  width: 44,
                  height: 72),
              const SizedBox(width: 6),
              _PersonAvatar(
                  bodyColor: const Color(0xFFEC4899),
                  skinColor: const Color(0xFFF9A8D4),
                  width: 52,
                  height: 86),
              const SizedBox(width: 6),
              _PersonAvatar(
                  bodyColor: const Color(0xFF6D28D9),
                  skinColor: const Color(0xFFA78BFA),
                  width: 44,
                  height: 72),
            ],
          ),
        ),
      ]),
    );
  }
}

class _PersonAvatar extends StatelessWidget {
  final Color bodyColor, skinColor;
  final double width, height;

  const _PersonAvatar({
    required this.bodyColor,
    required this.skinColor,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final headSize = width * 0.55;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: headSize,
        height: headSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: skinColor,
          boxShadow: [
            BoxShadow(
                color: skinColor.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
      ),
      const SizedBox(height: 3),
      Container(
        width: width,
        height: height * 0.55,
        decoration: BoxDecoration(
          color: bodyColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(width / 2),
            topRight: Radius.circular(width / 2),
            bottomLeft: Radius.circular(width / 5),
            bottomRight: Radius.circular(width / 5),
          ),
          boxShadow: [
            BoxShadow(
                color: bodyColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
      ),
    ]);
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBubble({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Icon(icon, color: color, size: 18),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADMIN LOGIN DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class _AdminLoginDialog extends StatefulWidget {
  final AdminApiService adminApiService;

  const _AdminLoginDialog({required this.adminApiService});

  @override
  State<_AdminLoginDialog> createState() => _AdminLoginDialogState();
}

class _AdminLoginDialogState extends State<_AdminLoginDialog> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = 'Remplissez tous les champs.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final ok = await widget.adminApiService.login(email, password);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminShell()),
          (route) => false,
        );
      } else {
        setState(() {
          _loading = false;
          _errorMsg = 'Email ou mot de passe incorrect.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMsg =
            'Impossible de contacter le serveur.\nVérifiez votre connexion.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFA855F7).withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 20))
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7B2FBE), Color(0xFFE91E8C)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFA855F7).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6))
              ],
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('Espace Administrateur',
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          Text('Connectez-vous à votre compte admin',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          if (_errorMsg != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFF5252).withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFFF5252), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_errorMsg!,
                      style: const TextStyle(
                          color: Color(0xFFFF5252),
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          ModernTextField(
            controller: _emailCtrl,
            hint: 'Email administrateur',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            accentColor: const Color(0xFFA855F7),
          ),
          const SizedBox(height: 14),
          ModernTextField(
            controller: _passCtrl,
            hint: 'Mot de passe',
            icon: Icons.lock_outline,
            obscure: _obscure,
            toggleObscure: () => setState(() => _obscure = !_obscure),
            accentColor: const Color(0xFFA855F7),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF7B2FBE), Color(0xFFE91E8C)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFA855F7).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Text('Se connecter',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            child: Text('Annuler',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOGIN PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  bool isLogin = true;
  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool isLoading = false;
  bool _rememberMe = false;

  final fullnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  Future<void> _checkIfLoggedIn() async {
    final token = await _apiService.getToken();
    if (token != null && mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  @override
  void dispose() {
    fullnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void _showToast({
    required String title,
    required String message,
    required ToastType type,
  }) =>
      ModernToast.show(context, title: title, message: message, type: type);

  void validateAndSubmit() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      if (!isLogin) {
        await registerUser(fullnameController.text.trim(),
            emailController.text.trim(), passwordController.text.trim());
      } else {
        await loginUser(
            emailController.text.trim(), passwordController.text.trim());
      }
    }
  }

  Future<void> registerUser(
      String username, String email, String password) async {
    setState(() => isLoading = true);
    ModernLoadingOverlay.show(context, message: "Création du compte...");
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
                {'username': username, 'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      ModernLoadingOverlay.hide();
      if (response.statusCode == 201) {
        _showToast(
            title: "Compte créé !",
            message: data['message'] ?? "Bienvenue sur WeJoy 🎉",
            type: ToastType.success);
        setState(() => isLogin = true);
      } else {
        _showToast(
            title: "Inscription échouée",
            message: data['message'] ?? "Une erreur est survenue.",
            type: ToastType.error);
      }
    } catch (e) {
      ModernLoadingOverlay.hide();
      _showToast(
          title: "Erreur",
          message: "Impossible de contacter le serveur.",
          type: ToastType.error);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loginUser(String email, String password) async {
    setState(() => isLoading = true);
    ModernLoadingOverlay.show(context, message: "Connexion en cours...");
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      ModernLoadingOverlay.hide();
      if (response.statusCode == 200) {
        await _apiService.saveToken(data['token']);
        _showToast(
            title: "Connecté !",
            message: "Bon retour sur WeJoy 👋",
            type: ToastType.success);
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomePage()));
      } else {
        _showToast(
            title: "Connexion refusée",
            message: data['message'] ?? "Email ou mot de passe incorrect.",
            type: ToastType.error);
      }
    } catch (e) {
      ModernLoadingOverlay.hide();
      _showToast(
          title: "Erreur",
          message: "Impossible de contacter le serveur.",
          type: ToastType.error);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showToast(
          title: "Email requis",
          message: "Entrez votre email dans le champ ci-dessus.",
          type: ToastType.warning);
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showToast(
          title: "Email invalide",
          message: "Format d'email incorrect.",
          type: ToastType.warning);
      return;
    }

    ModernLoadingOverlay.show(context, message: "Envoi du code...");
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/auth/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));

      ModernLoadingOverlay.hide();
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showToast(
            title: "Email envoyé !",
            message: "Vérifiez votre boîte mail pour le code OTP.",
            type: ToastType.success);
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => OtpResetScreen(email: email)));
      } else {
        _showToast(
            title: "Erreur",
            message: data['message'] ?? "Une erreur est survenue.",
            type: ToastType.error);
      }
    } catch (e) {
      ModernLoadingOverlay.hide();
      String msg = "Impossible de contacter le serveur.";
      if (e.toString().contains('TimeoutException')) {
        msg = "Le serveur ne répond pas (timeout).";
      } else if (e.toString().contains('SocketException')) {
        msg = "Pas de connexion réseau.";
      }
      _showToast(title: "Erreur réseau", message: msg, type: ToastType.error);
    }
  }

  void _openAdminLoginDialog() {
    final adminApiService = context.read<AdminApiService>();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _AdminLoginDialog(adminApiService: adminApiService),
    );
  }

  // ── RIGHT PANEL: LOGIN ────────────────────────────────────────────────────

  Widget _buildLoginPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Welcome Back 👋',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 6),
          Text('Login to continue to your account',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          const SizedBox(height: 32),

          const _FieldLabel('Email'),
          const SizedBox(height: 8),
          ModernTextField(
            controller: emailController,
            hint: "Enter your email",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 18),

          const _FieldLabel('Password'),
          const SizedBox(height: 8),
          ModernTextField(
            controller: passwordController,
            hint: "Enter your password",
            icon: Icons.lock_outline,
            obscure: obscurePassword,
            toggleObscure: () =>
                setState(() => obscurePassword = !obscurePassword),
            validator: Validators.validatePassword,
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    activeColor: const Color(0xFFE91E8C),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Remember me',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ]),
              GestureDetector(
                onTap: forgotPassword,
                child: const Text('Forgot Password?',
                    style: TextStyle(
                        color: Color(0xFFE91E8C),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 28),

          _GradientButton(
              label: 'Login',
              onPressed: isLoading ? null : validateAndSubmit,
              isLoading: isLoading),
          const SizedBox(height: 24),

          // ── Séparateur ─────────────────────────────────────────────────
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text("OR",
                  style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 20),

          // ── Google uniquement ──────────────────────────────────────────
          _SocialLoginButton(
            icon: Icons.g_mobiledata,
            iconColor: const Color(0xFFDB4437),
            label: 'Continue with Google',
            onPressed: () => SocialAuthService.signInWithGoogle(context),
          ),
          const SizedBox(height: 28),

          // ── Admin ──────────────────────────────────────────────────────
          GestureDetector(
            onTap: _openAdminLoginDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF7B2FBE), Color(0xFFE91E8C)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFAB47BC).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Espace Administrateur',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Colors.white)),
                        SizedBox(height: 2),
                        Text('Accédez à votre tableau de bord',
                            style:
                                TextStyle(fontSize: 12, color: Colors.white70)),
                      ]),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 13, color: Colors.white),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 28),

          Center(
            child: GestureDetector(
              onTap: () => setState(() => isLogin = false),
              child: RichText(
                text: const TextSpan(children: [
                  TextSpan(
                      text: "Don't have an account? ",
                      style:
                          TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                  TextSpan(
                      text: "Sign up",
                      style: TextStyle(
                          color: Color(0xFFE91E8C),
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── RIGHT PANEL: REGISTER ─────────────────────────────────────────────────

  Widget _buildRegisterPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Create your account 🎉',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 6),
          Text('Join WEJOY and start your journey',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          const SizedBox(height: 28),

          const _FieldLabel('Full Name'),
          const SizedBox(height: 8),
          ModernTextField(
            controller: fullnameController,
            hint: "Enter your full name",
            icon: Icons.person_outline,
            validator: Validators.validateName,
          ),
          const SizedBox(height: 16),

          const _FieldLabel('Email'),
          const SizedBox(height: 8),
          ModernTextField(
            controller: emailController,
            hint: "Enter your email",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 16),

          const _FieldLabel('Password'),
          const SizedBox(height: 8),
          ModernTextField(
            controller: passwordController,
            hint: "Create a password",
            icon: Icons.lock_outline,
            obscure: obscurePassword,
            toggleObscure: () =>
                setState(() => obscurePassword = !obscurePassword),
            validator: Validators.validatePassword,
          ),
          const SizedBox(height: 16),

          const _FieldLabel('Confirm Password'),
          const SizedBox(height: 8),
          ModernTextField(
            controller: confirmController,
            hint: "Confirm your password",
            icon: Icons.lock_outline,
            obscure: obscureConfirm,
            toggleObscure: () =>
                setState(() => obscureConfirm = !obscureConfirm),
            validator: (v) =>
                Validators.validateConfirmPassword(v, passwordController.text),
          ),
          const SizedBox(height: 24),

          _GradientButton(
              label: 'Create Account',
              onPressed: isLoading ? null : validateAndSubmit,
              isLoading: isLoading),
          const SizedBox(height: 20),

          Center(
            child: GestureDetector(
              onTap: () => setState(() => isLogin = true),
              child: RichText(
                text: const TextSpan(children: [
                  TextSpan(
                      text: "Already have an account? ",
                      style:
                          TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                  TextSpan(
                      text: "Login",
                      style: TextStyle(
                          color: Color(0xFFE91E8C),
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    if (isWide) {
      return Scaffold(
        body: Row(children: [
          const Expanded(flex: 5, child: _LeftPanel()),
          Expanded(
            flex: 6,
            child: Container(
              color: Colors.white,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: isLogin ? _buildLoginPanel() : _buildRegisterPanel(),
              ),
            ),
          ),
        ]),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4FF),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: isLogin ? _buildLoginPanel() : _buildRegisterPanel(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A2E)));
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GradientButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFAB47BC), Color(0xFFE91E8C)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFE91E8C).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                : Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
          ),
        ),
      );
}

class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onPressed;

  const _SocialLoginButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade200, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            backgroundColor: Colors.white,
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 10),
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
              ]),
        ),
      );
}