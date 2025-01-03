// import 'dart:convert'; // Provides JSON encoding and decoding functionality
import 'package:dio/dio.dart'; // HTTP client library for making API calls
import '../models/book.dart'; // Import Book model

// Service class to handle book-related API calls
class BookService {
  // Initialize Dio with base URL for backend API
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://127.0.0.1:8011/api"));

  // Method to search books by a query
  Future<List<Book>> searchBooks(String query) async {
    try {
      // Perform GET request with query parameter
      final response =
          await _dio.get('/books/search/', queryParameters: {'q': query});
      // Parse the response into a list of Book objects
      return (response.data as List)
          .map((book) => Book.fromJson(book))
          .toList();
    } catch (e) {
      // Handle errors gracefully
      throw Exception("Failed to fetch books");
    }
  }
}
