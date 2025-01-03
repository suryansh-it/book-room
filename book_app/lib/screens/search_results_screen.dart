import 'package:flutter/material.dart'; // Flutter package for UI design
import '../services/book_service.dart'; // BookService for API calls
import '../models/book.dart'; // Book model for handling data
import '../widgets/book_card.dart'; // BookCard widget for displaying book details

class SearchResultsScreen extends StatelessWidget {
  final String query; // Search query from the home screen
  final BookService _bookService = BookService(); // Instance of BookService

  SearchResultsScreen({super.key, required this.query}); // Constructor

  // Method to fetch books using the search query
  Future<List<Book>> _fetchBooks() {
    return _bookService.searchBooks(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results'), // AppBar title
      ),
      body: FutureBuilder<List<Book>>(
        future: _fetchBooks(), // Fetch books asynchronously
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator()); // Loading indicator
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}')); // Error handling
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No results found')); // No data case
          }

          // Render the list of books when data is available
          final books = snapshot.data!;
          return ListView.builder(
            itemCount: books.length, // Number of items in the list
            itemBuilder: (context, index) {
              return BookCard(
                  book: books[index]); // Display book details in a card
            },
          );
        },
      ),
    );
  }
}
