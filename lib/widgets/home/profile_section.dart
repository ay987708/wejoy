import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wejoy/screens/service/api_service.dart';

class ProfileSection extends StatelessWidget {
  final UserProfile? user;
  final bool loading;
  final bool detailed;
  const ProfileSection({super.key, this.user, required this.loading, this.detailed = false});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: detailed ? 300 : 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }

    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Center(child: Text('Profil non disponible')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text('Mon Profil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              if (detailed)
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFD63FBF),
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Modifier'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Hero(
                tag: 'profile-avatar',
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFFD63FBF), Color(0xFF9C27B0)]),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD63FBF).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: user!.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: user!.avatarUrl!,
                              fit: BoxFit.cover,
                              width: 66,
                              height: 66,
                              placeholder: (_, __) => const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              errorWidget: (_, __, ___) => const Text('👤', style: TextStyle(fontSize: 30)),
                            ),
                          )
                        : const Text('👤', style: TextStyle(fontSize: 30)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user!.username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Membre depuis ${user!.memberSince}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.star_outline_rounded, size: 14, color: const Color(0xFFD63FBF)),
              const SizedBox(width: 4),
              Text(
                "Centres d'intérêt",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          user!.interests.isEmpty
              ? Text(
                  'Aucun centre d\'intérêt défini',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user!.interests.map((interest) {
                    const icons = {
                      'Cuisine': '🍳',
                      'Lecture': '📚',
                      'Jardinage': '🌱',
                      'Yoga': '🧘',
                      'Sport': '⚽',
                      'Autre': '✨'
                    };
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD63FBF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(icons[interest] ?? '•', style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            interest,
                            style: const TextStyle(fontSize: 12, color: Color(0xFFD63FBF), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        '${user!.points}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFEAB308)),
                      ),
                      Text('Points', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Container(width: 1, height: 50, color: Colors.grey[300]),
                Expanded(
                  child: Column(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        '${user!.badges}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFD63FBF)),
                      ),
                      Text('Badges', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4)),
      ],
    );
  }
}
