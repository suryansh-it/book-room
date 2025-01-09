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
    String? rawDownloadUrl = json['download_url'];
    String? formattedDownloadUrl;

    if (rawDownloadUrl != null && rawDownloadUrl.isNotEmpty) {
      if (rawDownloadUrl.startsWith('http://') ||
          rawDownloadUrl.startsWith('https://')) {
        formattedDownloadUrl = rawDownloadUrl;
      } else {
        formattedDownloadUrl =
            'https://libgen.li${rawDownloadUrl.startsWith('/') ? '' : '/'}$rawDownloadUrl';
      }
    } else {
      throw Exception("Invalid download URL");
    }

    return EpubFile(
      id: json['id'] as int,
      title: json['title'] as String,
      author: json['author'] as String,
      downloadUrl: formattedDownloadUrl,
    );
  }
}
