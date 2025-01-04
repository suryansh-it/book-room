import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';
import '../services/epub_service.dart';

class BookCard extends StatelessWidget {
  final Book book;

  const BookCard({Key? key, required this.book}) : super(key: key);

  Future<void> _downloadBook(BuildContext context) async {
    final epubService = EpubService();

    try {
      // Get the document directory
      final directory = await getApplicationDocumentsDirectory();
      final savePath = '${directory.path}/${book.title}.epub';

      // Initiate the download
      await epubService.downloadEpub(
          book.title, book.author, book.downloadLink!, savePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded ${book.title} successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download ${book.title}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'By ${book.author}',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            if (book.publisher != null || book.year != null)
              Text(
                'Published by ${book.publisher ?? "Unknown"} (${book.year ?? "N/A"})',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            const SizedBox(height: 12),
            if (book.downloadLink != null)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _downloadBook(context),
                  child: const Text('Download'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
