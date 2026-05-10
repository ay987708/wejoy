import 'package:flutter/material.dart';
import 'package:wejoy/screens/service/api_service.dart';

class EditProfilePage extends StatefulWidget {
  final UserProfile user;
  final VoidCallback onProfileUpdated;

  const EditProfilePage({
    super.key,
    required this.user,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _api = ApiService();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _saving = false;
  String? _selectedAvatar;
  List<String> _selectedInterests = [];

  // Avatars disponibles
  final List<Map<String, dynamic>> _avatars = [
    {'emoji': '😊', 'color': const Color(0xFF6366F1)},
    {'emoji': '🦊', 'color': const Color(0xFFD63FBF)},
    {'emoji': '🐱', 'color': const Color(0xFF22C55E)},
    {'emoji': '🦁', 'color': const Color(0xFFEAB308)},
    {'emoji': '🐼', 'color': const Color(0xFF3B82F6)},
    {'emoji': '🦋', 'color': const Color(0xFFEC4899)},
    {'emoji': '🌟', 'color': const Color(0xFFF59E0B)},
    {'emoji': '🎭', 'color': const Color(0xFF8B5CF6)},
    {'emoji': '🌸', 'color': const Color(0xFFFF6B9D)},
    {'emoji': '🔥', 'color': const Color(0xFFEF4444)},
    {'emoji': '💎', 'color': const Color(0xFF06B6D4)},
    {'emoji': '🚀', 'color': const Color(0xFF1A1A2E)},
  ];

  // Centres d'intérêt disponibles
  final List<Map<String, dynamic>> _allInterests = [
    {'label': 'Cuisine', 'emoji': '🍳'},
    {'label': 'Lecture', 'emoji': '📚'},
    {'label': 'Jardinage', 'emoji': '🌱'},
    {'label': 'Yoga', 'emoji': '🧘'},
    {'label': 'Sport', 'emoji': '⚽'},
    {'label': 'Musique', 'emoji': '🎵'},
    {'label': 'Voyage', 'emoji': '✈️'},
    {'label': 'Photographie', 'emoji': '📸'},
    {'label': 'Peinture', 'emoji': '🎨'},
    {'label': 'Danse', 'emoji': '💃'},
    {'label': 'Méditation', 'emoji': '🧘'},
    {'label': 'Autre', 'emoji': '✨'},
  ];

  // Complétion du profil
  int get _completionScore {
    int score = 0;
    if (_usernameController.text.isNotEmpty) score += 30;
    if (_selectedAvatar != null) score += 30;
    if (_selectedInterests.isNotEmpty) score += 40;
    return score;
  }

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.user.username;
    _selectedInterests = List.from(widget.user.interests);
    _selectedAvatar = widget.user.avatarUrl;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _api.updateProfile({
        'username': _usernameController.text.trim(),
        'interests': _selectedInterests,
        'avatarUrl': _selectedAvatar ?? '',
      });
      if (!mounted) return;
      widget.onProfileUpdated();
      _showSuccessAnimation();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              const Text('Profil mis à jour !', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Vos modifications ont été sauvegardées', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // ferme dialog
                  Navigator.pop(context); // retour profil
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD63FBF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Super !', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Modifier mon profil', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _saving
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFD63FBF), strokeWidth: 2)))
                : TextButton(
                    onPressed: _save,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFD63FBF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Sauvegarder', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Complétion du profil ────────────────────────────────────
              _buildCompletionCard(),
              const SizedBox(height: 20),

              // ── Avatar ──────────────────────────────────────────────────
              _buildSectionTitle('Choisir un avatar', '🎭'),
              const SizedBox(height: 12),
              _buildAvatarSection(),
              const SizedBox(height: 20),

              // ── Nom d'utilisateur ────────────────────────────────────────
              _buildSectionTitle('Informations personnelles', '👤'),
              const SizedBox(height: 12),
              _buildInfoSection(),
              const SizedBox(height: 20),

              // ── Centres d'intérêt ────────────────────────────────────────
              _buildSectionTitle('Centres d\'intérêt', '⭐'),
              const SizedBox(height: 4),
              Text('Sélectionnez au moins un centre d\'intérêt', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              const SizedBox(height: 12),
              _buildInterestsSection(),
              const SizedBox(height: 32),

              // ── Bouton sauvegarder ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD63FBF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Sauvegarder les modifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionCard() {
    final score = _completionScore;
    final color = score == 100 ? const Color(0xFF22C55E) : (score >= 60 ? const Color(0xFFEAB308) : const Color(0xFFD63FBF));

    return StatefulBuilder(
      builder: (context, setLocal) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Complétion du profil', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('$score%', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              if (score < 100) ...[
                const SizedBox(height: 8),
                Text(
                  score < 30 ? '💡 Commence par choisir un nom' : score < 60 ? '💡 Choisis un avatar !' : '💡 Ajoute des centres d\'intérêt !',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ] else ...[
                const SizedBox(height: 8),
                const Text('✅ Profil complet !', style: TextStyle(fontSize: 11, color: Color(0xFF22C55E), fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, String emoji) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildAvatarSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        children: [
          // Avatar sélectionné
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFFD63FBF), Color(0xFF9C27B0)]),
                boxShadow: [BoxShadow(color: const Color(0xFFD63FBF).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Center(
                child: Text(
                  _selectedAvatar ?? '👤',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Sélectionne ton avatar', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 12),
          // Grille avatars
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _avatars.length,
            itemBuilder: (_, i) {
              final avatar = _avatars[i];
              final isSelected = _selectedAvatar == avatar['emoji'];
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = avatar['emoji'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? (avatar['color'] as Color).withOpacity(0.15) : Colors.grey[50],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? avatar['color'] as Color : Colors.grey[200]!,
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(avatar['emoji'] as String, style: TextStyle(fontSize: isSelected ? 24 : 20)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _usernameController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Nom d\'utilisateur',
              labelStyle: const TextStyle(color: Color(0xFFD63FBF)),
              prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFFD63FBF)),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD63FBF), width: 1.5),
              ),
              counterText: '${_usernameController.text.length}/30',
            ),
            maxLength: 30,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Le nom ne peut pas être vide';
              if (v.trim().length < 2) return 'Au moins 2 caractères';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD63FBF).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD63FBF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ce nom sera visible par les autres membres de la communauté.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_selectedInterests.length} sélectionné(s)', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              if (_selectedInterests.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _selectedInterests.clear()),
                  child: const Text('Tout effacer', style: TextStyle(fontSize: 12, color: Color(0xFFD63FBF), fontWeight: FontWeight.w500)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _allInterests.map((interest) {
              final label = interest['label'] as String;
              final emoji = interest['emoji'] as String;
              final isSelected = _selectedInterests.contains(label);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(label);
                    } else {
                      _selectedInterests.add(label);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFD63FBF).withOpacity(0.1) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFD63FBF) : Colors.grey[200]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? const Color(0xFFD63FBF) : Colors.grey[700],
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFFD63FBF)),
                      ],
                    ],
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
