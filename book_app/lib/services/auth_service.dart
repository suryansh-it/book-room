// import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://10.0.2.2:8011/api/users"));
  // Flutter apps running on emulators use 10.0.2.2 to connect to the local development server.
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
      if (e is DioException) {
        final message = e.response?.data['detail'] ?? "An error occurred";
        throw Exception("Login failed: $message");
      }
      throw Exception("Login failed: ${e.toString()}");
    }
  }

  Future<void> signup(String email, String password) async {
    try {
      await _dio.post('/signup/', data: {
        'email': email.trim(),
        'password': password.trim(),
      });
    } catch (e) {
      if (e is DioException) {
        print("DioException: ${e.response?.data}");
        final message = e.response?.data['error'] ?? "An error occurred";
        throw Exception("Signup failed: $message");
      }
      print("Unexpected error: $e");
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
