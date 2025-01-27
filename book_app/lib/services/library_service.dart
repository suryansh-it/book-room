import 'package:dio/dio.dart';
import 'auth_service.dart';

class LibraryService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: "http://192.168.10.250:8019/api/books/",
    connectTimeout: const Duration(seconds: 20), // 5 seconds
    receiveTimeout: const Duration(seconds: 20), // 3 seconds
  ));
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> getDownloadedBooks() async {
    final token =
        await _authService.getlogin(); // Assuming AuthService provides this
    if (token == null) {
      throw Exception("Authentication required. Please log in.");
    }

    _dio.options.headers['Authorization'] = 'Bearer $token';

    final response = await _dio.get('userlibrary/');

    if (response.statusCode == 200) {
      // Access the 'library' key from the response data
      if (response.data is Map && response.data.containsKey('library')) {
        final libraryData = response.data['library'];

        // Now check if libraryData is a List
        if (libraryData is List) {
          return libraryData.cast<Map<String, dynamic>>();
        } else {
          throw Exception('Unexpected format: "library" is not a list.');
        }
      } else {
        throw Exception('Unexpected format: missing "library" key.');
      }
    } else {
      throw Exception(
          'Failed to fetch downloaded books: ${response.statusCode}');
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
