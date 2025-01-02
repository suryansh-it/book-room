class Book {
  final int id;
  final String title;
  final String author;
  final String? publisher;
  final int? year;
  final String fileType;
  final String fileSize;
  final String? downloadLink;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.publisher,
    this.year,
    required this.fileType,
    required this.fileSize,
    this.downloadLink,
  });

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
    );
  }
}
