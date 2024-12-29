import 'package:flutter/material.dart'; // Core Flutter package for UI design
import '../services/book_service.dart'; // Import BookService for API calls
import '../models/book.dart'; // Import Book model
import '../widgets/book_card.dart'; // Import BookCard widget

// Screen to display search results
class SearchResultsScreen extends StatelessWidget {
  final String query; // Search query from the home screen
  final BookService _bookService = BookService(); // Instance of BookService

  // Constructor to accept search query and key
  SearchResultsScreen({super.key, required this.query});

  // Method to fetch books using the query
  Future<List<Book>> _fetchBooks() {
    return _bookService.searchBooks(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results'), // App bar title
      ),
      body: FutureBuilder<List<Book>>(
        future: _fetchBooks(), // Fetch books asynchronously
        builder: (context, snapshot) {
          // Show loading spinner while waiting for data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          // Handle errors during API call
          else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // Handle case where no results are found
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No results found'));
          }

          // Render the list of books when data is available
          final books = snapshot.data!;
          return ListView.builder(
            itemCount: books.length, // Number of items in the list
            itemBuilder: (context, index) {
              return BookCard(
                  book: books[index]); // Create a BookCard for each book
            },
          );
        },
      ),
    );
  }
}
