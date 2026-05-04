// lib/services/location_service.dart
//
// SETUP :
// 1. pubspec.yaml → geolocator: ^11.0.0
// 2. Android → AndroidManifest.xml (avant <application>) :
//    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
//    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
// 3. iOS → Info.plist (dans <dict>) :
//    <key>NSLocationWhenInUseUsageDescription</key>
//    <string>WeJoy utilise votre position pour trouver des personnes proches.</string>

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const String _baseUrl = 'http://localhost:5000';
const Color _rose   = Color(0xFFD63FBF);
const Color _violet = Color(0xFF7C3AED);
const Color _ink    = Color(0xFF0F0F1A);
const Color _slate  = Color(0xFF64748B);
const Color _snow   = Color(0xFFF8FAFC);
const Color _border = Color(0xFFEEEEF5);

// ═══════════════════════════════════════════════════════════════════════════
// EXCEPTION TYPÉE
// ═══════════════════════════════════════════════════════════════════════════
enum LocationExceptionType {
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  timeout,
  unknown,
}

class LocationException implements Exception {
  final LocationExceptionType type;
  final String message;
  const LocationException(this.type, this.message);
  @override
  String toString() => message;
}

// ═══════════════════════════════════════════════════════════════════════════
// SERVICE GPS
// ═══════════════════════════════════════════════════════════════════════════
class LocationService {
  static const _keyLat = 'cached_lat';
  static const _keyLng = 'cached_lng';
  static const _keyTs  = 'cached_location_ts';
  static const _cacheDuration = 5 * 60 * 1000; // 5 minutes en ms

