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
      child: ListTile(
        title: Text(book.title), // Display book title
        subtitle: Text('By ${book.author}'), // Display author name
        onTap: () {
          // Show a brief description in a Snackbar when the card is tapped
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text(book.description)),
          // );
        },
      ),
    );
  }
}
