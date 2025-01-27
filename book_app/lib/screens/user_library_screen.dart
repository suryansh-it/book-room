import 'package:flutter/material.dart';
import 'package:vocsy_epub_viewer/epub_viewer.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class UserLibraryScreen extends StatefulWidget {
  const UserLibraryScreen({super.key});

  @override
  State<UserLibraryScreen> createState() => _UserLibraryScreenState();
}

class _UserLibraryScreenState extends State<UserLibraryScreen> {
  List<Map<String, String>> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLibraryBooks();
  }

  Future<void> _fetchLibraryBooks() async {
    try {
      // Get the Downloads/user_books directory
      final downloadsDir = Directory('/storage/emulated/0/Download/user_books');

      // Check if directory exists
      if (!downloadsDir.existsSync()) {
        // Create the directory if it doesn't exist
        await downloadsDir.create(recursive: true);
      }

      // Retrieve list of .epub files in the folder
      final books = downloadsDir
          .listSync()
          .where((file) => file is File && file.path.endsWith('.epub'))
          .map((file) => {
                'title': p.basenameWithoutExtension(file.path),
                'path': file.path,
              })
          .toList();

      setState(() {
        _books = books.cast<Map<String, String>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching library: ${e.toString()}')),
      );
    }
  }

  void _openBook(String bookPath) async {
    try {
      if (await File(bookPath).exists()) {
        VocsyEpub.setConfig(
          themeColor: Theme.of(context).primaryColor,
          identifier: "androidBook",
          scrollDirection: EpubScrollDirection.VERTICAL,
          allowSharing: true,
          enableTts: true,
          nightMode: false,
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
                        subtitle: const Text('Tap to read'),
                        trailing: IconButton(
                          icon: const Icon(Icons.book),
                          onPressed: () =>
                              _openBook(book['path']!), // Pass book path
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
