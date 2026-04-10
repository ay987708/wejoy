import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:wejoy/screens/service/admin_api_service.dart';
import 'package:wejoy/screens/service/api_service.dart';
import 'package:wejoy/screens/admin/admin_shell.dart';
import 'dart:convert';
import 'package:wejoy/screens/home_page.dart' hide Widget;

const String _baseUrl = 'http://localhost:5001';

// MODERN TOAST NOTIFICATION SYSTEM

enum ToastType { success, error, warning, info }

class ModernToast {
  static OverlayEntry? _currentEntry;
  static void show(BuildContext context, {required String title, required String message, required ToastType type, Duration duration = const Duration(seconds: 3)}) {
    _currentEntry?.remove();
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (context) => _ToastWidget(title: title, message: message, type: type, onDismiss: () { entry.remove(); _currentEntry = null; }, duration: duration));
    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String title, message;
  final ToastType type;
  final VoidCallback onDismiss;
  final Duration duration;
  const _ToastWidget({required this.title, required this.message, required this.type, required this.onDismiss, required this.duration});
  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5)));
    _controller.forward();
    Future.delayed(widget.duration, () { if (mounted) _dismiss(); });
  }
  void _dismiss() async {
    if (!mounted) return;
    _controller.duration = const Duration(milliseconds: 300);
    await _controller.reverse();
    widget.onDismiss();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  _ToastConfig get _config {
    switch (widget.type) {
      case ToastType.success: return _ToastConfig(icon: Icons.check_circle_rounded, iconColor: const Color(0xFF00C853), accentColor: const Color(0xFF00C853), bgColor: const Color(0xFF1A2E1A), progressColor: const Color(0xFF00C853));
      case ToastType.error: return _ToastConfig(icon: Icons.cancel_rounded, iconColor: const Color(0xFFFF1744), accentColor: const Color(0xFFFF1744), bgColor: const Color(0xFF2E1A1A), progressColor: const Color(0xFFFF1744));
      case ToastType.warning: return _ToastConfig(icon: Icons.warning_rounded, iconColor: const Color(0xFFFFAB00), accentColor: const Color(0xFFFFAB00), bgColor: const Color(0xFF2E2A1A), progressColor: const Color(0xFFFFAB00));
      case ToastType.info: return _ToastConfig(icon: Icons.info_rounded, iconColor: const Color(0xFF2979FF), accentColor: const Color(0xFF2979FF), bgColor: const Color(0xFF1A1A2E), progressColor: const Color(0xFF2979FF));
    }
  }
  @override
  Widget build(BuildContext context) {
    final config = _config;
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 24, left: 16, right: 16,
      child: SlideTransition(position: _slideAnimation, child: FadeTransition(opacity: _fadeAnimation,
        child: GestureDetector(onTap: _dismiss, child: Material(color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(color: config.bgColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: config.accentColor.withOpacity(0.3), width: 1),
              boxShadow: [BoxShadow(color: config.accentColor.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)), BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 4))]),
            child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: config.accentColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(config.icon, color: config.iconColor, size: 24)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(widget.message, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4)),
                ])),
                GestureDetector(onTap: _dismiss, child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.4), size: 18)),
              ])),
              _ProgressBar(duration: widget.duration, color: config.progressColor),
            ])),
          ),
        )),
      )),
    );
  }
}

class _ProgressBar extends StatefulWidget {
  final Duration duration; final Color color;
  const _ProgressBar({required this.duration, required this.color});
  @override State<_ProgressBar> createState() => _ProgressBarState();
}
class _ProgressBarState extends State<_ProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: widget.duration); _ctrl.forward(); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: _ctrl, builder: (_, __) => LinearProgressIndicator(value: 1 - _ctrl.value, minHeight: 3, backgroundColor: widget.color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation(widget.color.withOpacity(0.8))));
}

class _ToastConfig {
  final IconData icon; final Color iconColor, accentColor, bgColor, progressColor;
  _ToastConfig({required this.icon, required this.iconColor, required this.accentColor, required this.bgColor, required this.progressColor});
}

class ModernLoadingOverlay {
  static OverlayEntry? _entry;
  static void show(BuildContext context, {String? message}) {
    _entry?.remove();
    _entry = OverlayEntry(builder: (_) => _ModernLoadingWidget(message: message));
    Overlay.of(context).insert(_entry!);
  }
  static void hide() { _entry?.remove(); _entry = null; }
}

