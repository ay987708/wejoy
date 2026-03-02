import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogin = true;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  // ================= VALIDATION =================

  bool isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidPassword(String password) {
    final passwordRegex =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
    return passwordRegex.hasMatch(password);
  }

  void validateAndSubmit() {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (!isValidEmail(email)) {
      showMessage("Email invalide");
      return;
    }

    if (!isValidPassword(password)) {
      showMessage(
          "Mot de passe doit contenir au moins 8 caractères,\nune majuscule, une minuscule et un chiffre");
      return;
    }

    if (!isLogin) {
      if (fullnameController.text.trim().isEmpty) {
        showMessage("Nom complet obligatoire");
        return;
      }

      if (password != confirmController.text.trim()) {
        showMessage("Les mots de passe ne correspondent pas");
        return;
      }
    }

    print("Validation réussie");
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // =================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEDE7F6),
              Color(0xFFF3E5F5),
              Color(0xFFFCE4EC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 50),

                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFAB47BC), Color(0xFFE91E8C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.groups,
                    color: Colors.white,
                    size: 38,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  "wejoy",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9B27AF),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Bienvenue dans votre espace bien-être",
                  style: TextStyle(
                    color: Color(0xFFAB47BC),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 30),

                Container(
                  width: 360,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.shade100.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Column(
                    children: [

                      // ===== Onglets Connexion / Inscription =====

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => isLogin = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: isLogin
                                        ? const LinearGradient(
                                            colors: [Color(0xFFAB47BC), Color(0xFFE91E8C)],
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Connexion",
                                      style: TextStyle(
                                        color: isLogin ? Colors.white : Colors.grey,
                                        fontWeight: isLogin ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => isLogin = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: !isLogin
                                        ? const LinearGradient(
                                            colors: [Color(0xFFAB47BC), Color(0xFFE91E8C)],
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Inscription",
                                      style: TextStyle(
                                        color: !isLogin ? Colors.white : Colors.grey,
                                        fontWeight: !isLogin ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      if (!isLogin) ...[
                        _buildTextField(
                          controller: fullnameController,
                          hint: "Nom complet",
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 14),
                      ],

                      _buildTextField(
                        controller: emailController,
                        hint: "Email",
                        icon: Icons.email_outlined,
                      ),

                      const SizedBox(height: 14),

                      _buildTextField(
                        controller: passwordController,
                        hint: "Mot de passe",
                        icon: Icons.lock_outline,
                        obscure: obscurePassword,
                        toggleObscure: () {
                          setState(() =>
                              obscurePassword = !obscurePassword);
                        },
                      ),

                      const SizedBox(height: 14),

                      if (!isLogin) ...[
                        _buildTextField(
                          controller: confirmController,
                          hint: "Confirmer mot de passe",
                          icon: Icons.lock_outline,
                          obscure: obscureConfirm,
                          toggleObscure: () {
                            setState(() =>
                                obscureConfirm = !obscureConfirm);
                          },
                        ),
                        const SizedBox(height: 14),
                      ],

                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFAB47BC), Color(0xFFE91E8C)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: validateAndSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            isLogin ? "Se connecter" : "Créer un compte",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool? obscure,
    VoidCallback? toggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure ?? false,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon:
            Icon(icon, color: const Color(0xFFAB47BC), size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  (obscure ?? false)
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFFAB47BC),
                  size: 20,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
            vertical: 16, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFAB47BC), width: 1.5),
        ),
      ),
    );
  }
}