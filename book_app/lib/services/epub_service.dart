import 'package:dio/dio.dart';
import 'auth_service.dart';
import '../models/book.dart';

// class EpubService {
//   final Dio _dio = Dio(BaseOptions(baseUrl: "http://10.0.2.2:8011/api/books/"));
//   final AuthService _authService = AuthService();

//   // Download ePub
//   Future<String> downloadEpub(
//       String title, String author, String downloadUrl, String savePath) async {
//     try {
//       // Fetch token from AuthService
//       final token = await _authService.getlogin();
//       if (token == null) {
//         throw Exception("Authentication required. Please log in.");
//       }

//       // Add Authorization header
//       _dio.options.headers['Authorization'] = 'Bearer $token';

//       print("Initiating download for $title by $author");
//       print("Downloading from: $downloadUrl");
//       print("Saving to: $savePath");

//       final sanitizedAuthor = author.isNotEmpty ? author : "Unknown Author";

//       final response = await _dio.download(
//         '/download',
//         savePath,
//         queryParameters: {
//           'title': title,
//           'author': sanitizedAuthor,
//           'url': downloadUrl
//         },
//         onReceiveProgress: (received, total) {
//           if (total != -1) {
//             print(
//                 "Downloading: ${(received / total * 100).toStringAsFixed(0)}%");
//           }
//         },
//       );

//       if (response.statusCode == 200) {
//         print("Download completed for $title");
//         return savePath;
//       } else {
//         throw Exception("Download failed: ${response.statusMessage}");
//       }
//     } catch (e) {
//       print("Error during download: $e");
//       throw Exception("Download failed: $e");
//     }
//   }
// }

class EpubService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: "http://192.168.10.250:8019/api/books/",
  ));
  final AuthService _authService = AuthService();

  Future<String> downloadEpub(Book book, String savePath) async {
    try {
      final token = await _authService.getlogin();
      if (token == null) {
        throw Exception("Authentication required. Please log in.");
      }

      _dio.options.headers['Authorization'] = 'Bearer $token';

      if (book.downloadLink == null) {
        throw Exception("Download link is missing for this book.");
      }

      print("Initiating download for ${book.title} by ${book.author}");
      print("Downloading from: ${book.downloadLink}");
      print("Saving to: $savePath");

      // Use FormData to send data in the request body
      FormData formData = FormData.fromMap({
        'libgen_link': book.downloadLink,
        'title': book.title,
        'author': book.author,
      });

      final response = await _dio.post(
        // Use POST request
        'download/',
        data: formData, // Send FormData
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print(
                "Downloading: ${(received / total * 100).toStringAsFixed(0)}%");
          }
        },
        options: Options(
          // Important: Set content type
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 201) {
        print("Download completed for ${book.title}");
        return savePath;
      } else {
        throw Exception(
            "Download failed: ${response.statusCode} ${response.statusMessage} ${response.data}"); // Include response data for debugging
      }
    } catch (e) {
      print("Error during download: $e");
      throw Exception("Download failed: $e");
    }
  }
}
