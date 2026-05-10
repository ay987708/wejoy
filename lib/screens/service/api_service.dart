import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


const String baseUrl = 'http://localhost:5000';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  // ─── Gestion du token ─────────────────────────────────────────────────────
  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    print('Token sauvegardé');
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    print('Token effacé');
  }

  // ─── Headers ─────────────────────────────────────────────────────────────
  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ─── Gestion des réponses ─────────────────────────────────────────────────
 dynamic _handleResponse(http.Response response) {
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');

  if (response.statusCode >= 200 && response.statusCode < 300) {
    if (response.body.isEmpty) {
      return {};
    }

    try {
      return jsonDecode(response.body);
    } catch (e) {
      return {};
    }
  }

  try {
    final body = jsonDecode(response.body);
    throw ApiException(
      statusCode: response.statusCode,
      message: body['message'] ?? 'Erreur inconnue',
    );
  } catch (e) {
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Erreur de communication avec le serveur',
    );
  }
}

  // ════════════════════════════════════════════════════════════════════════
  // AUTH
  // ════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: await _headers(auth: false),
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));
      final data = _handleResponse(response);
      if (data['token'] != null) await saveToken(data['token']);
      return data;
    } catch (e) {
      throw ApiException(statusCode: 0, message: 'Impossible de contacter le serveur');
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: await _headers(auth: false),
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  Future<void> logout() async {
    try {
      await http.post(Uri.parse('$baseUrl/api/auth/logout'), headers: await _headers());
    } finally {
      await clearToken();
    }
  }

  // ─── Mot de passe oublié — envoie l'OTP par email ────────────────────────
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/forgot-password'),
        headers: await _headers(auth: false),
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Code envoyé.',
      };
    } catch (e) {
      throw ApiException(statusCode: 0, message: 'Impossible de contacter le serveur');
    }
  }

  // ─── Réinitialisation du mot de passe avec OTP ───────────────────────────
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/reset-password'),
        headers: await _headers(auth: false),
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Erreur.',
      };
    } catch (e) {
      throw ApiException(statusCode: 0, message: 'Impossible de contacter le serveur');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // PROFIL
  // ════════════════════════════════════════════════════════════════════════

  Future<UserProfile?> getMyProfile() async {
    try {
      final token = await getToken();
      if (token == null) return null;
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/me'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) return UserProfile.fromJson(jsonDecode(response.body));
      if (response.statusCode == 401) { await clearToken(); throw ApiException(statusCode: 401, message: 'Session expirée'); }
      throw ApiException(statusCode: response.statusCode, message: 'Erreur de chargement du profil');
    } catch (e) { rethrow; }
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/users/me'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return UserProfile.fromJson(_handleResponse(response));
  }

  // ACTIVITÉS

  Future<List<Activity>> getRecommendedActivities() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/activities/recommended'),
        headers: await _headers(),
      );
      final List data = _handleResponse(response);
      return data.map((e) => Activity.fromJson(e)).toList();
    } catch (e) { return []; }
  }

  Future<List<Activity>> getAllActivities({String? category, String? search}) async {
    try {
      final params = <String, String>{};
      if (category != null && category != 'Tous') params['category'] = category;
      if (search != null && search.isNotEmpty) params['search'] = search;
      final uri = Uri.parse('$baseUrl/api/activities')
          .replace(queryParameters: params.isEmpty ? null : params);
      final response = await http.get(uri, headers: await _headers());
      final List data = _handleResponse(response);
      return data.map((e) => Activity.fromJson(e)).toList();
    } catch (e) { return []; }
  }

  Future<Map<String, dynamic>> createActivity(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/activities'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateActivity(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/activities/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<void> deleteActivity(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/activities/$id'),
      headers: await _headers(),
    );
    _handleResponse(response);
  }

  Future<void> joinActivity(String activityId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/activities/$activityId/join'),
      headers: await _headers(),
    );
    _handleResponse(response);
  }

  Future<void> leaveActivity(String activityId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/activities/$activityId/leave'),
      headers: await _headers(),
    );
    _handleResponse(response);
  }

  // HUMEUR

  Future<void> saveMood(String mood) async {
    await http.post(
      Uri.parse('$baseUrl/api/moods'),
      headers: await _headers(),
      body: jsonEncode({'mood': mood, 'date': DateTime.now().toIso8601String()}),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // JOURNAL
  // ════════════════════════════════════════════════════════════════════════

  // ── Analyser le sentiment d'un texte (Gemini via backend) ────────────────
  Future<Map<String, dynamic>> analyzeSentiment(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/journal/analyze'),
        headers: await _headers(),
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      return {'sentiment': 'Neutre', 'score': 0, 'message': 'Analyse indisponible'};
    }
  }

  // ── Détecteur de mood IA en temps réel (badge) ────────────────────────────
  // Retourne : { 'mood': 'mélancolie', 'emoji': '💜' }
  Future<Map<String, dynamic>> analyzeMood(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/journal/analyze-mood'),
        headers: await _headers(),
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      return {};
    }
  }

  // ── Réponse wellness Joya après soumission ────────────────────────────────
  // Retourne : { 'response': '...' }
  Future<String?> getJoyaResponse({
    required String text,
    required String moodLabel,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/journal/joya-response'),
        headers: await _headers(),
        body: jsonEncode({'text': text, 'moodLabel': moodLabel}),
      ).timeout(const Duration(seconds: 15));

      final data = _handleResponse(response);
      return data['response'] as String?;
    } catch (e) {
      return null;
    }
  }

  // ── Créer une nouvelle entrée ─────────────────────────────────────────────
  Future<Map<String, dynamic>> createJournalEntry({
    required String content,
    required int moodValue,
    List<String> tags = const [],
    String? sentiment,
    double? sentimentScore,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/journal/entries'),
      headers: await _headers(),
      body: jsonEncode({
        'content':        content.trim(),
        'moodValue':      moodValue,
        'tags':           tags,
        if (sentiment != null) 'sentiment': sentiment,
        if (sentimentScore != null) 'sentimentScore': sentimentScore,
      }),
    ).timeout(const Duration(seconds: 12));

    return _handleResponse(response);
  }

  // ── Récupérer les entrées (paginées) ─────────────────────────────────────
  Future<Map<String, dynamic>> getJournalEntries({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/journal/entries').replace(
        queryParameters: {
          'page':  page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: await _headers(),
      ).timeout(const Duration(seconds: 12));

      return _handleResponse(response);
    } catch (e) {
      return {'entries': [], 'pagination': {}};
    }
  }

  // ── Récupérer une entrée par ID ───────────────────────────────────────────
  Future<Map<String, dynamic>> getJournalEntry(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/journal/entries/$id'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 10));

    return _handleResponse(response);
  }

  // ── Modifier une entrée ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> updateJournalEntry(
    String id, {
    String? content,
    List<String>? tags,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/journal/entries/$id'),
      headers: await _headers(),
      body: jsonEncode({
        if (content != null) 'content': content.trim(),
        if (tags != null) 'tags': tags,
      }),
    ).timeout(const Duration(seconds: 12));

    return _handleResponse(response);
  }

  // ── Supprimer une entrée ──────────────────────────────────────────────────
  Future<void> deleteJournalEntry(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/journal/entries/$id'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 10));

    _handleResponse(response);
  }

  // ── Stats complètes ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getJournalStats({
    String period = 'week',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/journal/stats').replace(
        queryParameters: {'period': period},
      );

      final response = await http.get(
        uri,
        headers: await _headers(),
      ).timeout(const Duration(seconds: 12));

      return _handleResponse(response);
    } catch (e) {
      return {
        'totalEntries':    0,
        'avgMoodValue':    0,
        'avgMoodLabel':    'Neutre',
        'wellnessScore':   0,
        'streak':          0,
        'moodDistribution': [],
        'weeklyMoods':     [],
        'topTags':         [],
        'weeklySummary':   'Impossible de charger les stats.',
      };
    }
  }

  // NOTIFICATIONS

  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications'),
        headers: await _headers(),
      );
      return _handleResponse(response);
    } catch (e) { return []; }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await http.put(
        Uri.parse('$baseUrl/api/notifications/tout-lire'),
        headers: await _headers(),
      );
    } catch (_) {}
  }

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  Future<void> startChallenge(param0) async {}

  Future<dynamic> getDailyChallenge({String? moodName}) async {}

  Future<dynamic> getCommunityFeed() async {}

  Future<void> contactAdmin({required String sujet, required String message}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/demandes'),
      headers: await _headers(),
      body: jsonEncode({
        'titre':   sujet,
        'message': message,
      }),
    );
    _handleResponse(response);
  }
}

