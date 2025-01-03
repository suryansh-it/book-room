//  Model for ePub metadata

// Model for ePub metadata
class EpubFile {
  final int id;
  final String title;
  final String author;
  final String downloadUrl;

  EpubFile({
    required this.id,
    required this.title,
    required this.author,
    required this.downloadUrl,
  });

  // Factory method to create an EpubFile from JSON
  factory EpubFile.fromJson(Map<String, dynamic> json) {
    return EpubFile(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      downloadUrl: json['download_url'],
    );
  }
}
