import 'package:flutter/material.dart';

class MoodOption {
  final String emoji;
  final String label;
  final Color color;
  final int value;

  const MoodOption({
    required this.emoji,
    required this.label,
    required this.color,
    required this.value,
  });
}

const List<MoodOption> kMoods = [
  MoodOption(
    emoji: '😢',
    label: 'Triste',
    color: Color(0xFF6B8EAD),
    value: 1,
  ),
  MoodOption(
    emoji: '😰',
    label: 'Anxieux',
    color: Color(0xFFB39DDB),
    value: 2,
  ),
  MoodOption(
    emoji: '😐',
    label: 'Neutre',
    color: Color(0xFF90A4AE),
    value: 3,
  ),
  MoodOption(
    emoji: '🙂',
    label: 'Bien',
    color: Color(0xFFA855F7),
    value: 4,
  ),
  MoodOption(
    emoji: '🤩',
    label: 'Euphorique',
    color: Color(0xFFF472B6),
    value: 5,
  ),
];
