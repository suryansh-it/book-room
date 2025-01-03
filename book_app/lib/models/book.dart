class Book {
  final int id;
  final String title;
  final String author;
  final String? publisher;
  final int? year;
  final String fileType;
  final String fileSize;
  final String? downloadLink;
  final String? localPath; // New attribute for local file path
  final bool isDownloaded; // New attribute to track download status

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.publisher,
    this.year,
    required this.fileType,
    required this.fileSize,
    this.downloadLink,
    this.localPath,
    required this.isDownloaded,
  });

  // Factory constructor to create a Book object from JSON
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as int,
      title: json['title'] as String,
      author: json['author'] as String,
      publisher: json['publisher'] as String?,
      year: json['year'] as int?,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as String,
      downloadLink: json['download_link'] as String?,
      localPath: json['local_path'] as String?,
      isDownloaded: json['is_downloaded'] as bool? ??
          false, // Default to false if not present
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
      'file_type': fileType,
      'file_size': fileSize,
      'download_link': downloadLink,
      'local_path': localPath,
      'is_downloaded': isDownloaded,
    };
  }
}
