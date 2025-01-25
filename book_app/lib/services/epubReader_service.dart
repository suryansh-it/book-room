import 'dart:convert';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class EpubReaderService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://10.0.2.2:8011/api/"));
  final AuthService _authService = AuthService();

  /// Fetch ePub content for a specific book, chapter, and section.
  Future<Map<String, dynamic>> fetchEpubContent({
    required int bookId,
    int chapterPage = 1,
    int chaptersPerPage = 1,
    int sectionPage = 1,
    int sectionSize = 500,
  }) async {
    final token = await _authService.getlogin();
    if (token == null) {
      throw Exception("Authentication required. Please log in.");
    }

    // Add the Authorization token to Dio headers
    _dio.options.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await _dio.get(
        "books/read/$bookId/",
        queryParameters: {
          "chapter": chapterPage,
          "chapters_per_page": chaptersPerPage,
          "section": sectionPage,
          "section_size": sectionSize,
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        return response.data.cast<String, dynamic>();
      } else {
        throw Exception(
            'Failed to fetch ePub content: ${response.statusCode}, ${response.data}');
      }
    } catch (e) {
      throw Exception('Error fetching ePub content: $e');
    }
  }

  /// Fetch chapter details for a specific book.
  Future<List<Chapter>> fetchChapters({
    required int bookId,
    int chapterPage = 1,
    int chaptersPerPage = 1,
  }) async {
    final token = await _authService.getlogin();
    if (token == null) {
      throw Exception("Authentication required. Please log in.");
    }

    // Add the Authorization token to Dio headers
    _dio.options.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await _dio.get(
        'books/read/$bookId/',
        queryParameters: {
          'chapter': chapterPage,
          'chapters_per_page': chaptersPerPage,
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        List chapters = response.data['chapters'];
        return chapters.map((data) => Chapter.fromJson(data)).toList();
      } else {
        throw Exception(
            'Failed to fetch chapters: ${response.statusCode}, ${response.data}');
      }
    } catch (e) {
      throw Exception('Error fetching chapters: $e');
    }
  }
}

class Chapter {
  final String title;
  final int id;

  Chapter({required this.title, required this.id});

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      title: json['title'] ?? 'Untitled',
      id: json['id'] ?? 0,
    );
  }
}
