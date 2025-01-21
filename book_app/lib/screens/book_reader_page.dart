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

  int currentChapterPage = 1;
  int chaptersPerPage = 1;
  int currentSectionPage = 1;
  int sectionSize = 500;

  List<dynamic> currentChapters = [];
  int totalChapters = 0;
  int totalChapterPages = 0;
  bool isLoading = false;

  Future<void> fetchContent() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await _epubService.fetchEpubContent(
        bookId: widget.bookId,
        chapterPage: currentChapterPage,
        chaptersPerPage: chaptersPerPage,
        sectionPage: currentSectionPage,
        sectionSize: sectionSize,
      );

      setState(() {
        currentChapters = data['chapters'] ?? [];
        totalChapters = data['total_chapters'] ?? 0;
        totalChapterPages = data['total_chapter_pages'] ?? 0;
      });
    } catch (e) {
      print('Error fetching content: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchContent();
  }

  void nextChapterPage() {
    if (currentChapterPage < totalChapterPages) {
      setState(() {
        currentChapterPage++;
        currentSectionPage = 1; // Reset section page
      });
      fetchContent();
    }
  }

  void previousChapterPage() {
    if (currentChapterPage > 1) {
      setState(() {
        currentChapterPage--;
        currentSectionPage = 1; // Reset section page
      });
      fetchContent();
    }
  }

  void nextSection() {
    setState(() {
      currentSectionPage++;
    });
    fetchContent();
  }

  void previousSection() {
    if (currentSectionPage > 1) {
      setState(() {
        currentSectionPage--;
      });
      fetchContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bookTitle),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: currentChapters.length,
                    itemBuilder: (context, index) {
                      final chapter = currentChapters[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chapter['chapter_title'],
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                chapter['section_content'],
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Section ${chapter['current_section_page']} of ${chapter['total_sections']}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: previousChapterPage,
                      ),
                      Text('Chapter $currentChapterPage of $totalChapterPages'),
                      IconButton(
                        icon: Icon(Icons.arrow_forward),
                        onPressed: nextChapterPage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
