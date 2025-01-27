import 'package:flutter/material.dart';
import '../services/library_service.dart'; // Make sure this path is correct
import 'package:vocsy_epub_viewer/epub_viewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class UserLibraryScreen extends StatefulWidget {
  const UserLibraryScreen({super.key});

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

  Future<String> _getBookPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    print('Flutter Directory Path: ${directory.path}');
    final offlineDir = Directory(p.join(directory.path, 'user_books'));

    if (!offlineDir.existsSync()) {
      await offlineDir.create(recursive: true); // Ensure the directory exists
    }

    final bookPath = p.join(offlineDir.path, fileName);
    print('Constructed book path: $bookPath'); // Debug log
    return bookPath;
  }

  void _openBook(String bookTitle) async {
    try {
      final book = _books.firstWhere((book) => book['title'] == bookTitle);
      final relativePath = book['path'];

      // Get full book path
      final bookPath = await _getBookPath(relativePath);

      if (await File(bookPath).exists()) {
        VocsyEpub.setConfig(
          themeColor: Theme.of(context).primaryColor,
          identifier: "androidBook",
          scrollDirection: EpubScrollDirection.ALLDIRECTIONS,
          allowSharing: true,
          enableTts: true,
          nightMode: true,
        );
        VocsyEpub.open(bookPath);
      } else {
        throw Exception('Book not found at $bookPath');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening book: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                        trailing: IconButton(
                          icon: const Icon(Icons.book),
                          onPressed: () =>
                              _openBook(book['title']), // Pass book title
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
