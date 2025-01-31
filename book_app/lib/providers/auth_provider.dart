import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  String? _token;

  String? get token => _token;

  /// ✅ Login and Save Token
  Future<void> login(String email, String password) async {
    final data = await _authService.login(email, password);
    _token = data['access'];
    await _authService.saveToken(_token!); // Save token persistently
    notifyListeners();
  }

  /// ✅ Signup New User
  Future<void> signup(String email, String password) async {
    await _authService.signup(email, password);
  }

  /// ✅ Logout and Remove Token
  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    notifyListeners();
  }

  /// ✅ Automatically Check Authentication Status on App Start
  Future<void> checkAuth() async {
    _token = await _authService.getToken();
    notifyListeners();
  }

  /// ✅ Check if User is Authenticated
  bool get isAuthenticated => _token != null;
}