class _ModernLoadingWidget extends StatelessWidget {
  final String? message;
  const _ModernLoadingWidget({this.message});
  @override
  Widget build(BuildContext context) => Positioned.fill(child: Container(color: Colors.black.withOpacity(0.4), child: Center(child: TweenAnimationBuilder(tween: Tween<double>(begin: 0, end: 1), duration: const Duration(milliseconds: 400), curve: Curves.easeOutBack,
    builder: (context, double value, child) => Transform.scale(scale: value, child: child),
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40)]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 44, height: 44, child: Stack(children: [
          const CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(Color(0xFFAB47BC))),
          Center(child: Icon(Icons.favorite, color: const Color(0xFFAB47BC).withOpacity(0.5), size: 20)),
        ])),
        if (message != null) ...[const SizedBox(height: 16), Text(message!, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))],
      ]),
    ),
  ))));
}

class TypewriterText extends StatefulWidget {
  final String text; final Duration duration;
  const TypewriterText({super.key, required this.text, this.duration = const Duration(milliseconds: 1500)});
  @override State<TypewriterText> createState() => _TypewriterTextState();
}
class _TypewriterTextState extends State<TypewriterText> with SingleTickerProviderStateMixin {
  late AnimationController _controller; late Animation<int> _characterCount;
  @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: widget.duration); _characterCount = IntTween(begin: 0, end: widget.text.length).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)); _controller.forward(); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: _characterCount, builder: (context, child) => Text(widget.text.substring(0, _characterCount.value), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF9B27AF))));
}

class ModernTextField extends StatefulWidget {
  final TextEditingController controller; final String hint; final IconData icon; final bool obscure; final VoidCallback? toggleObscure; final String? Function(String?)? validator; final TextInputType keyboardType; final Color? accentColor;
  const ModernTextField({super.key, required this.controller, required this.hint, required this.icon, this.obscure = false, this.toggleObscure, this.validator, this.keyboardType = TextInputType.text, this.accentColor});
  @override State<ModernTextField> createState() => _ModernTextFieldState();
}
class _ModernTextFieldState extends State<ModernTextField> {
  late FocusNode _focusNode; bool _hasError = false; String? _errorText;
  Color get accent => widget.accentColor ?? const Color(0xFFAB47BC);
  @override void initState() { super.initState(); _focusNode = FocusNode(); _focusNode.addListener(() => setState(() {})); }
  @override void dispose() { _focusNode.dispose(); super.dispose(); }
  void _validate(String value) { if (widget.validator != null) { final error = widget.validator!(value); setState(() { _hasError = error != null; _errorText = error; }); } }
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AnimatedContainer(duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: _focusNode.hasFocus ? [BoxShadow(color: accent.withOpacity(0.2), blurRadius: 8, spreadRadius: 2)] : []),
        child: TextField(controller: widget.controller, focusNode: _focusNode, obscureText: widget.obscure, keyboardType: widget.keyboardType, onChanged: _validate,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: widget.hint, hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(widget.icon, color: _focusNode.hasFocus ? accent : Colors.grey.shade400, size: 20),
            suffixIcon: widget.toggleObscure != null ? IconButton(icon: Icon(widget.obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _focusNode.hasFocus ? accent : Colors.grey.shade400, size: 20), onPressed: widget.toggleObscure) : null,
            filled: true, fillColor: _hasError ? const Color(0xFFFEE7E7) : Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200, width: 1)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accent, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFFF5252), width: 2)),
          ),
        ),
      ),
      if (_hasError) Padding(padding: const EdgeInsets.only(left: 12, top: 6), child: Text(_errorText ?? '', style: const TextStyle(color: Color(0xFFFF5252), fontSize: 12, fontWeight: FontWeight.w500))),
    ]);
  }
}

class SocialButton extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onPressed;
  const SocialButton({super.key, required this.icon, required this.label, required this.color, required this.onPressed});
  @override
  Widget build(BuildContext context) => Material(color: Colors.transparent, child: InkWell(onTap: onPressed, borderRadius: BorderRadius.circular(12),
    child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [Icon(icon, color: color), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600))]))));
}

