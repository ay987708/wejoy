import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const String _baseUrl = 'http://localhost:5000';

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
  bool _obscurePass    = true;
  bool _obscureConfirm = true;

  Future<void> _resetPassword() async {
    final otp         = _otpController.text.trim();
    final newPassword = _passwordController.text;
    final confirm     = _confirmController.text;

    if (otp.isEmpty || newPassword.isEmpty || confirm.isEmpty) {
      _showToast("Remplissez tous les champs.", isError: true);
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
        _showToast("Mot de passe réinitialisé !", isError: false);
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        // Retour au login
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        _showToast(data['message'] ?? "Erreur.", isError: true);
      }
    } catch (e) {
      _showToast("Impossible de contacter le serveur.", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showToast(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? const Color(0xFFFF1744) : const Color(0xFF00C853),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

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
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: const Color(0xFFAB47BC), size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey.shade400, size: 20,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFAB47BC), width: 2)),
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
                // Back button
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
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFFAB47BC)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Icon
                Container(
                  width: 72, height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFFAB47BC), Color(0xFFE91E8C)]),
                  ),
                  child: const Icon(Icons.lock_reset, color: Colors.white, size: 34),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Vérification",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF9B27AF)),
                ),
                const SizedBox(height: 8),
                Text(
                  "Code envoyé à\n${widget.email}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 32),
                // Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.purple.shade100.withOpacity(0.3), blurRadius: 30, spreadRadius: 5)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // OTP field
                      const Text("Code OTP", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF9B27AF))),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _otpController,
                        hint: '_ _ _ _ _ _',
                        icon: Icons.pin_outlined,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                      ),
                      const SizedBox(height: 20),
                      const Text("Nouveau mot de passe", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF9B27AF))),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _passwordController,
                        hint: 'Nouveau mot de passe',
                        icon: Icons.lock_outline,
                        obscure: _obscurePass,
                        toggleObscure: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _confirmController,
                        hint: 'Confirmer le mot de passe',
                        icon: Icons.lock_outline,
                        obscure: _obscureConfirm,
                        toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      const SizedBox(height: 28),
                      // Submit button
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFAB47BC), Color(0xFFE91E8C)]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: const Color(0xFFAB47BC).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                : const Text("Réinitialiser", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Resend
                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            try {
                              await http.post(
                                Uri.parse('$_baseUrl/api/auth/forgot-password'),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({'email': widget.email}),
                              );
                              _showToast("Nouveau code envoyé !", isError: false);
                            } catch (_) {
                              _showToast("Erreur lors de l'envoi.", isError: true);
                            }
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: "Pas reçu le code ? ",
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                              children: [TextSpan(text: "Renvoyer", style: TextStyle(color: Color(0xFFAB47BC), fontWeight: FontWeight.w600, decoration: TextDecoration.underline))],
                            ),
                          ),
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