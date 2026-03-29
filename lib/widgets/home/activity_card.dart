import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wejoy/screens/service/api_service.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final Function(Activity) onJoin;
  const ActivityCard({super.key, required this.activity, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/activity-detail', arguments: activity);
      },
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'activity-${activity.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      height: 110,
                      width: double.infinity,
                      color: Colors.grey[100],
                      child: activity.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: activity.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: Colors.grey[100],
                                child: const Center(child: CircularProgressIndicator(color: Color(0xFFD63FBF), strokeWidth: 2)),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: const Color(0xFFD63FBF).withOpacity(0.1),
                                child: const Center(child: Icon(Icons.image_rounded, size: 30, color: Color(0xFFD63FBF))),
                              ),
                            )
                          : Container(
                              color: const Color(0xFFD63FBF).withOpacity(0.1),
                              child: const Center(child: Icon(Icons.image_rounded, size: 30, color: Color(0xFFD63FBF))),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      activity.isIndividual ? 'Individuel' : 'Collectif',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
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
                    const SizedBox(height: 6),
                    Text(
                      activity.description,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (activity.timeSlot != null)
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 10, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(activity.timeSlot!, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people_outline_rounded, size: 10, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(activity.participantsLabel ?? '', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => onJoin(activity),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A2E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
