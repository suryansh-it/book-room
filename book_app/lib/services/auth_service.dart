import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: "http://192.168.10.250:8019/api/users/",
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // ✅ Save Token Persistently
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  // ✅ Retrieve Token
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // ✅ Login and Save Token
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('login/', data: {
        'email': email,
        'password': password,
      });

      await saveToken(response.data['access']); // Save token
      return response.data;
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['detail'] ?? "An error occurred";
        throw Exception("Login failed: $message");
      }
      throw Exception("Login failed: ${e.toString()}");
    }
  }

  /// ✅ Signup User
  Future<void> signup(String email, String password) async {
    try {
      final response = await _dio.post('signup/', data: {
        'email': email.trim(),
        'password': password.trim(),
      });

      if (response.statusCode == 201) {
        print('Signup successful: ${response.data['message']}');
      } else {
        throw Exception("Unexpected response: ${response.statusCode}");
      }
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['error'] ?? "An error occurred";
        throw Exception("Signup failed: $message");
      }
      throw Exception("Signup failed");
    }
  }

  // ✅ Logout and Remove Token
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }
}
