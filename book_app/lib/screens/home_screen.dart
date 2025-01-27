import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '/services/permission_service.dart';
import 'search_results_screen.dart';
import 'user_library_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  // Check file access permissions
  Future<void> _checkPermissions() async {
    bool granted = await PermissionService().requestFilePermissions();
    if (!granted) {
      // Show dialog if permission is not granted
      showPermissionDialog(context);
    }
    setState(() {
      _hasPermission = granted;
    });
  }

  @override
  void dispose() {
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

  void showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text(
            'This app requires file access to download and read books. Please grant permission.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings(); // Redirect to app settings
              Navigator.pop(context); // Close the dialog after redirect
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Permission Required'),
        ),
        body: const Center(
          child: Text(
            'File access permission is required to use this app. Please enable it in settings.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Main content of the HomeScreen
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to the Book App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search for books',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _searchBooks(context),
              child: const Text('Search'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserLibraryScreen(),
                  ),
                );
              },
              child: const Text('Go to My Library'),
            ),
          ],
        ),
      ),
    );
  }
}
