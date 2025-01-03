// import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://10.0.2.2:8011/api/users/"));
  // Flutter apps running on emulators use 10.0.2.2 to connect to the local development server.
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Login method
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('login/', data: {
        'email': email,
        'password': password,
      });

      // Save login securely
      await _storage.write(key: 'login', value: response.data['access']);
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['detail'] ?? "An error occurred";
        throw Exception("Login failed: $message");
      }
      throw Exception("Login failed: ${e.toString()}");
    }
  }

  // Signup method
  Future<void> signup(String email, password) async {
    try {
      final response = await _dio.post('signup/', data: {
        'email': email.trim(),
        'password': password.trim(),
      });

      if (response.statusCode == 201) {
        final String message = response.data['message'] ?? "Signup successful";
        print('Signup successful: $message');
      } else {
        print('Unexpected response: ${response.data}');
        throw Exception("Unexpected response code: ${response.statusCode}");
      }
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['error'] ?? "An error occurred";
        throw Exception("Signup failed: $message");
      }
      throw Exception("Signup failed");
    }
  }

  // Logout method
  Future<void> logout() async {
    await _storage.delete(key: 'login');
  }

  // Method to get the login token from secure storage
  Future<String?> getlogin() async {
    try {
      final token = await _storage.read(key: 'login');
      if (token != null) {
        print("Token retrieved successfully");
      } else {
        print("No token found");
      }
      return token;
    } catch (e) {
      print("Error retrieving token: $e");
      return null;
    }
  }
}
