import 'package:flutter/material.dart'; // Core Flutter package for UI design
import './search_results_screen.dart'; // Import search results screen

// Main Home Screen widget
class HomeScreen extends StatelessWidget {
  // TextEditingController to capture the search input
  final TextEditingController _searchController = TextEditingController();

  // Method to navigate to Search Results Screen
  void _searchBooks(BuildContext context) {
    final query = _searchController.text; // Retrieve text from the controller
    if (query.isNotEmpty) {
      // Navigate to SearchResultsScreen and pass the search query
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SearchResultsScreen(query: query)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to the Book App'), // App bar title
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0), // Add padding around the content
        child: Column(
          children: [
            TextField(
              controller: _searchController, // Attach controller for input
              decoration: InputDecoration(
                labelText: 'Search for books', // Placeholder text
                border:
                    OutlineInputBorder(), // Add a border around the text field
              ),
            ),
            SizedBox(height: 20), // Add vertical spacing
            ElevatedButton(
              onPressed: () =>
                  _searchBooks(context), // Trigger search on button press
              child: Text('Search'), // Button text
            ),
          ],
        ),
      ),
    );
  }
}
