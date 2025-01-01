import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  String? _token;

  String? get token => _token;

  Future<void> login(String email, String password) async {
    final data = await _authService.login(email, password);
    _token = data['access'];
    notifyListeners();
  }

  Future<void> signup(String email, String password) async {
    await _authService.signup(email, password);
  }

  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    _token = await _authService.getlogin();
    notifyListeners();
  }
}