  // ── Vérifier et demander les permissions ─────────────────────────────
  static Future<void> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        LocationExceptionType.serviceDisabled,
        'Le GPS est désactivé sur votre appareil.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          LocationExceptionType.permissionDenied,
          'Permission de localisation refusée.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        LocationExceptionType.permissionPermanentlyDenied,
        'Permission refusée définitivement. Activez-la dans les paramètres.');
    }
  }

  // ── Obtenir la position — avec cache 5 min ───────────────────────────
  static Future<Position> getCachedPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final ts    = prefs.getInt(_keyTs) ?? 0;
    final now   = DateTime.now().millisecondsSinceEpoch;

    if (now - ts < _cacheDuration) {
      final lat = prefs.getDouble(_keyLat);
      final lng = prefs.getDouble(_keyLng);
      if (lat != null && lng != null) {
        return Position(
          latitude:         lat,
          longitude:        lng,
          timestamp:        DateTime.fromMillisecondsSinceEpoch(ts),
          accuracy:         0,
          altitude:         0,
          altitudeAccuracy: 0,
          heading:          0,
          headingAccuracy:  0,
          speed:            0,
          speedAccuracy:    0,
        );
      }
    }
    return _fetchFreshPosition();
  }

  static Future<Position> _fetchFreshPosition() async {
    await _ensurePermission();
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
    } on TimeoutException {
      throw const LocationException(
        LocationExceptionType.timeout,
        'Impossible d\'obtenir le signal GPS. Réessayez.');
    } catch (_) {
      throw const LocationException(
        LocationExceptionType.unknown,
        'Erreur GPS inattendue. Réessayez.');
    }

    // Mettre en cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLat, position.latitude);
    await prefs.setDouble(_keyLng, position.longitude);
    await prefs.setInt(_keyTs, DateTime.now().millisecondsSinceEpoch);

    return position;
  }

  // ── Envoyer la position au backend ───────────────────────────────────
  static Future<void> sendToBackend(Position position) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final res = await http.put(
      Uri.parse('$_baseUrl/api/users/profile/matching'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type':  'application/json',
      },
      body: jsonEncode({
        'location': {
          'latitude':  position.latitude,
          'longitude': position.longitude,
        },
      }),
    );

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Erreur serveur');
    }
  }

  // ── Tout en un ───────────────────────────────────────────────────────
  static Future<Position> locateAndSync() async {
    final position = await getCachedPosition();
    await sendToBackend(position);
    return position;
  }

  // ── Ouvrir les paramètres ────────────────────────────────────────────
  static Future<void> openSettings() => Geolocator.openAppSettings();

  // ── Distance lisible entre deux points ──────────────────────────────
  static String readableDistance(
      double lat1, double lng1, double lat2, double lng2) {
    final meters = Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGET GPS — à intégrer dans ProfileMatchingPage
// ═══════════════════════════════════════════════════════════════════════════
enum _GpsState { idle, loading, success, error }

class GpsLocationWidget extends StatefulWidget {
  final void Function(double lat, double lng)? onLocationSynced;
  const GpsLocationWidget({super.key, this.onLocationSynced});

  @override
  State<GpsLocationWidget> createState() => _GpsLocationWidgetState();
}

class _GpsLocationWidgetState extends State<GpsLocationWidget>
    with SingleTickerProviderStateMixin {
  _GpsState _state    = _GpsState.idle;
  double?   _lat;
  double?   _lng;
  String    _errorMsg = '';

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _loadCache();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final lat   = prefs.getDouble('cached_lat');
    final lng   = prefs.getDouble('cached_lng');
    if (lat != null && lng != null) {
      setState(() { _lat = lat; _lng = lng; _state = _GpsState.success; });
    }
  }

  Future<void> _locate() async {
    setState(() { _state = _GpsState.loading; _errorMsg = ''; });
    try {
      final pos = await LocationService.locateAndSync();
      if (!mounted) return;
      setState(() { _lat = pos.latitude; _lng = pos.longitude; _state = _GpsState.success; });
      widget.onLocationSynced?.call(pos.latitude, pos.longitude);
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() { _state = _GpsState.error; _errorMsg = e.message; });
      if (e.type == LocationExceptionType.permissionPermanentlyDenied) {
        _showSettingsDialog();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _state = _GpsState.error; _errorMsg = 'Erreur inattendue.'; });
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Permission requise',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
        content: const Text(
          'La localisation a été refusée définitivement.\n\n'
          'Activez-la dans Réglages → Applications → WeJoy → Localisation.',
          style: TextStyle(fontSize: 13, height: 1.5)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: _slate, side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Annuler'))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(
            onPressed: () { Navigator.pop(context); LocationService.openSettings(); },
            style: ElevatedButton.styleFrom(
              backgroundColor: _rose, foregroundColor: Colors.white, elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Ouvrir', style: TextStyle(fontWeight: FontWeight.w600)))),
        ])],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = _state == _GpsState.success;
    final isError   = _state == _GpsState.error;
    final isLoading = _state == _GpsState.loading;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuccess ? _rose.withOpacity(0.3)
               : isError   ? Colors.red.withOpacity(0.3)
               : _border,
          width: 1.5),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            // Icône pulsante pendant le chargement
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(
                scale: isLoading ? _pulseAnim.value : 1.0,
                child: child),
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: isSuccess ? _rose.withOpacity(0.1)
                       : isError   ? Colors.red.withOpacity(0.08)
                       : _violet.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14)),
                child: Icon(
                  isSuccess ? Icons.my_location_rounded
                : isError   ? Icons.location_off_rounded
                : Icons.location_on_rounded,
                  color: isSuccess ? _rose
                       : isError   ? Colors.red[400]
                       : _violet,
                  size: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                isSuccess ? 'Position enregistrée'
                : isLoading ? 'Localisation en cours...'
                : isError   ? 'Erreur de localisation'
                : 'Position non renseignée',
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: isError ? Colors.red[700] : _ink)),
              const SizedBox(height: 3),
              Text(
                isSuccess && _lat != null
                  ? '${_lat!.toStringAsFixed(5)}°N  ${_lng!.toStringAsFixed(5)}°E'
                : isLoading ? 'Recherche du signal GPS...'
                : isError   ? _errorMsg
                : 'Requise pour les suggestions proches',
                style: TextStyle(
                  fontSize: 11,
                  color: isError ? Colors.red[400] : _slate.withOpacity(0.6)),
                overflow: TextOverflow.ellipsis),
            ])),
            const SizedBox(width: 10),
            isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(color: _rose, strokeWidth: 2.5))
              : GestureDetector(
                  onTap: _locate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: isSuccess ? null
                        : const LinearGradient(colors: [_rose, _violet]),
                      color: isSuccess ? _snow : null,
                      borderRadius: BorderRadius.circular(10),
                      border: isSuccess ? Border.all(color: _border) : null),
                    child: Text(
                      isSuccess ? 'Actualiser' : 'Localiser',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: isSuccess ? _slate : Colors.white)))),
          ]),
        ),

        // Barre succès
        if (isSuccess)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14))),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded,
                color: Color(0xFF10B981), size: 14),
              const SizedBox(width: 8),
              const Text('Synchronisé avec le serveur WeJoy',
                style: TextStyle(
                  fontSize: 11, color: Color(0xFF10B981),
                  fontWeight: FontWeight.w500)),
            ])),

        // Barre erreur
        if (isError)
          GestureDetector(
            onTap: LocationService.openSettings,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14))),
              child: Row(children: [
                Icon(Icons.settings_rounded, color: Colors.red[400], size: 14),
                const SizedBox(width: 8),
                Text('Ouvrir les paramètres',
                  style: TextStyle(
                    fontSize: 11, color: Colors.red[400],
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline)),
              ])),
          ),
      ]),
    );
  }
}