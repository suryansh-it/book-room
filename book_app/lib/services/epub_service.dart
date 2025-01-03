import 'package:dio/dio.dart';
import 'auth_service.dart'; // Import AuthService

class EpubService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://10.0.2.2:8011/api/books/"));
  final AuthService _authService = AuthService(); // Use AuthService instance

  // Method to download ePub file
  Future<String> downloadEpub(String downloadUrl, String savePath) async {
    try {
      // Retrieve token using AuthService
      final token = await _authService.getlogin();
      if (token == null) {
        throw Exception("Authentication token not found. Please log in.");
      }

      // Set authorization header dynamically
      _dio.options.headers['Authorization'] = 'Bearer $token';

      print("Initiating download from: $downloadUrl");
      print("Saving file to: $savePath");

      final response = await _dio.download(
        "${_dio.options.baseUrl}download/", // Use dynamic download URL
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print(
                "Downloading: ${(received / total * 100).toStringAsFixed(0)}%");
          }
        },
      );

      if (response.statusCode == 200) {
        print("Download complete. File saved to $savePath");
        return savePath; // Return the saved file path
      } else {
        print("Download failed with status: ${response.statusCode}");
        throw Exception(
            "Failed to download ePub file: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error during download: $e");
      throw Exception("Failed to download ePub file: $e");
    }
  }
}