class Validators {
  static String? validateEmail(String? v) { if (v == null || v.isEmpty) return "L'email est requis"; if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return "Format d'email invalide"; return null; }
  static String? validatePassword(String? v) { if (v == null || v.isEmpty) return "Le mot de passe est requis"; if (v.length < 6) return "Minimum 6 caractères"; return null; }
  static String? validateName(String? v) { if (v == null || v.isEmpty) return "Le nom est requis"; if (v.length < 2) return "Nom trop court"; return null; }
  static String? validateConfirmPassword(String? v, String p) { if (v == null || v.isEmpty) return "Confirmation requise"; if (v != p) return "Les mots de passe ne correspondent pas"; return null; }
}

class SocialAuthService {
  static Future<void> signInWithGoogle(BuildContext context) async { ModernLoadingOverlay.show(context, message: "Connexion avec Google..."); await Future.delayed(const Duration(seconds: 2)); ModernLoadingOverlay.hide(); ModernToast.show(context, title: "Google", message: "Connexion Google réussie !", type: ToastType.success); }
  static Future<void> signInWithFacebook(BuildContext context) async { ModernLoadingOverlay.show(context, message: "Connexion avec Facebook..."); await Future.delayed(const Duration(seconds: 2)); ModernLoadingOverlay.hide(); ModernToast.show(context, title: "Facebook", message: "Connexion Facebook réussie !", type: ToastType.success); }
  static Future<void> signInWithApple(BuildContext context) async { ModernLoadingOverlay.show(context, message: "Connexion avec Apple..."); await Future.delayed(const Duration(seconds: 2)); ModernLoadingOverlay.hide(); ModernToast.show(context, title: "Apple", message: "Connexion Apple réussie !", type: ToastType.success); }
}


