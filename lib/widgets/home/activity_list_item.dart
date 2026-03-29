import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wejoy/screens/service/api_service.dart';

class ActivityListItem extends StatelessWidget {
  final Activity activity;
  final Function(Activity) onJoin;
  const ActivityListItem({super.key, required this.activity, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/activity-detail', arguments: activity);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'activity-${activity.id}-list',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  color: const Color(0xFFD63FBF).withOpacity(0.1),
                  child: activity.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: activity.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Color(0xFFD63FBF), strokeWidth: 2)),
                          errorWidget: (_, __, ___) => const Icon(Icons.image_rounded, color: Color(0xFFD63FBF)),
                        )
                      : const Icon(Icons.image_rounded, color: Color(0xFFD63FBF)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD63FBF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          activity.category,
                          style: const TextStyle(fontSize: 9, color: Color(0xFFD63FBF), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.description,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (activity.date != null) ...[
                        Icon(Icons.calendar_today_rounded, size: 10, color: Colors.grey[400]),
                        const SizedBox(width: 2),
                        Text(activity.date!, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                        const SizedBox(width: 8),
                      ],
                      Icon(Icons.people_outline_rounded, size: 10, color: Colors.grey[400]),
                      const SizedBox(width: 2),
                      Text(activity.participantsLabel ?? '', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => onJoin(activity),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                activity.isIndividual ? 'Commencer' : 'Rejoindre',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
