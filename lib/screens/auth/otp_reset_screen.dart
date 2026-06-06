import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

const String _baseUrl = 'http://localhost:5000';
// ── Même URL que login_page.dart ──────────────────────────────────────────────
// Émulateur Android  → http://10.0.2.2:5000
// Appareil physique  → http://192.168.X.X:5000
// Web / iOS simulateur → http://localhost:5000
// Pour Flutter Web


class OtpResetScreen extends StatefulWidget {
  final String email;
  const OtpResetScreen({super.key, required this.email});
  @override
  State<OtpResetScreen> createState() => _OtpResetScreenState();
}

class _OtpResetScreenState extends State<OtpResetScreen> {
  final _otpController      = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  bool _isLoading      = false;
  bool _isResending    = false;
  bool _obscurePass    = true;
  bool _obscureConfirm = true;

  // ── Compte à rebours pour le renvoi
  //button bloqué pendant 60 secondes. ──────────────────────────────────────
  int  _resendCountdown = 60;
  bool _canResend       = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60;
      _canResend       = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── Réinitialisation du mot de passe ─────────────────────────────────────
  Future<void> _resetPassword() async {
    final otp         = _otpController.text.trim();
    final newPassword = _passwordController.text;
    final confirm     = _confirmController.text;

    if (otp.isEmpty || newPassword.isEmpty || confirm.isEmpty) {
      _showToast("Remplissez tous les champs.", isError: true);
      return;
    }
    if (otp.length != 6) {
      _showToast("Le code OTP doit contenir 6 chiffres.", isError: true);
      return;
    }
    if (newPassword != confirm) {
      _showToast("Les mots de passe ne correspondent pas.", isError: true);
      return;
    }
    if (newPassword.length < 6) {
      _showToast("Minimum 6 caractères.", isError: true);
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      //  Envoie email + otp + newPassword au backend
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email':       widget.email,
          'otp':         otp,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showToast("Mot de passe réinitialisé avec succès !", isError: false);
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        _showToast(data['message'] ?? "Erreur.", isError: true);
      }
    } on TimeoutException {
      _showToast("Le serveur ne répond pas. Réessayez.", isError: true);
    } catch (e) {
      _showToast("Impossible de contacter le serveur.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Renvoi du code OTP ────────────────────────────────────────────────────
  Future<void> _resendOtp() async {
    if (!_canResend || _isResending) return;

    setState(() => _isResending = true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showToast("Nouveau code envoyé par email !", isError: false);
        _otpController.clear();
        _startResendTimer(); // relance le compte à rebours
      } else {
        _showToast(data['message'] ?? "Erreur lors de l'envoi.", isError: true);
      }
    } on TimeoutException {
      _showToast("Le serveur ne répond pas.", isError: true);
    } catch (e) {
      _showToast("Erreur lors de l'envoi.", isError: true);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  // ── Toast ─────────────────────────────────────────────────────────────────
  void _showToast(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
          color: Colors.white, size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(message,
            style: const TextStyle(color: Colors.white, fontSize: 14))),
      ]),
      backgroundColor: isError ? const Color(0xFFFF1744) : const Color(0xFF00C853),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Champ de texte ────────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: const Color(0xFFAB47BC), size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFAB47BC), width: 2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEDE7F6), Color(0xFFF3E5F5), Color(0xFFFCE4EC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // ── Bouton retour ──
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFAB47BC).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: Color(0xFFAB47BC)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // ── Icône ──
                Container(
                  width: 72, height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [Color(0xFFAB47BC), Color(0xFFE91E8C)]),
                  ),
                  child: const Icon(Icons.lock_reset,
                      color: Colors.white, size: 34),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Vérification",
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9B27AF)),
                ),
                const SizedBox(height: 8),

                // ── Email affiché ──
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAB47BC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.email,
                    style: const TextStyle(
                        color: Color(0xFF9B27AF),
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Le code a été envoyé à votre boîte mail",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.5),
                ),
                const SizedBox(height: 32),

                // ── Card ──
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.purple.shade100.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Champ OTP ──
                      const Text("Code OTP",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF9B27AF))),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _otpController,
                        hint: '_ _ _ _ _ _',
                        icon: Icons.pin_outlined,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                      ),
                      const SizedBox(height: 20),

                      // ── Nouveau mot de passe ──
                      const Text("Nouveau mot de passe",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF9B27AF))),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _passwordController,
                        hint: 'Nouveau mot de passe',
                        icon: Icons.lock_outline,
                        obscure: _obscurePass,
                        toggleObscure: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _confirmController,
                        hint: 'Confirmer le mot de passe',
                        icon: Icons.lock_outline,
                        obscure: _obscureConfirm,
                        toggleObscure: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                      const SizedBox(height: 28),

                      // ── Bouton réinitialiser ──
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFFAB47BC), Color(0xFFE91E8C)]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: const Color(0xFFAB47BC).withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation(
                                            Colors.white)))
                                : const Text("Réinitialiser",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Renvoi avec compte à rebours ──
                      Center(
                        child: _isResending
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                        Color(0xFFAB47BC))))
                            : _canResend
                                ? GestureDetector(
                                    onTap: _resendOtp,
                                    child: RichText(
                                      text: const TextSpan(
                                        text: "Pas reçu le code ? ",
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 13),
                                        children: [
                                          TextSpan(
                                            text: "Renvoyer",
                                            style: TextStyle(
                                                color: Color(0xFFAB47BC),
                                                fontWeight: FontWeight.w600,
                                                decoration:
                                                    TextDecoration.underline),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                : Text(
                                    "Renvoyer dans $_resendCountdown s",
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 13),
                                  ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
