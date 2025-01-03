import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';
import '../services/epub_service.dart';

class BookCard extends StatelessWidget {
  final Book book;

  const BookCard({super.key, required this.book});

  Future<void> _downloadBook(BuildContext context) async {
    final EpubService epubService = EpubService();

    try {
      // Get app's document directory
      final directory = await getApplicationDocumentsDirectory();
      final savePath = '${directory.path}/${book.title}.epub';

      // Trigger download
      await epubService.downloadEpub(book.downloadLink!, savePath);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${book.title} downloaded successfully!')),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download ${book.title}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Title
            Text(
              book.title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            // Author Name
            Text(
              'By ${book.author}',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            // Publisher and Year
            if (book.publisher != null || book.year != null)
              Text(
                'Published by: ${book.publisher ?? "Unknown"} (${book.year ?? "N/A"})',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            SizedBox(height: 8),
            // File Info
            Text(
              'File: ${book.fileType} (${book.fileSize})',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            // Download Button
            if (book.downloadLink != null)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _downloadBook(context),
                  child: Text('Download'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
