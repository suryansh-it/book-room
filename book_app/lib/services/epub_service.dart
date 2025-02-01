import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'auth_service.dart';
import '../models/book.dart';
import 'package:flutter/material.dart';

class EpubService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: "http://unbind.onrender.com/api/books/",
  ));

  final Dio _dio2 = Dio(BaseOptions(
    baseUrl: "http://unbind.onrender.com/",
  ));

  final AuthService _authService = AuthService();

  Future<String> downloadEpub(Book book) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception("Authentication required. Please log in.");
      }

      _dio.options.headers['Authorization'] = 'Bearer $token';

      if (book.downloadLink == null) {
        throw Exception("Download link is missing for this book.");
      }

      print("Initiating download for ${book.title} by ${book.author}");

      // Prepare save directory
      Directory appDir = await getApplicationDocumentsDirectory();
      String saveDirPath = '${appDir.path}/user_books';
      await Directory(saveDirPath).create(recursive: true);

      // Step 1: Request the file URL from the backend
      FormData formData = FormData.fromMap({
        'libgen_link': book.downloadLink,
        'title': book.title,
        'author': book.author,
      });

      final response = await _dio.post(
        'download/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 201) {
        final downloadUrl = response.data['file_url'];

        if (downloadUrl == null) {
          throw Exception("Download URL not found in the response.");
        }

        // Step 2: Download the file using the provided URL
        String sanitizedTitle =
            book.title.replaceAll(RegExp(r'[\\/:"*?<>|]+'), '_');
        String saveFilePath = '$saveDirPath/$sanitizedTitle.epub';

        final downloadResponse = await _dio2.download(
          downloadUrl,
          saveFilePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              print(
                  "Downloading: ${(received / total * 100).toStringAsFixed(0)}%");
            }
          },
        );

        if (downloadResponse.statusCode == 200) {
          print("Download completed for ${book.title} at $saveFilePath");
          // Delete from backend *after* successful download
          await _deleteAllBooks(); // New function
          return saveFilePath;
        } else {
          throw Exception(
              "File download failed: ${downloadResponse.statusCode} ${downloadResponse.statusMessage}");
        }
      } else {
        throw Exception(
            "Failed to retrieve file URL: ${response.statusCode} ${response.statusMessage}");
      }
    } catch (e) {
      print("Error during download: $e");
      throw Exception("Download failed: $e");
    }
  }

  Future<void> _deleteAllBooks() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception("Authentication required for deletion.");
    }

    _dio.options.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await _dio.delete('delete/'); // Correct delete URL

      if (response.statusCode == 200) {
        print("Books deleted from server ");
      } else {
        print("Failed to delete books from server");
      }
    } catch (e) {
      print("Error deleting book from server: $e");
    }
  }
}
