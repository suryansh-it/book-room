import 'package:flutter/material.dart';
import 'book_reader_page.dart';

class EpubReaderScreen extends StatelessWidget {
  final int bookId;
  final String bookTitle;

  const EpubReaderScreen({
    Key? key,
    required this.bookId,
    required this.bookTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(bookTitle),
      ),
      body: BookReaderPage(
        bookId: bookId,
        bookTitle: bookTitle,
      ),
    );
  }
}
