import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:wejoy/screens/service/admin_api_service.dart';
import 'package:wejoy/screens/service/api_service.dart';
import 'package:wejoy/screens/admin/admin_shell.dart';
import 'dart:convert';
import 'package:wejoy/screens/home_page.dart' hide Widget;

const String _baseUrl = 'http://localhost:5000';

// ── Palette thème genre ───────────────────────────────────────
const Color _pinkPrimary   = Color.fromARGB(255, 245, 157, 201);
const Color _pinkLight     = Color.fromARGB(255, 243, 157, 205);
const Color _pinkMid       = Color(0xFFFCE7F3);
const Color _bluePrimary   = Color.fromARGB(255, 171, 202, 252);
const Color _blueLight     = Color.fromARGB(255, 185, 210, 243);
const Color _blueMid       = Color(0xFFDBEAFE);
const Color _neutralPrimary = Color.fromARGB(255, 179, 137, 175);
const Color _neutralLight   = Color.fromARGB(255, 208, 204, 228);

// ══════════════════════════════════════════════════════════════
// TOAST
// ══════════════════════════════════════════════════════════════
enum ToastType { success, error, warning, info }

class ModernToast {
  static OverlayEntry? _currentEntry;
  static void show(BuildContext context,
      {required String title,
      required String message,
      required ToastType type,
      Duration duration = const Duration(seconds: 3)}) {
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
            duration: duration));
    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String title, message;
  final ToastType type;
  final VoidCallback onDismiss;
  final Duration duration;
  const _ToastWidget(
      {required this.title,
      required this.message,
      required this.type,
      required this.onDismiss,
      required this.duration});
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
    _slideAnimation = Tween<Offset>(
            begin: const Offset(0, 1.5), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _controller, curve: const Interval(0, 0.5)));
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

  Color get _accent {
    switch (widget.type) {
      case ToastType.success: return const Color(0xFF00C853);
      case ToastType.error:   return const Color(0xFFFF1744);
      case ToastType.warning: return const Color(0xFFFFAB00);
      case ToastType.info:    return const Color(0xFF2979FF);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case ToastType.success: return Icons.check_circle_rounded;
      case ToastType.error:   return Icons.cancel_rounded;
      case ToastType.warning: return Icons.warning_rounded;
      case ToastType.info:    return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 24,
      left: 16, right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _accent.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(color: _accent.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8)),
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 4)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: _accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(_icon, color: _accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827))),
                      const SizedBox(height: 2),
                      Text(widget.message, style: TextStyle(
                          fontSize: 12, color: Colors.grey[600], height: 1.4)),
                    ],
                  )),
                  GestureDetector(
                    onTap: _dismiss,
                    child: Icon(Icons.close_rounded, color: Colors.grey[300], size: 18)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// LOADING
// ══════════════════════════════════════════════════════════════
class ModernLoadingOverlay {
  static OverlayEntry? _entry;
  static void show(BuildContext context, {String? message}) {
    _entry?.remove();
    _entry = OverlayEntry(
        builder: (_) => _LoadingWidget(message: message));
    Overlay.of(context).insert(_entry!);
  }
  static void hide() { _entry?.remove(); _entry = null; }
}

class _LoadingWidget extends StatelessWidget {
  final String? message;
  const _LoadingWidget({this.message});
  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Container(
      color: Colors.black.withOpacity(0.35),
      child: Center(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30)]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(
              strokeWidth: 3, valueColor: AlwaysStoppedAnimation(_neutralPrimary)),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
          ],
        ]),
      )),
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// TYPEWRITER
// ══════════════════════════════════════════════════════════════
class TypewriterText extends StatefulWidget {
  final String text;
  final Color color;
  const TypewriterText({super.key, required this.text, required this.color});
  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _charCount;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _charCount = IntTween(begin: 0, end: widget.text.length)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _charCount,
    builder: (_, __) => Text(
      widget.text.substring(0, _charCount.value),
      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: widget.color),
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// VALIDATORS
// ══════════════════════════════════════════════════════════════
class Validators {
  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Email requis';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Email invalide';
    return null;
  }
  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Mot de passe requis';
    if (v.length < 6) return 'Minimum 6 caractères';
    return null;
  }
  static String? name(String? v) {
    if (v == null || v.isEmpty) return 'Nom requis';
    if (v.length < 2) return 'Nom trop court';
    return null;
  }
  static String? confirmPassword(String? v, String p) {
    if (v == null || v.isEmpty) return 'Confirmation requise';
    if (v != p) return 'Mots de passe différents';
    return null;
  }
  static String? age(String? v) {
    if (v == null || v.isEmpty) return 'Âge requis';
    final n = int.tryParse(v);
    if (n == null || n < 8 || n > 100) return 'Âge entre 8 et 100 ans';
    return null;
  }
}

