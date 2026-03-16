import 'package:flutter/material.dart';
import 'package:wejoy/screens/service/api_service.dart';

class WelcomeCard extends StatelessWidget {
  final UserProfile? user;
  final bool loading;
  const WelcomeCard({super.key, this.user, required this.loading});

  @override
  Widget build(BuildContext context) {
    final name = loading ? '...' : (user?.username ?? '');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD63FBF), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD63FBF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue, $name !',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Connectez-vous, partagez et épanouissez-vous avec votre communauté.',
                  style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const Text('👋', style: TextStyle(fontSize: 40)),
        ],
      ),
    );
  }
}
