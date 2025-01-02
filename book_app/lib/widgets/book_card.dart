import 'package:flutter/material.dart'; // Core Flutter package for UI design
import '../models/book.dart'; // Import Book model

// Widget to display a single book as a card
class BookCard extends StatelessWidget {
  final Book book; // Book data for the card

  // Constructor to accept Book object
  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0), // Add margin around the card
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Add padding inside the card
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align contents to the start
          children: [
            // Book Title
            Text(
              book.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4), // Spacing between title and author

            // Author Name
            Text(
              'By ${book.author}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8), // Spacing between author and other details

            // Publisher and Year (if available)
            if (book.publisher != null || book.year != null)
              Text(
                'Published by: ${book.publisher ?? "Unknown"} (${book.year?.toString() ?? "N/A"})',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),

            SizedBox(height: 8), // Spacing between details and file info

            // File Type and Size
            Text(
              'File: ${book.fileType} (${book.fileSize})',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),

            // Spacing for download button
            SizedBox(height: 12),

            // Download Button
            if (book.downloadLink != null)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle download link navigation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Downloading ${book.title}...')),
                    );
                    // Add actual download logic here if needed
                  },
                  child: Text('Download'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
