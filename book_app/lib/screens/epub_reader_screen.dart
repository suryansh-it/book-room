class EpubReaderScreen extends StatefulWidget {
  final int bookId;
  final String bookTitle;

  EpubReaderScreen({required this.bookId, required this.bookTitle});

  @override
  _EpubReaderScreenState createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
  // (Existing code remains the same)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.bookTitle)),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.0),
                    child: Text(chapterContent),
                  ),
                ),
                // (Pagination controls remain the same)
              ],
            ),
    );
  }
}
