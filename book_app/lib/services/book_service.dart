import 'package:dio/dio.dart';
import '../models/book.dart';

// class BookService {
//   final Dio _dio = Dio(BaseOptions(
//     baseUrl: "http://10.0.2.2:8011/api/books/", // Update to match backend
//     // connectTimeout: Duration(milliseconds: 5000), // Specify as Duration
//     // receiveTimeout: Duration(milliseconds: 5000), // Specify as Duration
//   ));

//   /// Searches for books matching the given query string.
//   ///
//   /// [query]: The search query entered by the user.
//   /// Returns a list of [Book] objects if the API call succeeds.
//   Future<List<Book>> searchBooks(String query) async {
//     try {
//       // Make a GET request to the search endpoint with the query parameter
//       final response = await _dio.get(
//         'search/',
//         queryParameters: {'q': query},
//       );

//       // Ensure the response format is valid
//       if (response.data is Map<String, dynamic> &&
//           response.data['results'] is List) {
//         final List<dynamic> booksData = response.data['results'];

//         // Map the response data to a list of Book objects
//         return booksData.map((book) {
//           try {
//             // Parse file size safely from various types (String or double)
//             double parseFileSize(dynamic size) {
//               if (size == null) return 0.0;
//               try {
//                 if (size is String) {
//                   return double.parse(size.replaceAll(RegExp(r'[^0-9.]'), ''));
//                 } else if (size is double || size is int) {
//                   return size.toDouble();
//                 }
//               } catch (_) {
//                 // Ignore errors and return default value
//               }
//               return 0.0;
//             }

//             // Construct the full download link
//             String? constructDownloadLink(String? link) {
//               if (link == null || link.isEmpty) return null;
//               const baseDownloadUrl = 'https://libgen.li'; // Update if needed
//               return '$baseDownloadUrl$link';
//             }

//             // Construct and return a Book object
//             return Book.fromJson({
//               'id': book['id']?.toString() ?? '',
//               'title': book['title'] ?? 'Unknown Title',
//               'author': book['author'] != null && book['author'].isNotEmpty
//                   ? book['author']
//                   : 'Unknown Author',
//               'publisher': book['publisher'] ?? 'Unknown Publisher',
//               'year': book['year']?.toString() ?? '',
//               'language': book['language'] ?? 'Unknown Language',
//               'file_type': book['file_type'] ?? '',
//               'file_size': parseFileSize(book['file_size']),
//               'download_link': constructDownloadLink(book['download_link']),
//               'local_path': null, // Default to null, updated when downloaded
//               'is_downloaded': false, // Default to false
//             });
//           } catch (e) {
//             throw Exception("Error parsing book data: ${e.toString()}");
//           }
//         }).toList();
//       } else {
//         throw Exception(
//             "Unexpected response format: 'results' field is missing or not a list.");
//       }
//     } catch (e) {
//       throw Exception("Failed to fetch books: ${e.toString()}");
//     }
//   }
// }

class BookService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: "http://192.168.29.41:8019/api/books/",
  ));

  Future<List<Book>> searchBooks(String query) async {
    try {
      final response = await _dio.post(
        'search/',
        data: {'q': query}, // Send query in the request body
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        if (response.data['books'] is List) {
          // Check for 'books' key
          final List<dynamic> booksData = response.data['books'];
          return booksData.map((book) => Book.fromJson(book)).toList();
        } else {
          // Handle the case where 'books' key is missing or not a list
          print("Unexpected data format: ${response.data}");
          return []; // Or throw an exception if you prefer
        }
      } else if (response.statusCode == 404) {
        // Handle 404 (No books found)
        return []; // Return an empty list to indicate no results
      } else {
        throw Exception(
            "Invalid response from server: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      print("Error fetching books: $e"); // Print error for debugging
      throw Exception("Failed to fetch books: $e");
    }
  }
}
