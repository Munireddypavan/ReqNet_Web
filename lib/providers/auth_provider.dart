import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/mesh_database.dart';

class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _loadSavedUser();
    AuthService.loadCustomBaseUrl();
  }

  Future<void> _loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('resqnet_user');
    if (userJson != null) {
      try {
        _user = jsonDecode(userJson);
        notifyListeners();
      } catch (e) {
        debugPrint("Error parsing stored user: $e");
      }
    }
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await AuthService.login(usernameOrEmail, password);
    _isLoading = false;

    if (result['success'] == true) {
      await MeshDatabase.instance.clearDatabase();
      _user = result['user'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('resqnet_user', jsonEncode(_user));
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String fullName,
    required String email,
    required String username,
    required String password,
    required String phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await AuthService.signup(
      fullName: fullName,
      email: email,
      username: username,
      password: password,
      phone: phone,
    );
    _isLoading = false;

    if (result['success'] == true) {
      await MeshDatabase.instance.clearDatabase();
      _user = result['user'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('resqnet_user', jsonEncode(_user));
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (_user == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await AuthService.updateProfile(
      username: _user!['username'],
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
    );
    _isLoading = false;

    if (result['success'] == true) {
      _user = result['user'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('resqnet_user', jsonEncode(_user));
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('resqnet_user');
    await MeshDatabase.instance.clearDatabase();
    notifyListeners();
  }
}
