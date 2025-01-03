// // # UI for reading ePub files
// import 'package:flutter/material.dart';
// import '../services/epub_service.dart';

// class EpubReaderScreen extends StatefulWidget {
//   final int bookId;

//   EpubReaderScreen({required this.bookId});

//   @override
//   _EpubReaderScreenState createState() => _EpubReaderScreenState();
// }

// class _EpubReaderScreenState extends State<EpubReaderScreen> {
//   final EpubService _epubService = EpubService();
//   int currentChapter = 1;
//   String chapterContent = '';
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadChapter();
//   }

//   Future<void> _loadChapter() async {
//     setState(() => isLoading = true);
//     try {
//       final content =
//           await _epubService.getEpubChapter(widget.bookId, currentChapter);
//       setState(() {
//         chapterContent = content;
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() => isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: ${e.toString()}')),
//       );
//     }
//   }

//   void _nextChapter() {
//     setState(() => currentChapter++);
//     _loadChapter();
//   }

//   void _previousChapter() {
//     if (currentChapter > 1) {
//       setState(() => currentChapter--);
//       _loadChapter();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('ePub Reader')),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: EdgeInsets.all(16.0),
//                     child: Text(chapterContent),
//                   ),
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     IconButton(
//                       icon: Icon(Icons.arrow_back),
//                       onPressed: currentChapter > 1 ? _previousChapter : null,
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.arrow_forward),
//                       onPressed: _nextChapter,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//     );
//   }
// }
