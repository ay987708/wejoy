import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DailyChallengeCard extends StatelessWidget {
  final Map<String, dynamic>? challenge;
  final bool loading;
  final VoidCallback onJoin;
  const DailyChallengeCard({
    super.key,
    this.challenge,
    required this.loading,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }

    final String title = challenge?['title'] ?? 'Défi du jour';
    final String description = challenge?['description'] ?? 'Relevez un défi et gagnez des points !';
    final int points = challenge?['points'] ?? 10;
    final Color color = _parseColor(challenge?['color']) ?? const Color(0xFFD63FBF);
    final IconData icon = _parseIcon(challenge?['icon']) ?? Icons.emoji_events_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
          Column(
            children: [
              Text('+$points', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF22C55E))),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: onJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(80, 36),
                ),
                child: const Text('Relever'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color? _parseColor(String? colorStr) {
    if (colorStr == null) return null;
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }

  IconData _parseIcon(String? iconStr) {
    return Icons.emoji_events_rounded;
  }
}
