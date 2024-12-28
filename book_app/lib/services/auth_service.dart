// import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://your-backend-url/api"));
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/token/', data: {
        'email': email,
        'password': password,
      });
      // Save token securely
      await _storage.write(key: 'token', value: response.data['access']);
      return response.data;
    } catch (e) {
      throw Exception("Login failed");
    }
  }

  Future<void> signup(String email, String password) async {
    try {
      await _dio.post('/signup/', data: {
        'email': email,
        'password': password,
      });
    } catch (e) {
      throw Exception("Signup failed");
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }
}
