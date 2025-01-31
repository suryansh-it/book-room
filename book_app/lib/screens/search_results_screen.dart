import 'package:flutter/material.dart';
import '../services/book_service.dart';
import '../models/book.dart';
import '../widgets/book_card.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;

  SearchResultsScreen({super.key, required this.query});

  @override
  _SearchResultsScreenState createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final BookService _bookService = BookService();
  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  String? _selectedLanguage; // Holds the selected language filter
  bool _isLoading = true; // Track loading state
  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'Hindi'
  ]; // Example language options

  // Fetch books based on the query and update both _books and _filteredBooks
  Future<void> _fetchBooks() async {
    try {
      final books = await _bookService.searchBooks(widget.query);
      setState(() {
        _books = books;
        _filteredBooks = books; // Initially, show all books
        _isLoading = false; // Set loading to false after the books are fetched
      });
    } catch (e) {
      print("Error fetching books: $e");
      setState(() {
        _isLoading = false; // Set loading to false even if there is an error
      });
    }
  }

  // Method to filter books based on the selected language
  void _filterBooksByLanguage() {
    if (_selectedLanguage == null || _selectedLanguage!.isEmpty) {
      setState(() {
        _filteredBooks = _books; // If no language is selected, show all books
      });
    } else {
      setState(() {
        _filteredBooks =
            _books.where((book) => book.language == _selectedLanguage).toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results'),
      ),
      body: Column(
        children: [
          // Language filter dropdown
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              hint: Text('Select Language'),
              value: _selectedLanguage,
              onChanged: (String? newLanguage) {
                setState(() {
                  _selectedLanguage = newLanguage;
                  _filterBooksByLanguage(); // Apply language filter when changed
                });
              },
              items:
                  _languages.map<DropdownMenuItem<String>>((String language) {
                return DropdownMenuItem<String>(
                  value: language,
                  child: Text(language),
                );
              }).toList(),
            ),
          ),
          // Display the books (filtered or all)
          Expanded(
            child: _isLoading
                ? Center(
                    child:
                        CircularProgressIndicator()) // Show loading indicator while books are loading
                : _filteredBooks.isEmpty
                    ? Center(
                        child: Text(
                            'No books found')) // Show message if no books found
                    : ListView.builder(
                        itemCount: _filteredBooks.length,
                        itemBuilder: (context, index) {
                          return BookCard(book: _filteredBooks[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
