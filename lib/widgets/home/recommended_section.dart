import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wejoy/screens/service/api_service.dart';
import 'package:wejoy/widgets/home/activity_card.dart';

class RecommendedSection extends StatelessWidget {
  final List<Activity> activities;
  final bool loading;
  final Function(Activity) onJoin;
  final VoidCallback onSeeAll;

  const RecommendedSection({
    super.key,
    required this.activities,
    required this.loading,
    required this.onJoin,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Activités recommandées',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFD63FBF)),
              child: const Text('Voir tout', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (loading)
          SizedBox(
            height: 300,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => _buildShimmerCard(),
            ),
          )
        else if (activities.isEmpty)
          _buildEmptyState('Aucune activité recommandée')
        else
          SizedBox(
            height: 300,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                return TweenAnimationBuilder<Offset>(
                  tween: Tween<Offset>(begin: const Offset(0.5, 0), end: Offset.zero),
                  duration: Duration(milliseconds: 300 + index * 50),
                  curve: Curves.easeOutQuad,
                  builder: (context, offset, child) {
                    return Transform.translate(
                      offset: offset,
                      child: child,
                    );
                  },
                  child: ActivityCard(
                    activity: activities[index],
                    onJoin: onJoin,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        ],
      ),
    );
  }
}
