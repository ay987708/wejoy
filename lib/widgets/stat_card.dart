import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[600]),
              ),
              Icon(icon, size: 20, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
            style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 4),
          Text(subtitle,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}