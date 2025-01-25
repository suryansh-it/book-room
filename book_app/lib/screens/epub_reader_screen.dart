import 'package:flutter/material.dart';

class EpubReaderScreen extends StatefulWidget {
  final int bookId;
  final String bookTitle;

  const EpubReaderScreen({
    Key? key,
    required this.bookId,
    required this.bookTitle,
  }) : super(key: key);

  @override
  _EpubReaderScreenState createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
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
      // Simulate fetching content (replace with actual service call)
      await Future.delayed(Duration(seconds: 1)); // Simulating API delay
      final response = {
        'chapters': [
          {'content': 'Content of chapter $chapterPage'}
        ],
        'total_chapters': 5,
      };

      setState(() {
        _chapterContent =
            (response['chapters'] as List<dynamic>?)?.isNotEmpty == true
                ? (response['chapters'] as List<dynamic>)[0]['content'] ??
                    'Chapter is empty.'
                : 'No chapters available.';
        _currentChapter = chapterPage;
        _hasNextChapter =
            chapterPage < (response['total_chapters'] as num? ?? 0);
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
      appBar: AppBar(title: Text(widget.bookTitle)),
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

void main() {
  runApp(MaterialApp(
    home: EpubReaderScreen(
      bookId: 1,
      bookTitle: 'Sample Book',
    ),
  ));
}
