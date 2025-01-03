import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://10.0.2.2:8011/api/auth/"));
  // Flutter apps running on emulators use 10.0.2.2 to connect to the local development server.
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Login method
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('login/', data: {
        'email': email,
        'password': password,
      });

      // If login is successful, save the token securely
      if (response.statusCode == 200) {
        await _storage.write(key: 'login', value: response.data['access']);
        return response.data; // Return the token data
      } else {
        throw Exception("Failed to login: ${response.data['error']}");
      }
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['detail'] ?? "An error occurred";
        throw Exception("Login failed: $message");
      }
      throw Exception("Login failed: ${e.toString()}");
    }
  }

  // Signup method
  Future<void> signup(String email, String password) async {
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

  // Get login token from storage
  Future<String?> getlogin() async {
    try {
      final token = await _storage.read(key: 'login');
      if (token != null) {
        print("Token retrieved successfully");
        return token;
      } else {
        print("No token found, please log in.");
        return null;
      }
    } catch (e) {
      print("Error retrieving token: $e");
      return null;
    }
  }

  // Method to get token dynamically
  Future<String?> getToken(String email, String password) async {
    // Attempt to get the token from storage first
    final token = await getlogin();
    if (token != null) {
      return token;
    }

    // If no token found in storage, attempt to login and retrieve token
    final loginResponse = await login(email, password);
    return loginResponse['access']; // Return access token from login response
  }
}
