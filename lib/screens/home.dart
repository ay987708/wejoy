import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wejoy/screens/activitie_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  File? _image;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.chat_bubble_outline, color: Colors.purple),
            SizedBox(width: 8),
            Text(
              "Wejoy",
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: const [
          Icon(Icons.notifications_none, color: Colors.black),
          SizedBox(width: 15)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ===== MENU =====
            const MainMenu(),

            const SizedBox(height: 20),

            /// ===== WELCOME =====
            const WelcomeSection(),

            const SizedBox(height: 20),

            /// ===== PROFILE CARD WITH AVATAR =====
            ProfileCard(
              image: _image,
              onAvatarTap: pickImage,
            ),

            const SizedBox(height: 20),

            /// ===== MOOD SECTION =====
            const MoodSection(),
          ],
        ),
      ),
    );
  }
}

/* ================= MENU PRINCIPAL ================= */

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [

          MenuItem(icon: Icons.home, label: "Accueil", onTap: () {}),

          MenuItem(
            icon: Icons.event,
            label: "Activités",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>  ActivitiePage(),
                ),
              );
            },
          ),

          MenuItem(icon: Icons.videogame_asset, label: "Jeux", onTap: () {}),

          MenuItem(icon: Icons.check_box, label: "Tâches", onTap: () {}),

          // ❌ GROUPES SUPPRIMÉ

          MenuItem(icon: Icons.emoji_events, label: "Récompenses", onTap: () {}),
        ],
      ),
    );
  }
}




/* ================= MENU ITEM ================= */

class MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const MenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}




/* ================= WELCOME ================= */

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Bienvenue 👋",
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        Text(
          "Connectez-vous et profitez de votre communauté.",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}




/* ================= PROFILE CARD ================= */

class ProfileCard extends StatelessWidget {
  final File? image;
  final VoidCallback onAvatarTap;

  const ProfileCard({
    super.key,
    required this.image,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [

          GestureDetector(
            onTap: onAvatarTap,
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  image != null ? FileImage(image!) : null,
              child: image == null
                  ? const Icon(Icons.camera_alt)
                  : null,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Utilisateur",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "Membre actif",
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}




/* ================= MOOD ================= */

class MoodSection extends StatelessWidget {
  const MoodSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Comment vous sentez-vous aujourd'hui ?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: const [
            MoodChip("Excellent"),
            MoodChip("Bien"),
            MoodChip("Neutre"),
            MoodChip("Triste"),
            MoodChip("Besoin de soutien"),
          ],
        )
      ],
    );
  }
}

class MoodChip extends StatelessWidget {
  final String label;

  const MoodChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}