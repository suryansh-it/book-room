import 'dart:convert';
import 'package:http/http.dart' as http;

class EpubReaderService {
  final String _baseUrl =
      "http://10.0.2.2:8011"; // Replace with your actual API URL

  /// Fetch a specific chapter and section from an ePub book.
  ///
  /// - `bookId`: The ID of the book.
  /// - `chapterPage`: The chapter number to fetch (default: 1).
  /// - `chaptersPerPage`: Number of chapters to fetch at once (default: 1).
  /// - `sectionPage`: The section number within the chapter (default: 1).
  /// - `sectionSize`: Number of characters per section (default: 500).
  /// Fetch chapters and sections for a given book
  Future<Map<String, dynamic>> fetchEpubContent({
    required int bookId,
    int chapterPage = 1,
    int chaptersPerPage = 1,
    int sectionPage = 1,
    int sectionSize = 500,
  }) async {
    final url = Uri.parse(
        "$_baseUrl/books/read/$bookId/?chapter=$chapterPage&chapters_per_page=$chaptersPerPage&section=$sectionPage&section_size=$sectionSize");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to fetch eBook content: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching content: $e');
    }
  }
}
