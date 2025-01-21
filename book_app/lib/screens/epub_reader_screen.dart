import 'package:flutter/material.dart';
import '../services/epub_service.dart';

class EpubReaderScreen extends StatefulWidget {
  final int bookId;

  EpubReaderScreen({required this.bookId});

  @override
  _EpubReaderScreenState createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
  final EpubService _epubService = EpubService();

  int currentChapterPage = 1;
  int currentSectionPage = 1;
  String chapterTitle = '';
  String sectionContent = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChapter();
  }

  Future<void> _loadChapter() async {
    setState(() => isLoading = true);

    try {
      final response = await _epubService.fetchEpubChapter(
        bookId: widget.bookId,
        chapterPage: currentChapterPage,
        sectionPage: currentSectionPage,
      );

      setState(() {
        chapterTitle = response['chapters'][0]['chapter_title'];
        sectionContent = response['chapters'][0]['section_content'];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _nextSection() {
    setState(() => currentSectionPage++);
    _loadChapter();
  }

  void _previousSection() {
    if (currentSectionPage > 1) {
      setState(() => currentSectionPage--);
      _loadChapter();
    }
  }

  void _nextChapter() {
    setState(() {
      currentChapterPage++;
      currentSectionPage = 1; // Reset section to 1 for the new chapter
    });
    _loadChapter();
  }

  void _previousChapter() {
    if (currentChapterPage > 1) {
      setState(() {
        currentChapterPage--;
        currentSectionPage = 1;
      });
      _loadChapter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ePub Reader')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    chapterTitle,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.0),
                    child: Text(sectionContent),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: currentSectionPage > 1
                          ? _previousSection
                          : null, // Disable if on the first section
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward),
                      onPressed: _nextSection,
                    ),
                  ],
                ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left),
                      onPressed: currentChapterPage > 1
                          ? _previousChapter
                          : null, // Disable if on the first chapter
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right),
                      onPressed: _nextChapter,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
