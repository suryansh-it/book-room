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
            return Book.fromJson({
              'id': int.parse(book['id'].toString()), // Ensure ID is an integer
              'title': book['title'],
              'author': book['author'],
              'publisher': book['publisher'],
              'year': book['year'] != null
                  ? int.tryParse(book['year'].toString())
                  : null, // Year as int or null
              'file_type': book['file_type'],
              'file_size': book['file_size'],
              'download_link': book['download_link']
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