// ══════════════════════════════════════════════════════════════
// CHAMP TEXTE STYLÉ
// ══════════════════════════════════════════════════════════════
class _InputField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final VoidCallback? toggleObscure;
  final String? Function(String?)? validator;
  final TextInputType keyboard;
  final Color accentColor;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.accentColor,
    this.obscure = false,
    this.toggleObscure,
    this.validator,
    this.keyboard = TextInputType.text,
  });

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  late FocusNode _focus;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  void _validate(String v) {
    if (widget.validator != null) {
      setState(() => _error = widget.validator!(v));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _error != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _focus.hasFocus
              ? [BoxShadow(color: widget.accentColor.withOpacity(0.15),
                  blurRadius: 8, spreadRadius: 2)]
              : [],
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focus,
          obscureText: widget.obscure,
          keyboardType: widget.keyboard,
          onChanged: _validate,
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(widget.icon,
                color: _focus.hasFocus ? widget.accentColor : Colors.grey[400],
                size: 18),
            suffixIcon: widget.toggleObscure != null
                ? IconButton(
                    icon: Icon(
                        widget.obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey[400], size: 18),
                    onPressed: widget.toggleObscure)
                : null,
            filled: true,
            fillColor: hasError
                ? const Color(0xFFFEF2F2) : const Color(0xFFF9FAFB),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: hasError
                        ? const Color(0xFFFCA5A5) : Colors.grey.shade200,
                    width: 1)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: widget.accentColor, width: 1.5)),
          ),
        ),
      ),
      if (hasError)
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 5),
          child: Text(_error!,
              style: const TextStyle(
                  color: Color(0xFFEF4444), fontSize: 11)),
        ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
