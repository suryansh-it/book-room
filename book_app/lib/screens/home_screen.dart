// import 'package:flutter/material.dart';
// import 'search_results_screen.dart';
// import 'user_library_screen.dart';

// class HomeScreen extends StatelessWidget {
//   HomeScreen({super.key});

//   final TextEditingController _searchController = TextEditingController();

//   void _searchBooks(BuildContext context) {
//     final query = _searchController.text;
//     if (query.isNotEmpty) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => SearchResultsScreen(query: query)),
//       );
//     }
//   }

//  @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(
//       title: Text('Welcome to the Book App'),
//       actions: [
//         IconButton(
//           icon: Icon(Icons.logout),
//           onPressed: () {
//             Navigator.pushReplacementNamed(context, '/login');
//           },
//         ),
//       ],
//     ),
//     body: Padding(
//       padding: EdgeInsets.all(16.0),
//       child: Column(
//         children: [
//           TextField(
//             controller: _searchController,
//             decoration: InputDecoration(
//               labelText: 'Search for books',
//               border: OutlineInputBorder(),
//             ),
//           ),
//           SizedBox(height: 20),
//           ElevatedButton(
//             onPressed: () => _searchBooks(context),
//             child: Text('Search'),
//           ),
//           SizedBox(height: 20),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => UserLibraryScreen()),
//               );
//             },
//             child: Text('Go to My Library'),
//           ),
//         ],
//       ),
//     ),
//   );
// }

import 'package:flutter/material.dart';
import 'search_results_screen.dart';
import 'user_library_screen.dart';

class HomeScreen extends StatefulWidget {
  // Use StatefulWidget if needed
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    // Dispose of the controller
    _searchController.dispose();
    super.dispose();
  }

  void _searchBooks(BuildContext context) {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SearchResultsScreen(query: query)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to the Book App'), // Use const for Text
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), // Use const for Icon
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Use const for EdgeInsets
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                // Use const for InputDecoration
                labelText: 'Search for books',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20), // Use const for SizedBox
            ElevatedButton(
              onPressed: () => _searchBooks(context),
              child: const Text('Search'), // Use const for Text
            ),
            const SizedBox(height: 20), // Use const for SizedBox
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const UserLibraryScreen()), // Use const here as well
                );
              },
              child: const Text('Go to My Library'), // Use const for Text
            ),
          ],
        ),
      ),
    );
  }
}
