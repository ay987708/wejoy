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

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

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
    final res = await http.get(Uri.parse('$baseUrl/dashboard'), headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur dashboard');
  }

  // USERS
  Future<List<dynamic>> getUsers({String? search}) async {
    final url = search != null
        ? '$baseUrl/users?search=$search'
        : '$baseUrl/users';
    final res = await http.get(Uri.parse(url), headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur utilisateurs');
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 201) return jsonDecode(res.body);
    throw Exception('Erreur création utilisateur');
  }

  Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur modification utilisateur');
  }

  Future<void> deleteUser(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/users/$id'), headers: _headers);
    if (res.statusCode != 200) throw Exception('Erreur suppression');
  }

  // SERVICES
  Future<List<dynamic>> getServices() async {
    final res = await http.get(Uri.parse('$baseUrl/services'), headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur services');
  }

  Future<Map<String, dynamic>> createService(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/services'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 201) return jsonDecode(res.body);
    throw Exception('Erreur création service');
  }

  Future<Map<String, dynamic>> updateService(int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/services/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur modification service');
  }

  Future<void> deleteService(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/services/$id'), headers: _headers);
    if (res.statusCode != 200) throw Exception('Erreur suppression');
  }

  // DEMANDES
  Future<Map<String, dynamic>> getDemandes() async {
    final res = await http.get(Uri.parse('$baseUrl/demandes'), headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur demandes');
  }

  Future<void> approuverDemande(int id) async {
    await http.put(Uri.parse('$baseUrl/demandes/$id/approuver'), headers: _headers);
  }

  Future<void> rejeterDemande(int id) async {
    await http.put(Uri.parse('$baseUrl/demandes/$id/rejeter'), headers: _headers);
  }

  // NOTIFICATIONS
  Future<List<dynamic>> getNotifications() async {
    final res = await http.get(Uri.parse('$baseUrl/notifications'), headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur notifications');
  }

  Future<void> sendNotification(Map<String, dynamic> data) async {
    await http.post(
      Uri.parse('$baseUrl/notifications'),
      headers: _headers,
      body: jsonEncode(data),
    );
  }

  // STATS
  Future<Map<String, dynamic>> getStats() async {
    final res = await http.get(Uri.parse('$baseUrl/stats'), headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur stats');
  }
}