// LOGIN PAGE
// ══════════════════════════════════════════════════════════════
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  // ── Mode ─────────────────────────────────────
  String _mode  = 'user'; // 'user' | 'admin'
  bool _isLogin = true;

  // ── Genre ─────────────────────────────────────
  String? _gender; // 'femme' | 'homme'

  // ── Âge ──────────────────────────────────────
  final ageController = TextEditingController();

  // ── Password visibility ───────────────────────
  bool _obscurePwd     = true;
  bool _obscureConfirm = true;
  bool _obscureAdmin   = true;

  // ── Loading ───────────────────────────────────
  bool _loading      = false;
  bool _adminLoading = false;

  // ── Controllers ───────────────────────────────
  final _nameCtrl          = TextEditingController();
  final _emailCtrl         = TextEditingController();
  final _passwordCtrl      = TextEditingController();
  final _confirmCtrl       = TextEditingController();
  final _adminEmailCtrl    = TextEditingController();
  final _adminPasswordCtrl = TextEditingController();
  final _formKey           = GlobalKey<FormState>();

  final ApiService _api = ApiService();

  // ── Thème dynamique selon genre ───────────────
  Color get _primary {
    if (_gender == 'femme') return _pinkPrimary;
    if (_gender == 'homme') return _bluePrimary;
    return _neutralPrimary;
  }

  Color get _lightBg {
    if (_gender == 'femme') return _pinkLight;
    if (_gender == 'homme') return _blueLight;
    return _neutralLight;
  }

  Color get _midBg {
    if (_gender == 'femme') return _pinkMid;
    if (_gender == 'homme') return _blueMid;
    return const Color(0xFFEDE9FE);
  }

  List<Color> get _pageGradient {
    if (_gender == 'femme')
      return [const Color(0xFFFDF2F8), const Color(0xFFFCE7F3), const Color(0xFFFFF1F5)];
    if (_gender == 'homme')
      return [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE), const Color(0xFFF0F9FF)];
    return [const Color(0xFFF5F3FF), const Color(0xFFEDE9FE), const Color(0xFFF8F7FF)];
  }

  @override
  void initState() {
    super.initState();
    _checkLoggedIn();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passwordCtrl.dispose(); _confirmCtrl.dispose();
    _adminEmailCtrl.dispose(); _adminPasswordCtrl.dispose();
    ageController.dispose();
    super.dispose();
  }

  Future<void> _checkLoggedIn() async {
    final t = await _api.getToken();
    if (t != null && mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  void _toast(String title, String msg, ToastType type) =>
      ModernToast.show(context, title: title, message: msg, type: type);

  // ══════════════════════════════════════════════
  // AUTH METHODS
  // ══════════════════════════════════════════════
  Future<void> _loginAdmin() async {
    if (_adminEmailCtrl.text.trim().isEmpty ||
        _adminPasswordCtrl.text.trim().isEmpty) {
      _toast('Champs requis', 'Remplissez tous les champs.', ToastType.warning);
      return;
    }
    setState(() => _adminLoading = true);
    ModernLoadingOverlay.show(context, message: 'Connexion admin...');
    try {
      final ok = await context
          .read<AdminApiService>()
          .login(_adminEmailCtrl.text.trim(), _adminPasswordCtrl.text.trim());
      ModernLoadingOverlay.hide();
      if (ok && mounted) {
        _toast('Connecté !', "Bienvenue dans l'espace admin 👋", ToastType.success);
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const AdminShell()));
      } else {
        _toast('Erreur', 'Email ou mot de passe incorrect.', ToastType.error);
      }
    } catch (_) {
      ModernLoadingOverlay.hide();
      _toast('Erreur', 'Impossible de contacter le serveur.', ToastType.error);
    } finally {
      setState(() => _adminLoading = false);
    }
  }

  void _submit() async {
    FocusScope.of(context).unfocus();
    if (!_isLogin) {
      if (_gender == null) {
        _toast('Genre requis', 'Veuillez sélectionner votre genre.', ToastType.warning);
        return;
      }
      if (ageController.text.trim().isEmpty) {
        _toast('Âge requis', 'Veuillez entrer votre âge.', ToastType.warning);
        return;
      }
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_isLogin) {
      await _register();
    } else {
      await _login();
    }
  }

  Future<void> _register() async {
    setState(() => _loading = true);
    ModernLoadingOverlay.show(context, message: 'Création du compte...');
    try {
      final age = int.tryParse(ageController.text.trim()) ?? 0;
      final res = await http.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _nameCtrl.text.trim(),
          'email':    _emailCtrl.text.trim(),
          'password': _passwordCtrl.text.trim(),
          'gender':   _gender,
          'age':      age,
        }),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      ModernLoadingOverlay.hide();
      if (res.statusCode == 201) {
        _toast('Compte créé !',
            data['message'] ?? 'Bienvenue sur WeJoy 🎉', ToastType.success);
        setState(() => _isLogin = true);
      } else {
        _toast('Erreur', data['message'] ?? 'Une erreur est survenue.', ToastType.error);
      }
    } catch (_) {
      ModernLoadingOverlay.hide();
      _toast('Erreur', 'Impossible de contacter le serveur.', ToastType.error);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    ModernLoadingOverlay.show(context, message: 'Connexion en cours...');
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email':    _emailCtrl.text.trim(),
          'password': _passwordCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      ModernLoadingOverlay.hide();
      if (res.statusCode == 200) {
        await _api.saveToken(data['token']);
        _toast('Connecté !', 'Bon retour sur WeJoy 👋', ToastType.success);
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomePage()));
      } else {
        _toast('Connexion refusée',
            data['message'] ?? 'Email ou mot de passe incorrect.', ToastType.error);
      }
    } catch (_) {
      ModernLoadingOverlay.hide();
      _toast('Erreur', 'Impossible de contacter le serveur.', ToastType.error);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _toast('Email requis', 'Entrez un email valide.', ToastType.warning);
      return;
    }
    ModernLoadingOverlay.show(context, message: 'Envoi en cours...');
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      ModernLoadingOverlay.hide();
      if (res.statusCode == 200) {
        _toast('Email envoyé !', data['message'] ?? 'Vérifiez votre boîte mail.', ToastType.success);
      } else {
        _toast('Erreur', data['message'] ?? 'Une erreur est survenue.', ToastType.error);
      }
    } catch (_) {
      ModernLoadingOverlay.hide();
      _toast('Erreur', 'Impossible de contacter le serveur.', ToastType.error);
    }
  }

  // ══════════════════════════════════════════════
  // WIDGETS
  // ══════════════════════════════════════════════

  // Boutons radio genre
  Widget _buildGenderRadios() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Vous êtes',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
              color: Colors.grey[700])),
      const SizedBox(height: 10),
      Row(children: [
        // ── Femme ──
        Expanded(child: GestureDetector(
          onTap: () => setState(() => _gender = 'femme'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: _gender == 'femme' ? _pinkLight : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _gender == 'femme'
                    ? _pinkPrimary : Colors.grey.shade200,
                width: _gender == 'femme' ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              // Radio circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _gender == 'femme'
                        ? _pinkPrimary : Colors.grey.shade300,
                    width: _gender == 'femme' ? 0 : 1.5,
                  ),
                  color: _gender == 'femme' ? _pinkPrimary : Colors.white,
                ),
                child: _gender == 'femme'
                    ? const Icon(Icons.check, color: Colors.white, size: 13)
                    : null,
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Femme', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: _gender == 'femme' ? _pinkPrimary : Colors.grey[700])),
                Text('♀', style: TextStyle(fontSize: 14,
                    color: _gender == 'femme'
                        ? _pinkPrimary : Colors.grey[400])),
              ]),
            ]),
          ),
        )),
        const SizedBox(width: 10),
        // ── Homme ──
        Expanded(child: GestureDetector(
          onTap: () => setState(() => _gender = 'homme'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: _gender == 'homme' ? _blueLight : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _gender == 'homme'
                    ? _bluePrimary : Colors.grey.shade200,
                width: _gender == 'homme' ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _gender == 'homme'
                        ? _bluePrimary : Colors.grey.shade300,
                    width: _gender == 'homme' ? 0 : 1.5,
                  ),
                  color: _gender == 'homme' ? _bluePrimary : Colors.white,
                ),
                child: _gender == 'homme'
                    ? const Icon(Icons.check, color: Colors.white, size: 13)
                    : null,
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Homme', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: _gender == 'homme' ? _bluePrimary : Colors.grey[700])),
                Text('♂', style: TextStyle(fontSize: 14,
                    color: _gender == 'homme'
                        ? _bluePrimary : Colors.grey[400])),
              ]),
            ]),
          ),
        )),
      ]),
    ]);
  }

  // Champ âge
  Widget _buildAgeField() {
    return _InputField(
      controller: ageController,
      hint: 'Votre âge',
      icon: Icons.cake_outlined,
      keyboard: TextInputType.number,
      accentColor: _primary,
      validator: Validators.age,
    );
  }

  // Tab bar
  Widget _buildTab(String label, bool active, VoidCallback onTap) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active ? _primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Text(label,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: active ? Colors.white : Colors.grey[500],
            ))),
      ),
    ));
  }

  // Champs inscription
  Widget _buildRegisterFields() {
    return Column(key: const ValueKey('reg'), children: [
      // Genre
      _buildGenderRadios(),
      const SizedBox(height: 16),

      // Âge
      _buildAgeField(),
      const SizedBox(height: 12),

      // Nom
      _InputField(
        controller: _nameCtrl, hint: 'Nom complet',
        icon: Icons.person_outline_rounded, accentColor: _primary,
        validator: Validators.name,
      ),
      const SizedBox(height: 12),

      // Email
      _InputField(
        controller: _emailCtrl, hint: 'Adresse email',
        icon: Icons.mail_outline_rounded,
        keyboard: TextInputType.emailAddress,
        accentColor: _primary, validator: Validators.email,
      ),
      const SizedBox(height: 12),

      // Password
      _InputField(
        controller: _passwordCtrl, hint: 'Mot de passe',
        icon: Icons.lock_outline_rounded,
        obscure: _obscurePwd,
        toggleObscure: () => setState(() => _obscurePwd = !_obscurePwd),
        accentColor: _primary, validator: Validators.password,
      ),
      const SizedBox(height: 12),

      // Confirm
      _InputField(
        controller: _confirmCtrl, hint: 'Confirmer le mot de passe',
        icon: Icons.lock_outline_rounded,
        obscure: _obscureConfirm,
        toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
        accentColor: _primary,
        validator: (v) => Validators.confirmPassword(v, _passwordCtrl.text),
      ),
    ]);
  }

  // Champs connexion
  Widget _buildLoginFields() {
    return Column(key: const ValueKey('log'), children: [
      _InputField(
        controller: _emailCtrl, hint: 'Adresse email',
        icon: Icons.mail_outline_rounded,
        keyboard: TextInputType.emailAddress,
        accentColor: _primary, validator: Validators.email,
      ),
      const SizedBox(height: 12),
      _InputField(
        controller: _passwordCtrl, hint: 'Mot de passe',
        icon: Icons.lock_outline_rounded,
        obscure: _obscurePwd,
        toggleObscure: () => setState(() => _obscurePwd = !_obscurePwd),
        accentColor: _primary, validator: Validators.password,
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: _forgotPassword,
          child: Text('Mot de passe oublié ?',
              style: TextStyle(fontSize: 12, color: _primary,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline)),
        ),
      ),
    ]);
  }

  // Bouton principal
  Widget _buildPrimaryButton() {
    return SizedBox(
      width: double.infinity, height: 48,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
            : Text(_isLogin ? 'Se connecter' : 'Créer mon compte',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // Contenu carte mode user
  Widget _buildUserCard() {
    return Column(children: [
      // Tabs
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          _buildTab('Connexion', _isLogin,
              () => setState(() => _isLogin = true)),
          _buildTab('Inscription', !_isLogin,
              () => setState(() => _isLogin = false)),
        ]),
      ),
      const SizedBox(height: 24),

      // Champs
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
                begin: const Offset(0, 0.04), end: Offset.zero)
                .animate(anim),
            child: child,
          ),
        ),
        child: !_isLogin ? _buildRegisterFields() : _buildLoginFields(),
      ),
      const SizedBox(height: 20),

      _buildPrimaryButton(),
      const SizedBox(height: 20),

      // Divider
      Row(children: [
        Expanded(child: Divider(color: Colors.grey.shade200)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('ou continuer avec',
              style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ),
        Expanded(child: Divider(color: Colors.grey.shade200)),
      ]),
      const SizedBox(height: 16),

      // Social
      Row(children: [
        _socialBtn('Google', Icons.g_mobiledata, const Color(0xFFDB4437)),
        const SizedBox(width: 10),
        _socialBtn('Facebook', Icons.facebook, const Color(0xFF1877F2)),
        const SizedBox(width: 10),
        _socialBtn('Apple', Icons.apple, Colors.black),
      ]),

      // Lien admin
      const SizedBox(height: 16),
      GestureDetector(
        onTap: () => setState(() => _mode = 'admin'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.admin_panel_settings_outlined,
                size: 16, color: Colors.grey[500]),
            const SizedBox(width: 8),
            Text('Accès administrateur',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ]),
        ),
      ),
    ]);
  }

  Widget _socialBtn(String label, IconData icon, Color color) {
    return Expanded(child: OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        side: BorderSide(color: Colors.grey.shade200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ));
  }

  // Contenu carte mode admin
  Widget _buildAdminCard() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Retour
      GestureDetector(
        onTap: () => setState(() {
          _mode = 'user';
          _adminEmailCtrl.clear();
          _adminPasswordCtrl.clear();
        }),
        child: Row(children: [
          Icon(Icons.arrow_back_ios_new_rounded,
              size: 14, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Text('Retour', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ]),
      ),
      const SizedBox(height: 20),

      Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: _neutralLight,
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.admin_panel_settings_outlined,
              color: _neutralPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Espace Administrateur',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                  color: Color(0xFF111827))),
          Text('Accès restreint',
              style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ]),
      ]),
      const SizedBox(height: 24),

      _InputField(
        controller: _adminEmailCtrl,
        hint: 'Email administrateur',
        icon: Icons.mail_outline_rounded,
        keyboard: TextInputType.emailAddress,
        accentColor: _neutralPrimary,
      ),
      const SizedBox(height: 12),
      _InputField(
        controller: _adminPasswordCtrl,
        hint: 'Mot de passe',
        icon: Icons.lock_outline_rounded,
        obscure: _obscureAdmin,
        toggleObscure: () => setState(() => _obscureAdmin = !_obscureAdmin),
        accentColor: _neutralPrimary,
      ),
      const SizedBox(height: 20),

      SizedBox(
        width: double.infinity, height: 48,
        child: ElevatedButton(
          onPressed: _adminLoading ? null : _loginAdmin,
          style: ElevatedButton.styleFrom(
            backgroundColor: _neutralPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _adminLoading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white)))
              : const Text('Se connecter',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _pageGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(children: [
              // Logo
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary,
                  boxShadow: [
                    BoxShadow(color: _primary.withOpacity(0.3),
                        blurRadius: 20, offset: const Offset(0, 8))
                  ],
                ),
                child: Icon(
                  _gender == 'femme'
                      ? Icons.female_rounded
                      : _gender == 'homme'
                          ? Icons.male_rounded
                          : Icons.favorite_rounded,
                  color: Colors.white, size: 32,
                ),
              ),
              const SizedBox(height: 12),

              TypewriterText(text: 'WeJoy', color: _primary),
              const SizedBox(height: 4),
              Text('Votre espace bien-être',
                  style: TextStyle(fontSize: 13, color: _primary.withOpacity(0.7))),
              const SizedBox(height: 28),

              // Carte
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: _primary.withOpacity(0.12),
                        blurRadius: 30, spreadRadius: 2,
                        offset: const Offset(0, 8)),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: _mode == 'admin'
                      ? _buildAdminCard()
                      : _buildUserCard(),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}