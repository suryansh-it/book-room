import 'package:flutter/material.dart';
import 'epub_reader_screen.dart';
import '../services/library_service.dart';

class UserLibraryScreen extends StatefulWidget {
  const UserLibraryScreen({Key? key}) : super(key: key);

  @override
  State<UserLibraryScreen> createState() => _UserLibraryScreenState();
}

class _UserLibraryScreenState extends State<UserLibraryScreen> {
  final LibraryService _libraryService = LibraryService();
  List<Map<String, dynamic>> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLibraryBooks();
  }

  Future<void> _fetchLibraryBooks() async {
    try {
      final books = await _libraryService.getDownloadedBooks();
      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching library: ${e.toString()}')),
      );
    }
  }

  void _openBook(int bookId, String bookTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EpubReaderScreen(bookId: bookId, bookTitle: bookTitle),
      ),
    );
  }

  Future<void> _deleteBook(int bookId) async {
    try {
      await _libraryService.deleteBook(bookId);
      setState(() {
        _books.removeWhere((book) => book['id'] == bookId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Book deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting book: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Library')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? Center(child: Text('No downloaded books in the library'))
              : ListView.builder(
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final book = _books[index];
                    return ListTile(
                      title: Text(book['title']),
                      subtitle: Text('Author: ${book['author']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteBook(book['id']),
                          ),
                          IconButton(
                            icon: Icon(Icons.book),
                            onPressed: () =>
                                _openBook(book['id'], book['title']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