// LOGIN PAGE

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  // Mode: 'user' ou 'admin'
  String _mode = 'user'; 
  bool isLogin = true;
  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool isLoading = false;

  // Admin
  bool adminObscure = true;
  bool adminLoading = false;
  final adminEmailController = TextEditingController();
  final adminPasswordController = TextEditingController();

  // User
  final fullnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _toggleAnimationController;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _toggleAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _checkIfLoggedIn();
  }

  Future<void> _checkIfLoggedIn() async {
    final token = await _apiService.getToken();
    if (token != null && mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
  }

  @override
  void dispose() {
    _toggleAnimationController.dispose();
    fullnameController.dispose(); emailController.dispose(); passwordController.dispose(); confirmController.dispose();
    adminEmailController.dispose(); adminPasswordController.dispose();
    super.dispose();
  }

  void _showToast({required String title, required String message, required ToastType type}) => ModernToast.show(context, title: title, message: message, type: type);

  Future<void> _loginAdmin() async {
    final email = adminEmailController.text.trim();
    final password = adminPasswordController.text.trim();
    if (email.isEmpty || password.isEmpty) { _showToast(title: 'Champs requis', message: 'Remplissez tous les champs.', type: ToastType.warning); return; }
    setState(() => adminLoading = true);
    ModernLoadingOverlay.show(context, message: 'Connexion admin...');
    try {
      final adminApi = context.read<AdminApiService>();
      final ok = await adminApi.login(email, password);
      ModernLoadingOverlay.hide();
      if (ok && mounted) {
        _showToast(title: 'Connecté !', message: "Bienvenue dans l'espace admin 👋", type: ToastType.success);
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminShell()));
      } else {
        _showToast(title: 'Erreur', message: 'Email ou mot de passe incorrect.', type: ToastType.error);
      }
    } catch (e) {
      ModernLoadingOverlay.hide();
      _showToast(title: 'Erreur', message: 'Impossible de contacter le serveur.', type: ToastType.error);
    } finally {
      setState(() => adminLoading = false);
    }
  }

  void validateAndSubmit() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      if (!isLogin) await registerUser(fullnameController.text.trim(), emailController.text.trim(), passwordController.text.trim());
      else await loginUser(emailController.text.trim(), passwordController.text.trim());
    }
  }

  Future<void> registerUser(String username, String email, String password) async {
    setState(() => isLoading = true);
    ModernLoadingOverlay.show(context, message: "Création du compte...");
    try {
      final response = await http.post(Uri.parse('$_baseUrl/api/auth/register'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'username': username, 'email': email, 'password': password})).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      ModernLoadingOverlay.hide();
      if (response.statusCode == 201) { _showToast(title: "Compte créé !", message: data['message'] ?? "Bienvenue sur WeJoy 🎉", type: ToastType.success); setState(() { isLogin = true; _toggleAnimationController.forward(from: 0); }); }
      else { _showToast(title: "Inscription échouée", message: data['message'] ?? "Une erreur est survenue.", type: ToastType.error); }
    } catch (e) { ModernLoadingOverlay.hide(); _showToast(title: "Erreur", message: "Impossible de contacter le serveur.", type: ToastType.error); }
    finally { setState(() => isLoading = false); }
  }

  Future<void> loginUser(String email, String password) async {
    setState(() => isLoading = true);
    ModernLoadingOverlay.show(context, message: "Connexion en cours...");
    try {
      final response = await http.post(Uri.parse('$_baseUrl/api/auth/login'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'password': password})).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      ModernLoadingOverlay.hide();
      if (response.statusCode == 200) {
        await _apiService.saveToken(data['token']);
        _showToast(title: "Connecté !", message: "Bon retour sur WeJoy 👋", type: ToastType.success);
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
      } else { _showToast(title: "Connexion refusée", message: data['message'] ?? "Email ou mot de passe incorrect.", type: ToastType.error); }
    } catch (e) { ModernLoadingOverlay.hide(); _showToast(title: "Erreur", message: "Impossible de contacter le serveur.", type: ToastType.error); }
    finally { setState(() => isLoading = false); }
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) { _showToast(title: "Email requis", message: "Entrez un email valide.", type: ToastType.warning); return; }
    ModernLoadingOverlay.show(context, message: "Envoi en cours...");
    try {
      final response = await http.post(Uri.parse('$_baseUrl/api/auth/forgot-password'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email})).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      ModernLoadingOverlay.hide();
      if (response.statusCode == 200) _showToast(title: "Email envoyé !", message: data['message'] ?? "Vérifiez votre boîte mail.", type: ToastType.success);
      else _showToast(title: "Erreur", message: data['message'] ?? "Une erreur est survenue.", type: ToastType.error);
    } catch (e) { ModernLoadingOverlay.hide(); _showToast(title: "Erreur", message: "Impossible de contacter le serveur.", type: ToastType.error); }
  }

  // ── Tabs user ─────────────────────────────
  Widget _buildTab(String label, bool isActive, VoidCallback onTap) {
    return Expanded(child: GestureDetector(onTap: onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: isActive ? const LinearGradient(colors: [Color(0xFFAB47BC), Color(0xFFE91E8C)]) : null,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(child: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal))),
    )));
  }

  Widget _buildRegisterFields() {
    return Column(key: const ValueKey('register'), children: [
      ModernTextField(controller: fullnameController, hint: "Nom complet", icon: Icons.person_outline, validator: Validators.validateName),
      const SizedBox(height: 14),
      ModernTextField(controller: emailController, hint: "Email", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: Validators.validateEmail),
      const SizedBox(height: 14),
      ModernTextField(controller: passwordController, hint: "Mot de passe", icon: Icons.lock_outline, obscure: obscurePassword, toggleObscure: () => setState(() => obscurePassword = !obscurePassword), validator: Validators.validatePassword),
      const SizedBox(height: 14),
      ModernTextField(controller: confirmController, hint: "Confirmer mot de passe", icon: Icons.lock_outline, obscure: obscureConfirm, toggleObscure: () => setState(() => obscureConfirm = !obscureConfirm), validator: (v) => Validators.validateConfirmPassword(v, passwordController.text)),
    ]);
  }

  Widget _buildLoginFields() {
    return Column(key: const ValueKey('login'), children: [
      ModernTextField(controller: emailController, hint: "Email", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: Validators.validateEmail),
      const SizedBox(height: 14),
      ModernTextField(controller: passwordController, hint: "Mot de passe", icon: Icons.lock_outline, obscure: obscurePassword, toggleObscure: () => setState(() => obscurePassword = !obscurePassword), validator: Validators.validatePassword),
      Align(alignment: Alignment.centerRight, child: GestureDetector(onTap: forgotPassword, child: const Padding(padding: EdgeInsets.only(top: 8), child: Text("Mot de passe oublié ?", style: TextStyle(color: Color(0xFFAB47BC), fontWeight: FontWeight.w500, decoration: TextDecoration.underline))))),
    ]);
  }

  Widget _buildSocialButtons() {
    return Column(children: [
      Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text("Ou continuer avec", style: TextStyle(color: Colors.grey.shade500, fontSize: 13))), const Expanded(child: Divider())]),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: SocialButton(icon: Icons.g_mobiledata, label: "Google", color: const Color(0xFFDB4437), onPressed: () => SocialAuthService.signInWithGoogle(context))),
        const SizedBox(width: 12),
        Expanded(child: SocialButton(icon: Icons.facebook, label: "Facebook", color: const Color(0xFF4267B2), onPressed: () => SocialAuthService.signInWithFacebook(context))),
        const SizedBox(width: 12),
        Expanded(child: SocialButton(icon: Icons.apple, label: "Apple", color: Colors.black, onPressed: () => SocialAuthService.signInWithApple(context))),
      ]),
    ]);
  }

  // ── Contenu carte selon mode ──────────────
  Widget _buildCardContent() {
    if (_mode == 'admin') {
      // Interface admin : même design que user mais sans les tabs
      return Column(children: [
        // Header admin avec bouton retour
        Row(children: [
          GestureDetector(
            onTap: () => setState(() { _mode = 'user'; adminEmailController.clear(); adminPasswordController.clear(); }),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFA855F7).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFFA855F7)),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.admin_panel_settings, color: Color(0xFFA855F7), size: 22),
          const SizedBox(width: 8),
          const Text('Espace Administrateur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        ]),
        const SizedBox(height: 24),
        // Champs admin — même style que user
        ModernTextField(
          controller: adminEmailController,
          hint: "Email administrateur",
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          accentColor: const Color(0xFFA855F7),
        ),
        const SizedBox(height: 14),
        ModernTextField(
          controller: adminPasswordController,
          hint: "Mot de passe",
          icon: Icons.lock_outline,
          obscure: adminObscure,
          toggleObscure: () => setState(() => adminObscure = !adminObscure),
          accentColor: const Color(0xFFA855F7),
        ),
        const SizedBox(height: 24),
        // Bouton connexion admin — même style que user
        SizedBox(
          width: double.infinity, height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFFEC4899)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton(
              onPressed: adminLoading ? null : _loginAdmin,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: adminLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Text("Se connecter", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ]);
    }

    // Mode user normal
    return Column(children: [
      // Tabs Connexion / Inscription + bouton Admin
      Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(30)),
            child: Row(children: [
              _buildTab("Connexion", isLogin, () => setState(() { isLogin = true; _toggleAnimationController.forward(from: 0); })),
              _buildTab("Inscription", !isLogin, () => setState(() { isLogin = false; _toggleAnimationController.forward(from: 0); })),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        // 🔑 Bouton Admin discret
        GestureDetector(
          onTap: () => setState(() => _mode = 'admin'),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFA855F7).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.25)),
            ),
            child: const Icon(Icons.admin_panel_settings_outlined, size: 20, color: Color(0xFFA855F7)),
          ),
        ),
      ]),
      const SizedBox(height: 24),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuad)), child: child)),
        child: !isLogin ? _buildRegisterFields() : _buildLoginFields(),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity, height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFAB47BC), Color(0xFFE91E8C)]), borderRadius: BorderRadius.circular(14)),
          child: ElevatedButton(
            onPressed: isLoading ? null : validateAndSubmit,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                : Text(isLogin ? "Se connecter" : "Créer un Compte", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
      const SizedBox(height: 20),
      _buildSocialButtons(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFEDE7F6), Color(0xFFF3E5F5), Color(0xFFFCE4EC)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Center(
          child: SingleChildScrollView(
            child: Column(children: [
              const SizedBox(height: 20),
              TweenAnimationBuilder(tween: Tween<double>(begin: 0, end: 1), duration: const Duration(milliseconds: 800), curve: Curves.elasticOut,
                builder: (context, double value, child) => Transform.scale(scale: value, child: child),
                child: Container(width: 80, height: 80,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFAB47BC), Color(0xFFE91E8C)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                  child: const Icon(Icons.groups, color: Colors.white, size: 38),
                ),
              ),
              const SizedBox(height: 16),
              const TypewriterText(text: "wejoy"),
              const SizedBox(height: 6),
              const Text("Bienvenue dans votre espace bien-être", style: TextStyle(color: Color(0xFFAB47BC), fontSize: 14)),
              const SizedBox(height: 30),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 360,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: (_mode == 'admin' ? const Color(0xFFA855F7) : Colors.purple.shade100).withOpacity(0.3), blurRadius: 30, spreadRadius: 5)],
                ),
                child: Form(key: _formKey, child: _buildCardContent()),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
    );
  }
}