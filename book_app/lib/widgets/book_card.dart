import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';
import '../services/epub_service.dart';

class BookCard extends StatelessWidget {
  final Book book;

  const BookCard({Key? key, required this.book}) : super(key: key);

  // Extract title before the hashtag from `id`
  String getFormattedTitle(String id) {
    return id.split('#').first.trim();
  }

  Future<void> _downloadBook(BuildContext context) async {
    final epubService = EpubService();

    try {
      // Get the document directory
      final directory = await getApplicationDocumentsDirectory();
      final savePath =
          '${directory.path}/${getFormattedTitle(book.id)}.epub'; // Use formatted title for file name

      // Initiate the download
      await epubService.downloadEpub(getFormattedTitle(book.id), book.author,
          book.downloadLink!, savePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Downloaded ${getFormattedTitle(book.id)} successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to download ${getFormattedTitle(book.id)}: $e')),
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
            // Display formatted title
            Text(
              getFormattedTitle(book.id),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'By ${book.author}', // Display author
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            if (book.publisher != null || book.year != null)
              Text(
                'Published by ${book.publisher ?? "Unknown"} (${book.year ?? "N/A"})', // Publisher and year
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
