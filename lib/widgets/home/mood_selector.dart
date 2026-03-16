import 'package:flutter/material.dart';

enum Mood { excellent, bien, neutre, triste, besoinSoutien }

class MoodSelector extends StatelessWidget {
  final Mood? selectedMood;
  final ValueChanged<Mood> onMoodSelected;
  const MoodSelector({super.key, required this.selectedMood, required this.onMoodSelected});

  final List<Map<String, dynamic>> moods = const [
    {'label': 'Excellent', 'emoji': '🌟', 'color': Color(0xFF22C55E), 'mood': Mood.excellent},
    {'label': 'Bien',      'emoji': '😊', 'color': Color(0xFF3B82F6), 'mood': Mood.bien},
    {'label': 'Neutre',    'emoji': '😐', 'color': Color(0xFFF59E0B), 'mood': Mood.neutre},
    {'label': 'Triste',    'emoji': '😟', 'color': Color(0xFFEF4444), 'mood': Mood.triste},
    {'label': 'Besoin de\nsoutien', 'emoji': '🤍', 'color': Color(0xFFD63FBF), 'mood': Mood.besoinSoutien},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Comment vous sentez-vous aujourd'hui ?",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: moods.map((m) {
              final isSelected = selectedMood == m['mood'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onMoodSelected(m['mood'] as Mood),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? (m['color'] as Color).withOpacity(0.1) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? (m['color'] as Color) : Colors.grey[200]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          m['emoji'] as String,
                          style: TextStyle(fontSize: isSelected ? 24 : 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m['label'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? (m['color'] as Color) : Colors.grey[600],
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
