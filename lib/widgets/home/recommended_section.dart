import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wejoy/screens/service/api_service.dart';
import 'package:wejoy/screens/activitie_page.dart'; // ← ActivityDetailPage
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
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD63FBF),
              ),
              child: const Text(
                'Voir tout',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
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
          _buildEmptyState()
        else
          SizedBox(
            height: 300,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final activity = activities[index];
                return TweenAnimationBuilder<Offset>(
                  tween: Tween<Offset>(
                    begin: const Offset(0.5, 0),
                    end: Offset.zero,
                  ),
                  duration: Duration(milliseconds: 300 + index * 50),
                  curve: Curves.easeOutQuad,
                  builder: (context, offset, child) {
                    return Transform.translate(
                      offset: offset,
                      child: child,
                    );
                  },
                  // ── CORRECTION : GestureDetector intercepte le tap ──
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActivityDetailPage(activityId: 'activity', // ← objet Activity complet
                        ),
                      ),
                    ),
                    child: ActivityCard(
                      activity: activity,
                      onJoin: onJoin,
                    ),
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE84C88).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mood_rounded,
              size: 40,
              color: const Color(0xFFE84C88).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Choisis ton humeur',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Des activités personnalisées\napparaîtront ici selon comment tu te sens.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
