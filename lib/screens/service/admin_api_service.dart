import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminApiService extends ChangeNotifier {
  // Change this to your server IP/domain
  static const String baseUrl = 'http://localhost:5001/api';

  String? _token;
  Map<String, dynamic>? _admin;

  bool get isAuthenticated => _token != null;
  Map<String, dynamic>? get admin => _admin;

  AdminApiService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final adminJson = prefs.getString('admin');
    if (adminJson != null) {
      _admin = jsonDecode(adminJson);
    }
    notifyListeners();
  }

  // ✅ Toujours lire le token depuis SharedPreferences — évite le bug du token null
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? _token ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // AUTH
  Future<bool> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _token = data['token'];
        _admin = data['admin'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('admin', jsonEncode(_admin));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _admin = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('admin');
    notifyListeners();
  }

  // DASHBOARD
  Future<Map<String, dynamic>> getDashboard() async {
    final h = await _getHeaders();
    final res = await http.get(Uri.parse('$baseUrl/dashboard'), headers: h);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur dashboard: ${res.statusCode}');
  }

  // USERS
  Future<List<dynamic>> getUsers({String? search}) async {
    final h = await _getHeaders();
    final url = search != null ? '$baseUrl/users?search=$search' : '$baseUrl/users';
    final res = await http.get(Uri.parse(url), headers: h);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur utilisateurs: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final h = await _getHeaders();
    final res = await http.post(Uri.parse('$baseUrl/users'), headers: h, body: jsonEncode(data));
    if (res.statusCode == 201) return jsonDecode(res.body);
    throw Exception('Erreur création utilisateur: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> data) async {
    final h = await _getHeaders();
    final res = await http.put(Uri.parse('$baseUrl/users/$id'), headers: h, body: jsonEncode(data));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur modification utilisateur: ${res.statusCode}');
  }

  Future<void> deleteUser(String id) async {
    final h = await _getHeaders();
    final res = await http.delete(Uri.parse('$baseUrl/users/$id'), headers: h);
    if (res.statusCode != 200) throw Exception('Erreur suppression: ${res.statusCode}');
  }

  Future<void> toggleBlockUser(String id) async {
    final h = await _getHeaders();
    await http.put(Uri.parse('$baseUrl/users/$id/block'), headers: h);
  }

  // SERVICES
  Future<List<dynamic>> getServices() async {
    final h = await _getHeaders();
    final res = await http.get(Uri.parse('$baseUrl/services'), headers: h);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur services: ${res.statusCode} — ${res.body}');
  }

  Future<Map<String, dynamic>> createService(Map<String, dynamic> data) async {
    final h = await _getHeaders();
    final res = await http.post(Uri.parse('$baseUrl/services'), headers: h, body: jsonEncode(data));
    if (res.statusCode == 201) return jsonDecode(res.body);
    throw Exception('Erreur création service: ${res.statusCode} — ${res.body}');
  }

  Future<Map<String, dynamic>> updateService(String id, Map<String, dynamic> data) async {
    final h = await _getHeaders();
    final res = await http.put(Uri.parse('$baseUrl/services/$id'), headers: h, body: jsonEncode(data));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur modification service: ${res.statusCode}');
  }

  Future<void> deleteService(String id) async {
    final h = await _getHeaders();
    final res = await http.delete(Uri.parse('$baseUrl/services/$id'), headers: h);
    if (res.statusCode != 200) throw Exception('Erreur suppression service: ${res.statusCode}');
  }

  // DEMANDES
  Future<Map<String, dynamic>> getDemandes() async {
    final h = await _getHeaders();
    final res = await http.get(Uri.parse('$baseUrl/demandes'), headers: h);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur demandes: ${res.statusCode}');
  }

  Future<void> approuverDemande(String id) async {
    final h = await _getHeaders();
    await http.put(Uri.parse('$baseUrl/demandes/$id/approuver'), headers: h);
  }

  Future<void> rejeterDemande(String id) async {
    final h = await _getHeaders();
    await http.put(Uri.parse('$baseUrl/demandes/$id/rejeter'), headers: h);
  }

  // NOTIFICATIONS ADMIN
  Future<List<dynamic>> getNotifications() async {
    final h = await _getHeaders();
    final res = await http.get(Uri.parse('$baseUrl/admin/notifications'), headers: h);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur notifications: ${res.statusCode}');
  }

  Future<void> sendNotification(Map<String, dynamic> data) async {
    final h = await _getHeaders();
    await http.post(Uri.parse('$baseUrl/admin/notifications'), headers: h, body: jsonEncode(data));
  }

  // STATS
  Future<Map<String, dynamic>> getStats() async {
    final h = await _getHeaders();
    final res = await http.get(Uri.parse('$baseUrl/stats'), headers: h);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur stats: ${res.statusCode}');
  }
//notification
Future<void> updateNotification(String id, Map<String, dynamic> data) async {
  final h = await _getHeaders();
  final res = await http.put(
    Uri.parse('$baseUrl/admin/notifications/$id'),
    headers: h,
    body: jsonEncode(data),
  );

  if (res.statusCode != 200) {
    throw Exception("Erreur modification notif: ${res.statusCode}");
  }
}


Future<void> deleteNotification(String id) async {
  final h = await _getHeaders();
  final res = await http.delete(
    Uri.parse('$baseUrl/admin/notifications/$id'),
    headers: h,
  );

  if (res.statusCode != 200) {
    throw Exception("Erreur suppression notif: ${res.statusCode}");
  }
}
}