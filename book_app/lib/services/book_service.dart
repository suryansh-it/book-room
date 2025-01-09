import 'package:dio/dio.dart';
import '../models/book.dart';

class BookService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://10.0.2.2:8011/api/books/"));

  Future<List<Book>> searchBooks(String query) async {
    try {
      final response = await _dio.get(
        'search/',
        queryParameters: {'q': query},
      );

      if (response.data is Map<String, dynamic> &&
          response.data['results'] is List) {
        final List<dynamic> booksData = response.data['results'];

        return booksData.map((book) {
          try {
            // Parse file size safely
            double parseFileSize(String size) {
              try {
                return double.parse(size.replaceAll(RegExp(r'[^0-9.]'), ''));
              } catch (e) {
                return 0.0;
              }
            }

            // Construct and return a Book object
            return Book.fromJson({
              'id': book['id']?.toString() ?? '',
              'title': book['title'] ?? 'Unknown Title',
              'author': book['author'] ?? 'Unknown Author',
              'publisher': book['publisher'] ?? 'Unknown Publisher',
              'year': book['year']?.toString(),
              'language': book['language'] ?? 'Unknown Language',
              'file_type': book['file_type'] ?? '',
              'file_size': parseFileSize(book['file_type'] ?? '0.0'),
              'download_link': book['download_link'] != null
                  ? 'https://libgen.li${book['download_link']}'
                  : null,
              'local_path': null, // Default to null
              'is_downloaded': false, // Default to false
            });
          } catch (e) {
            throw Exception("Error parsing book data: ${e.toString()}");
          }
        }).toList();
      } else {
        throw Exception(
            "Unexpected response format: 'results' field is missing or not a list.");
      }
    } catch (e) {
      throw Exception("Failed to fetch books: ${e.toString()}");
    }
  }
}
