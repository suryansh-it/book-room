import 'dart:convert';
import 'package:http/http.dart' as http;

class LibraryService {
  final String baseUrl =
      'https://your-backend-api.com'; // Replace with your backend URL

  Future<List<Map<String, dynamic>>> getDownloadedBooks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/library/'),
      headers: {'Authorization': 'Bearer YOUR_TOKEN'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to fetch downloaded books');
    }
  }

  Future<void> deleteBook(int bookId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/books/$bookId/'),
      headers: {'Authorization': 'Bearer YOUR_TOKEN'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete the book');
    }
  }
}
