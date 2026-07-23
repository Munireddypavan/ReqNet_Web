import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String? _customBaseUrl;

  static Future<void> loadCustomBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customBaseUrl = prefs.getString('resqnet_custom_url');
    } catch (_) {}
  }

  static Future<void> setCustomBaseUrl(String url) async {
    final cleaned = url.trim();
    _customBaseUrl = cleaned;
    final prefs = await SharedPreferences.getInstance();
    if (cleaned.isEmpty) {
      _customBaseUrl = null;
      await prefs.remove('resqnet_custom_url');
    } else {
      // Ensure protocol is included
      String formattedUrl = cleaned;
      if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
        formattedUrl = 'http://$formattedUrl';
      }
      _customBaseUrl = formattedUrl;
      await prefs.setString('resqnet_custom_url', formattedUrl);
    }
  }

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Windows machine IP (WiFi) — update this if your IP changes
      return 'http://10.164.63.204:8080';
    } else {
      return 'http://localhost:8080';
    }
  }

  static Future<Map<String, dynamic>> login(String usernameOrEmail, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usernameOrEmail': usernameOrEmail,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'user': data['user'], 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': _friendlyError(e)};
    }
  }

  static Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String username,
    required String password,
    required String phone,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/signup');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'username': username,
          'password': password,
          'phone': phone,
        }),
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'user': data['user'], 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': _friendlyError(e)};
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String username,
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/profile');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'user': data['user'], 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update profile'};
      }
    } catch (e) {
      return {'success': false, 'message': _friendlyError(e)};
    }
  }

  /// Converts raw Dart exceptions into clean, user-facing messages.
  static String _friendlyError(Object e) {
    if (e is TimeoutException) {
      return 'Server took too long to respond. Check that the server is running and the IP address is correct.';
    }
    if (e is SocketException) {
      return 'Unable to reach the server. Make sure you are on the same network and the server IP/port is correct.';
    }
    return 'Connection error. Please check server settings and try again.';
  }
}
