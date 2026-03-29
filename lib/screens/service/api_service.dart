import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Configuration automatique selon la plateforme
String get baseUrl {
  return 'http://192.168.1.11:5000';
}

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
    print('💾 Token sauvegardé');
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    print('🗑️ Token effacé');
  }

  // ─── Headers ──────────────────────────────────────────────────────────────
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
    print('📡 Status: ${response.statusCode}');
    try {
      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) return body;
      throw ApiException(
        statusCode: response.statusCode,
        message: body['message'] ?? 'Erreur inconnue',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Erreur de communication avec le serveur',
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AUTH
  // ══════════════════════════════════════════════════════════════════════════

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
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(statusCode: 0, message: 'Impossible de contacter le serveur');
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: await _headers(auth: false),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = _handleResponse(response);
      if (data['token'] != null) {
        await saveToken(data['token']);
      }
      return data;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de contacter le serveur',
      );
    }
  }

  Future<void> logout() async {
    try {
      await http.post(Uri.parse('$baseUrl/api/auth/logout'), headers: await _headers());
    } finally {
      await clearToken();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROFIL
  // ══════════════════════════════════════════════════════════════════════════

  Future<UserProfile?> getMyProfile() async {
    try {
      final token = await getToken();
      if (token == null) return null;
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/me'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserProfile.fromJson(data);
      } else if (response.statusCode == 401) {
        await clearToken();
        throw ApiException(statusCode: 401, message: 'Session expirée');
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Erreur de chargement du profil',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de contacter le serveur',
      );
    }
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/me'),
        headers: await _headers(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      return UserProfile.fromJson(_handleResponse(response));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de mettre à jour le profil',
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACTIVITÉS
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Activity>> getRecommendedActivities() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/activities/recommended'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      final data = _handleResponse(response);
      final List list = data is List ? data : [];
      return list.map((e) => Activity.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Activity>> getAllActivities({String? category, String? search}) async {
    try {
      final params = <String, String>{};
      if (category != null && category != 'Tous') params['category'] = category;
      if (search != null && search.isNotEmpty) params['search'] = search;
      final uri = Uri.parse('$baseUrl/api/activities')
          .replace(queryParameters: params.isEmpty ? null : params);

      final response = await http.get(
        uri,
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      final data = _handleResponse(response);
      final List list = data is List ? data : (data['activities'] is List ? data['activities'] : []);
      return list.map((e) => Activity.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createActivity(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/activities'),
        headers: await _headers(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de créer l\'activité',
      );
    }
  }

  Future<Map<String, dynamic>> updateActivity(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/activities/$id'),
        headers: await _headers(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de modifier l\'activité',
      );
    }
  }

  Future<void> deleteActivity(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/activities/$id'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));
      _handleResponse(response);
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de supprimer l\'activité',
      );
    }
  }

  Future<Activity?> getActivityById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/activities/$id'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      final data = _handleResponse(response);
      return Activity.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<void> joinActivity(String activityId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/activities/$activityId/join'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));
      _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de rejoindre l\'activité',
      );
    }
  }

  Future<void> leaveActivity(String activityId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/activities/$activityId/leave'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));
      _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de quitter l\'activité',
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HUMEUR
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> saveMood(String mood) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/mood'),
        headers: await _headers(),
        body: jsonEncode({'mood': mood}),
      ).timeout(const Duration(seconds: 10));
      _handleResponse(response);
    } catch (e) {
      // On ignore les erreurs d'humeur silencieusement
    }
  }

  Future<String?> getTodayMood() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/mood/today'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      final data = _handleResponse(response);
      return data['mood'];
    } catch (e) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response) ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<void> markNotificationAsRead(String id) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/api/notifications/$id/read'),
        headers: await _headers(),
      );
    } catch (e) {}
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await http.put(
        Uri.parse('$baseUrl/api/notifications/read-all'),
        headers: await _headers(),
      );
    } catch (e) {}
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FIL COMMUNAUTAIRE (NOUVEAU)
  // ══════════════════════════════════════════════════════════════════════════

  /// Récupère les dernières actions des utilisateurs (ex: "Marie a rejoint Yoga")
  Future<List<Map<String, dynamic>>> getCommunityFeed() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/community/feed'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      final data = _handleResponse(response);
      // On s'attend à une liste d'objets avec { username, action, activityTitle, createdAt }
      if (data is List) {
        return data.map((e) {
          return {
            'name': e['username'] ?? 'Anonyme',
            'action': e['action'] ?? 'a interagi avec',
            'activity': e['activityTitle'] ?? 'une activité',
            'time': _formatTimeAgo(e['createdAt']),
          };
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Helper pour formater une date ISO en "il y a X min"
  String _formatTimeAgo(String? isoDate) {
    if (isoDate == null) return 'récemment';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 60) return 'à l\'instant';
      if (difference.inMinutes < 60) return 'il y a ${difference.inMinutes} min';
      if (difference.inHours < 24) return 'il y a ${difference.inHours} h';
      if (difference.inDays < 7) return 'il y a ${difference.inDays} j';
      return 'il y a ${(difference.inDays / 7).floor()} sem';
    } catch (_) {
      return 'récemment';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DÉFI DU JOUR (NOUVEAU)
  // ══════════════════════════════════════════════════════════════════════════

  /// Récupère le défi personnalisé du jour, éventuellement adapté à l'humeur
  Future<Map<String, dynamic>> getDailyChallenge({String? moodName}) async {
    try {
      // On peut envoyer l'humeur en paramètre si le backend le supporte
      final query = moodName != null ? '?mood=$moodName' : '';
      final response = await http.get(
        Uri.parse('$baseUrl/api/challenges/daily$query'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      // En cas d'erreur, on retourne un défi par défaut (fallback)
      return {
        'id': 'default',
        'title': 'Méditation express',
        'description': '5 minutes de respiration consciente',
        'icon': '🧘',
        'color': '#D63FBF',
        'points': 10,
      };
    }
  }

  /// Marque le défi comme commencé / relevé par l'utilisateur
  Future<void> startChallenge(String challengeId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/challenges/$challengeId/start'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de démarrer le défi',
      );
    }
  }

  /// Optionnel : Récupère l'historique des défis de l'utilisateur
  Future<List<dynamic>> getUserChallenges() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/me/challenges'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response) ?? [];
    } catch (e) {
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEALTH CHECK
  // ══════════════════════════════════════════════════════════════════════════

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
      ).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
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

// ══════════════════════════════════════════════════════════════════════════════
// MODÈLES
// ══════════════════════════════════════════════════════════════════════════════

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

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id:          json['_id']         ?? json['id']         ?? '',
      username:    json['username']    ?? json['name']       ?? 'Utilisateur',
      email:       json['email']       ?? '',
      memberSince: json['memberSince'] ?? json['createdAt']  ?? 'mars 2026',
      points:      json['points']      ?? 0,
      badges:      (json['badges'] is List)
                    ? (json['badges'] as List).length
                    : (json['badges'] ?? json['badgeCount'] ?? 0),
      interests:   List<String>.from(json['interests'] ?? []),
      avatarUrl:   json['avatarUrl']   ?? json['avatar'],
    );
  }

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
  final int currentParticipants;
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
    this.currentParticipants = 0,
    this.maxParticipants,
    this.isIndividual = false,
    this.isDaily = false,
    this.createdBy,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id:                  json['_id']                 ?? json['id']    ?? '',
      title:               json['title']               ?? '',
      category:            json['category']            ?? '',
      description:         json['description']         ?? '',
      imageUrl:            json['imageUrl']             ?? json['image'] ?? '',
      isOfficial:          json['isOfficial']          ?? false,
      date:                json['date'],
      timeSlot:            json['timeSlot']             ?? json['time'],
      location:            json['location'],
      currentParticipants: json['currentParticipants'] ?? 0,
      maxParticipants:     json['maxParticipants'],
      isIndividual:        json['isIndividual']         ?? json['type'] == 'individual',
      isDaily:             json['isDaily']              ?? false,
      createdBy:           json['createdBy'] is Map
                            ? Map<String, dynamic>.from(json['createdBy'])
                            : null,
    );
  }

  String get participantsLabel {
    if (maxParticipants != null && maxParticipants! > 0) {
      return '$currentParticipants/$maxParticipants participants';
    }
    return '$currentParticipants participants';
  }
}