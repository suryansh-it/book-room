import 'dart:ffi';

class Book {
  final String id;
  final String title;
  final String author;
  final String? publisher;
  final String? year;
  final String? language;
  final String fileType;
  final double fileSize;
  final String? downloadLink;
  final String? localPath; // New attribute for local file path
  final bool isDownloaded; // New attribute to track download status

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.publisher,
    this.year,
    this.language,
    required this.fileType,
    required this.fileSize,
    this.downloadLink,
    this.localPath,
    required this.isDownloaded,
  });

  // Factory constructor to create a Book object from JSON
  factory Book.fromJson(Map<String, dynamic> json) {
    // Parse the file size as a double, handling errors gracefully
    double parseFileSize(String size) {
      try {
        return double.parse(size.replaceAll(RegExp(r'[^0-9.]'), ''));
      } catch (e) {
        return 0.0;
      }
    }

    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      publisher: json['publisher'] as String?,
      year: json['year'] as String?, // Corrected to handle string data
      language: json['language'] as String?, // Corrected to handle string data
      fileType: json['file_type'] as String,
      fileSize: parseFileSize(
          json['file_type'] ?? '0.0'), // Extract numeric part from file size
      downloadLink: json['download_link'] != null
          ? 'https://libgen.li${json['download_link']}' // Prepend the base URL to the download link
          : null,
      localPath: json['local_path'] as String?,
      isDownloaded: json['is_downloaded'] as bool? ?? false, // Default to false
    );
  }

  // Method to convert Book object to JSON (if needed for API calls)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'publisher': publisher,
      'year': year,
      'language': language,
      'file_type': fileType,
      'file_size': fileSize,
      'download_link': downloadLink,
      'local_path': localPath,
      'is_downloaded': isDownloaded,
    };
  }
}
