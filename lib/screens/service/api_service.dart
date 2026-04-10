import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


const String baseUrl = 'http://localhost:5001';

// ✅ Configuration automatique selon la plateforme



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
    try {
      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) return body;
      throw ApiException(
        statusCode: response.statusCode,
        message: body['message'] ?? 'Erreur inconnue',
      );
    } catch (e) {
      if (response.statusCode >= 200 && response.statusCode < 300) return null;
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

  // créer une activité (utilisé par activitie_page)
  Future<Map<String, dynamic>> createActivity(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/activities'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  //  modifier une activité
  Future<Map<String, dynamic>> updateActivity(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/activities/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  // supprimer une activité
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

  //Marquer toutes les notifications comme lues
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
// MODÈLES

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