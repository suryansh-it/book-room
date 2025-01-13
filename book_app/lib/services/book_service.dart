import 'package:dio/dio.dart';
import '../models/book.dart';

class BookService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: "http://10.0.2.2:8011/api/books/", // Update to match backend
    connectTimeout: Duration(milliseconds: 5000), // Specify as Duration
    receiveTimeout: Duration(milliseconds: 5000), // Specify as Duration
  ));

  /// Searches for books matching the given query string.
  ///
  /// [query]: The search query entered by the user.
  /// Returns a list of [Book] objects if the API call succeeds.
  Future<List<Book>> searchBooks(String query) async {
    try {
      // Make a GET request to the search endpoint with the query parameter
      final response = await _dio.get(
        'search/',
        queryParameters: {'q': query},
      );

      // Ensure the response format is valid
      if (response.data is Map<String, dynamic> &&
          response.data['results'] is List) {
        final List<dynamic> booksData = response.data['results'];

        // Map the response data to a list of Book objects
        return booksData.map((book) {
          try {
            // Parse file size safely from string
            double parseFileSize(String? size) {
              if (size == null || size.isEmpty) return 0.0;
              try {
                return double.parse(size.replaceAll(RegExp(r'[^0-9.]'), ''));
              } catch (_) {
                return 0.0;
              }
            }

            // Construct the full download link
            String? constructDownloadLink(String? link) {
              if (link == null || link.isEmpty) return null;
              const baseDownloadUrl = 'https://libgen.li'; // Update if needed
              return '$baseDownloadUrl$link';
            }

            // Construct and return a Book object
            return Book.fromJson({
              'id': book['id']?.toString() ?? '',
              'title': book['title'] ?? 'Unknown Title',
              'author': book['author'] != null && book['author'].isNotEmpty
                  ? book['author']
                  : 'Unknown Author',
              'publisher': book['publisher'] ?? 'Unknown Publisher',
              'year': book['year']?.toString() ?? '',
              'language': book['language'] ?? 'Unknown Language',
              'file_type': book['file_type'] ?? '',
              'file_size': parseFileSize(book['file_size']),
              'download_link': constructDownloadLink(book['download_link']),
              'local_path': null, // Default to null, updated when downloaded
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
