import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/epub_service.dart';

class BookCard extends StatelessWidget {
  final Book book;

  const BookCard({super.key, required this.book});

  // Extract title before the hashtag from `id`
  String getFormattedTitle(String id) {
    return id.split('#').first.trim();
  }

  Future<void> _downloadBook(BuildContext context) async {
    final epubService = EpubService();

    try {
      // Check if download link is available before initiating download
      if (book.downloadLink == null) {
        throw Exception("Download link is not available for this book.");
      }

      // Initiate the download and get the file path
      final savePath = await epubService.downloadEpub(book);

      // Show success message in SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Downloaded ${getFormattedTitle(book.id)} successfully to $savePath!',
          ),
        ),
      );
    } catch (e) {
      // Show failure message in SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download ${getFormattedTitle(book.id)}: $e'),
        ),
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
              getFormattedTitle(book.title),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            // Display author
            Text(
              'Author: ${book.author}',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),

            // Conditional spacing for details
            if (book.publisher != null ||
                book.year != null ||
                book.language != null ||
                book.fileSize != null)
              const SizedBox(height: 8),

            // Display "Published by" only if available
            if (book.publisher != null)
              Text(
                'Publisher: ${book.publisher}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),

            // Display "Year" only if available
            if (book.year != null)
              Text(
                '${book.year}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),

            // Display "Language" only if available
            if (book.language != null)
              Text(
                '${book.language}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),

            // Display "File Size" only if available
            if (book.fileSize != null)
              Text(
                '${book.fileSize}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),

            const SizedBox(height: 12),

            // Display download button only if downloadLink is available
            if (book.downloadLink != null)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _downloadBook(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Download'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
