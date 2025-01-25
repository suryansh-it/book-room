import 'package:flutter/material.dart';
import '../services/epubReader_service.dart';

class BookReaderPage extends StatefulWidget {
  final int bookId;
  final String bookTitle;

  const BookReaderPage(
      {Key? key, required this.bookId, required this.bookTitle})
      : super(key: key);

  @override
  _BookReaderPageState createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage> {
  final EpubReaderService _epubService = EpubReaderService();
  int _currentChapter = 1;
  String _chapterContent = '';
  bool _isLoading = true;
  bool _hasNextChapter = true;

  @override
  void initState() {
    super.initState();
    _loadChapter();
  }

  Future<void> _loadChapter({int chapterPage = 1}) async {
    setState(() => _isLoading = true);

    try {
      final response = await _epubService.fetchEpubContent(
        bookId: widget.bookId,
        chapterPage: chapterPage,
        chaptersPerPage: 1,
      );

      setState(() {
        _chapterContent = response['chapters'][0]['content'];
        _currentChapter = chapterPage;
        _hasNextChapter = chapterPage < response['total_chapters'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading chapter: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextChapter() {
    if (_hasNextChapter) {
      _loadChapter(chapterPage: _currentChapter + 1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This is the last chapter.')),
      );
    }
  }

  void _previousChapter() {
    if (_currentChapter > 1) {
      _loadChapter(chapterPage: _currentChapter - 1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This is the first chapter.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      _chapterContent,
                      style: TextStyle(fontSize: 16.0, height: 1.5),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed:
                            _currentChapter > 1 ? _previousChapter : null,
                        child: Text('Previous'),
                      ),
                      ElevatedButton(
                        onPressed: _hasNextChapter ? _nextChapter : null,
                        child: Text('Next'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
