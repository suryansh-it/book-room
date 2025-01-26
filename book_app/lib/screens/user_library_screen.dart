import 'package:flutter/material.dart';
import '../services/library_service.dart'; // Make sure this path is correct
import 'package:vocsy_epub_viewer/epub_viewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

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

  Future<String> _getBookPath(String fileName) async {
    Directory directory;

    if (Platform.isAndroid) {
      // For Android, use the application document directory
      directory = await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows) {
      // For Windows, use the hardcoded path directly for the books directory
      directory = Directory('D:/offline_books');
    } else {
      // For other platforms, use the default directory
      directory = await getApplicationDocumentsDirectory();
    }

    // If it's not Windows, we append the 'user_books' folder to the path
    final offlineDirPath = Platform.isWindows
        ? directory.path // Use the hardcoded Windows path directly
        : p.join(directory.path, 'user_books');
    final offlineDir = Directory(offlineDirPath);

    // Ensure the directory exists, but do not create it for Windows
    if (!Platform.isWindows && !offlineDir.existsSync()) {
      offlineDir.createSync(recursive: true);
    }

    // Log the constructed path for debugging
    final bookPath = p.join(offlineDirPath, fileName);
    print('Constructed book path: $bookPath'); // Debug output to check path

    return bookPath;
  }

  void _openBook(String bookTitle) async {
    try {
      // Fetch the book details from the list based on the title
      final book = _books.firstWhere((book) => book['title'] == bookTitle);
      final relativePath = book['path'];

      // Get the full book path using the helper function
      String bookPath;

      if (Platform.isWindows) {
        // On Windows, use the hardcoded path for reading books
        bookPath = 'D:/offline_books/';
      } else {
        // For other platforms, use the usual method to get the path
        bookPath = await _getBookPath(relativePath);
      }

      // Log the book path for debugging
      print('Attempting to open book at: $bookPath');

      // Check if the file exists before attempting to open it
      if (await File(bookPath).exists()) {
        // Set configuration for the EPUB viewer
        VocsyEpub.setConfig(
          themeColor: Theme.of(context).primaryColor,
          identifier: "iosBook",
          scrollDirection: EpubScrollDirection.ALLDIRECTIONS,
          allowSharing: true,
          enableTts: true,
          nightMode: true,
        );

        // Open the book using the Vocsy EPUB viewer
        VocsyEpub.open(bookPath);
      } else {
        throw Exception('Book file not found at: $bookPath');
      }
    } catch (e) {
      // Display an error message if any issue occurs
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
