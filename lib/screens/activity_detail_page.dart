import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wejoy/screens/service/api_service.dart'; // adaptez le chemin si besoin

class ActivityDetailPage extends StatelessWidget {
  static const routeName = '/activity-detail';

  const ActivityDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupérer l'activité passée en argument
    final activity = ModalRoute.of(context)!.settings.arguments as Activity;

    return Scaffold(
      appBar: AppBar(
        title: Text(activity.title),
        backgroundColor: const Color(0xFFD63FBF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero doit être placé ici avec le même tag que dans la carte
            Hero(
              tag: 'activity-${activity.id}',
              child: CachedNetworkImage(
                imageUrl: activity.imageUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFFD63FBF))),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 250,
                  color: const Color(0xFFD63FBF).withOpacity(0.1),
                  child: const Icon(Icons.broken_image, size: 50, color: Color(0xFFD63FBF)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et catégorie
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          activity.title,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD63FBF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          activity.category,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFD63FBF), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Text(
                    activity.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Informations supplémentaires
                  _buildInfoRow(Icons.calendar_today_rounded, activity.date ?? 'Date non définie'),
                  if (activity.timeSlot != null)
                    _buildInfoRow(Icons.access_time_rounded, activity.timeSlot!),
                  if (activity.location != null)
                    _buildInfoRow(Icons.location_on_rounded, activity.location!),
                  _buildInfoRow(
                    Icons.people_outline_rounded,
                    activity.participantsLabel,
                  ),
                  const SizedBox(height: 24),

                  // Type d'activité (individuel/collectif)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: activity.isIndividual ? Colors.blue[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          activity.isIndividual ? Icons.person_rounded : Icons.group_rounded,
                          color: activity.isIndividual ? Colors.blue : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          activity.isIndividual ? 'Activité individuelle' : 'Activité collective',
                          style: TextStyle(
                            color: activity.isIndividual ? Colors.blue : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Appeler la méthode pour rejoindre l'activité
          // Ici vous pouvez utiliser le même service que dans HomePage
          // Pour simplifier, on peut retourner un résultat ou utiliser un provider
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fonctionnalité à implémenter')),
          );
        },
        label: Text(activity.isIndividual ? 'Commencer' : 'Rejoindre'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFFD63FBF),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}