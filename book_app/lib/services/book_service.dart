import 'package:dio/dio.dart';
import '../models/book.dart';

class BookService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://10.0.2.2:8011/api/books/"));

  Future<List<Book>> searchBooks(String query) async {
    try {
      final response = await _dio.get('search/', queryParameters: {'q': query});

      if (response.data is Map<String, dynamic> &&
          response.data['results'] is List) {
        final List<dynamic> booksData = response.data['results'];

        return booksData.map((book) {
          try {
            // Adjust parsing to match the updated JSON structure
            return Book.fromJson({
              'id': book['id'], // ID as string, // Use as title in UI
              'title': book['id'], // Assign `id` as `title`
              'author': book['author'],
              'publisher': book['publisher'],
              'year': book['year'], // Keep year as string for flexibility
              'language': book['language'], // Corrected for language field
              'file_type': book['file_type'],
              'file_size': book['file_type'], // Parse file size from file_type
              'download_link': book['download_link'] != null
                  ? 'https://libgen.li${book['download_link']}'
                  : null, // Construct full download link
            });
          } catch (e) {
            throw Exception("Error parsing book data: ${e.toString()}");
          }
        }).toList();
      } else {
        throw Exception(
            "Unexpected response format: 'results' field is missing or not a list");
      }
    } catch (e) {
      throw Exception("Failed to fetch books: ${e.toString()}");
    }
  }
}
