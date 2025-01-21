import 'dart:convert';
import 'package:dio/dio.dart';
import 'auth_service.dart';
import '../models/book.dart';

class LibraryService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://10.0.2.2:8011/api/books/"));
  final AuthService _authService = AuthService();

  // **Improved getDownloadedBooks:**
  Future<List<Map<String, dynamic>>> getDownloadedBooks() async {
    final token =
        await _authService.getlogin(); // Assuming AuthService provides this
    if (token == null) {
      throw Exception("Authentication required. Please log in.");
    }

    _dio.options.headers['Authorization'] = 'Bearer $token';

    final response = await _dio.get('userlibrary/');

    if (response.statusCode == 200) {
      // Check if response.data is a List before casting
      if (response.data is List) {
        return response.data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Unexpected response format for downloaded books.');
      }
    } else {
      throw Exception(
          'Failed to fetch downloaded books: ${response.statusCode}'); // Include status code for debugging
    }
  }

  // **New function: getBookDetails**
  Future<Map<String, dynamic>> getBookDetails(int bookId) async {
    final token =
        await _authService.getlogin(); // Assuming AuthService provides this
    if (token == null) {
      throw Exception("Authentication required. Please log in.");
    }

    final response = await _dio.get('$bookId/');

    _dio.options.headers['Authorization'] = 'Bearer $token';

    if (response.statusCode == 200) {
      // Check if response.data is a Map before casting
      if (response.data is Map) {
        return response.data.cast<String, dynamic>();
      } else {
        throw Exception('Unexpected response format for book details.');
      }
    } else {
      throw Exception(
          'Failed to fetch book details: ${response.statusCode}'); // Include status code for debugging
    }
  }

  // **Improved deleteBook:**
  Future<void> deleteBook(int bookId) async {
    final token =
        await _authService.getlogin(); // Assuming AuthService provides this
    if (token == null) {
      throw Exception("Authentication required. Please log in.");
    }

    final response = await _dio.delete('$bookId/');

    _dio.options.headers['Authorization'] = 'Bearer $token';

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to delete the book: ${response.statusCode}'); // Include status code for debugging
    }
  }
}