// ─── Exception ────────────────────────────────────────────────────────────────
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException({required this.statusCode, required this.message});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ─── MODÈLES ──────────────────────────────────────────────────────────────────

class UserProfile {
  final String id;
  final String username;
  final String email;
  final String memberSince;
  final int points;
  final int badges;
  final List<String> interests;
  final String? avatarUrl;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.memberSince,
    required this.points,
    required this.badges,
    required this.interests,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id:           json['_id'] ?? json['id'] ?? '',
    username:     json['username'] ?? json['name'] ?? 'Utilisateur',
    email:        json['email'] ?? '',
    memberSince:  json['memberSince'] ?? json['createdAt'] ?? json['joinedAt'] ?? 'Janvier 2025',
    points:       json['points'] ?? 1250,
    badges:       (json['badges'] is List) ? (json['badges'] as List).length : (json['badges'] ?? 3),
    interests:    List<String>.from(json['interests'] ?? ['Cuisine', 'Lecture']),
    avatarUrl:    json['avatarUrl'] ?? json['avatar'],
  );

  Map<String, dynamic> toJson() => {
    'username':  username,
    'interests': interests,
    'avatarUrl': avatarUrl,
  };
}

class Activity {
  final String id;
  final String title;
  final String category;
  final String description;
  final String imageUrl;
  final bool isOfficial;
  final String? date;
  final String? timeSlot;
  final String? location;
  final int? currentParticipants;
  final int? maxParticipants;
  final bool isIndividual;
  final bool isDaily;
  final Map<String, dynamic>? createdBy;

  Activity({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.imageUrl,
    this.isOfficial = false,
    this.date,
    this.timeSlot,
    this.location,
    this.currentParticipants,
    this.maxParticipants,
    this.isIndividual = false,
    this.isDaily = false,
    this.createdBy,
  });

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    id:                  json['_id'] ?? json['id'] ?? '',
    title:               json['title'] ?? '',
    category:            json['category'] ?? '',
    description:         json['description'] ?? '',
    imageUrl:            json['imageUrl'] ?? json['image'] ?? '',
    isOfficial:          json['isOfficial'] ?? false,
    date:                json['date'],
    timeSlot:            json['timeSlot'] ?? json['time'],
    location:            json['location'],
    currentParticipants: json['currentParticipants'],
    maxParticipants:     json['maxParticipants'],
    isIndividual:        json['isIndividual'] ?? json['type'] == 'individual',
    isDaily:             json['isDaily'] ?? false,
    createdBy:           json['createdBy'] is Map ? Map<String, dynamic>.from(json['createdBy']) : null,
  );

  String? get participantsLabel {
    if (currentParticipants == null || maxParticipants == null) return null;
    return '$currentParticipants/$maxParticipants';
  }
}