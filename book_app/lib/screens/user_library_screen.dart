import 'package:flutter/material.dart';
import 'epub_reader_screen.dart';
import '../services/library_service.dart';
import 'package:vocsy_epub_viewer/epub_viewer.dart'; // Import vocsy_epub_viewer

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

  String _getBookPath(String relativePath) async {
    // Get the app's document directory (same logic as before)
    final directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, relativePath);
  }

  void _openBook(int bookId, String bookTitle, String relativePath) async {
    final bookPath = await _getBookPath(relativePath); // Await the future
    final file = File(bookPath);

    if (await file.exists()) {
      try {
        await VocsyEpub.setConfig(
          themeColor: Theme.of(context).primaryColor,
          identifier: "iosBook",
          scrollDirection: EpubScrollDirection.ALLDIRECTIONS,
          allowSharing: true,
          enableTts: true,
          nightMode: true,
        );
        await VocsyEpub.open(bookPath);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening book: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Book not found locally at: $bookPath',
          ),
        ),
      );
    }
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
      // ...
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? const Center(child: Text('No books available in the library.'))
              : ListView.builder(
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final book = _books[index];
                    return Card(
                      child: ListTile(
                        title: Text(book['title'] ?? 'No Title'),
                        subtitle: Text(book['author'] ?? 'Unknown Author'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ... (delete button)
                            IconButton(
                              icon: const Icon(Icons.book),
                              onPressed: () {
                                if (book.containsKey('path')) {
                                  _openBook(
                                      book['id'], book['title'], book['path']);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'File name not available for this book.'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
