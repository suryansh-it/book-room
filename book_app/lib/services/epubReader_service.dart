import 'dart:convert';
import 'package:http/http.dart' as http;

class EpubService {
  final String _baseUrl =
      "https://your-api-url.com"; // Replace with your actual API URL

  /// Fetch a specific chapter and section from an ePub book.
  ///
  /// - `bookId`: The ID of the book.
  /// - `chapterPage`: The chapter number to fetch (default: 1).
  /// - `chaptersPerPage`: Number of chapters to fetch at once (default: 1).
  /// - `sectionPage`: The section number within the chapter (default: 1).
  /// - `sectionSize`: Number of characters per section (default: 500).
  Future<Map<String, dynamic>> fetchEpubChapter({
    required int bookId,
    int chapterPage = 1,
    int chaptersPerPage = 1,
    int sectionPage = 1,
    int sectionSize = 500,
  }) async {
    final url = Uri.parse(
        "$_baseUrl/api/books/$bookId/read?chapter=$chapterPage&chapters_per_page=$chaptersPerPage&section=$sectionPage&section_size=$sectionSize");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
            'Failed to load chapter: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching chapter: $e');
    }
  }
}
