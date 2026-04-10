import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:wejoy/screens/service/api_service.dart';

// Navigation :
// Navigator.pushNamed(context, ActivityDetailPage.routeName, arguments: activity)
// OU
// Navigator.push(..., MaterialPageRoute(builder: (_) => ActivityDetailPage.fromId(id: activity.id)))

class ActivityDetailPage extends StatefulWidget {
  static const routeName = '/activity-detail';

  final Activity? activity;
  final String? activityId;

  const ActivityDetailPage({
    super.key,
    this.activity,
    this.activityId,
  });

  static Widget fromId({required String id}) =>
      ActivityDetailPage(activityId: id);

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  static const String _baseUrl = 'http://localhost:5000';

  Activity? _activity;
  bool _loading = true;
  bool _isMember = false;

  @override
  void initState() {
    super.initState();

    if (widget.activity != null) {
      _activity = widget.activity;
      _loading = false;
    } else {
      _fetchDetail();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_activity == null && widget.activityId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is Activity) {
        setState(() {
          _activity = args;
          _loading = false;
        });
      } else if (args is String && args.isNotEmpty) {
        _fetchDetailById(args);
      }
    }
  }

  Future<String?> _tok() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('auth_token');
  }

  Future<void> _fetchDetail() async {
    final id = widget.activityId;
    if (id == null || id.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    await _fetchDetailById(id);
  }

  Future<void> _fetchDetailById(String id) async {
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      final token = await _tok();

      final res = await http.get(
        Uri.parse('$_baseUrl/api/activities/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (!mounted) return;
        setState(() {
          _activity = Activity.fromJson(data);
          _isMember = data['isMember'] == true;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggleJoin() async {
    if (_activity == null) return;

    final api = ApiService();

    try {
      if (_isMember) {
        await api.leaveActivity(_activity!.id);
      } else {
        await api.joinActivity(_activity!.id);
      }

      if (!mounted) return;

      setState(() => _isMember = !_isMember);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isMember
                ? 'Vous avez rejoint l\'activité ! +50 points 🎉'
                : 'Vous avez quitté l\'activité',
          ),
          backgroundColor:
              _isMember ? const Color(0xFF10B981) : Colors.grey,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFD63FBF),
          ),
        ),
      );
    }

    if (_activity == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFD63FBF),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Activité introuvable',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final activity = _activity!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          activity.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFFD63FBF),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: GestureDetector(
              onTap: _toggleJoin,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _isMember
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  _isMember ? 'Quitter' : 'Rejoindre',
                  style: TextStyle(
                    color: _isMember
                        ? Colors.white
                        : const Color(0xFFD63FBF),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            activity.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: activity.imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        _imgPlaceholder(activity.category),
                  )
                : _imgPlaceholder(activity.category),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD63FBF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      activity.category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFD63FBF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F0F1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _infoRow(
                    Icons.calendar_today_rounded,
                    activity.date ?? 'Date non définie',
                  ),
                  if (activity.timeSlot != null)
                    _infoRow(Icons.access_time_rounded, activity.timeSlot!),
                  if (activity.location != null)
                    _infoRow(Icons.location_on_rounded, activity.location!),
                  _infoRow(
                    Icons.people_outline_rounded,
                    activity.participantsLabel ??
                        '${activity.currentParticipants} participants',
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: activity.isIndividual
                          ? Colors.blue.withOpacity(0.08)
                          : Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          activity.isIndividual
                              ? Icons.person_rounded
                              : Icons.group_rounded,
                          color: activity.isIndividual
                              ? Colors.blue
                              : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          activity.isIndividual
                              ? 'Activité individuelle'
                              : 'Activité collective',
                          style: TextStyle(
                            color: activity.isIndividual
                                ? Colors.blue
                                : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _toggleJoin,
                      icon: Icon(
                        _isMember
                            ? Icons.exit_to_app_rounded
                            : Icons.add_rounded,
                      ),
                      label: Text(
                        _isMember
                            ? 'Quitter l\'activité'
                            : 'Rejoindre l\'activité',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isMember
                            ? Colors.grey[200]
                            : const Color(0xFFD63FBF),
                        foregroundColor:
                            _isMember ? Colors.grey[700] : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder(String category) {
    const emojis = {
      'Cuisine': '🍳',
      'Lecture': '📚',
      'Jardinage': '🌱',
      'Yoga': '🧘',
      'Sport': '⚽',
      'Autre': '✨',
    };

    return Container(
      height: 220,
      width: double.infinity,
      color: const Color(0xFFD63FBF).withOpacity(0.07),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emojis[category] ?? '✨',
            style: const TextStyle(fontSize: 60),
          ),
          const SizedBox(height: 8),
          Text(
            category,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFD63FBF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}