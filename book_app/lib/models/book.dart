class Book {
  final String id;
  final String title;
  final String author;
  final String? publisher;
  final String? year;
  final String? language;
  final String fileType;
  final String? fileSize; // Keep the file size as a string
  final String? downloadLink;
  final String? localPath;
  final bool isDownloaded;

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

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id']?.toString() ?? '', // Handle null ID gracefully
      title: json['title'] ?? 'Unknown Title',
      author: json['author'] ?? 'Unknown Author',
      publisher: json['publisher'],
      year: json['year'],
      language: json['language'],
      fileType: json['file_type'] ?? '',
      fileSize:
          json['file_size'], // Directly use the file size from the backend
      downloadLink: json['download_link'], // Directly use the link from backend
      localPath: null, // Default to null if not provided
      isDownloaded: false, // Default to false for new objects
    );
  }

  Map<String, dynamic> toJson() => {
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
