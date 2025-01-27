import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'auth_service.dart';
import '../models/book.dart';
import 'package:flutter/material.dart';

class EpubService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: "http://192.168.10.250:8019/api/books/",
  ));
  final Dio _dio2 = Dio(BaseOptions(
    baseUrl: "http://192.168.10.250:8019/",
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
        'download/', // Match the backend route for downloading
        data: formData, // Send FormData
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print(
                "Downloading: ${(received / total * 100).toStringAsFixed(0)}%");
          }
        },
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 201) {
        // Retrieve the download URL from backend response
        final downloadUrl = response.data['file_url'];
        if (downloadUrl == null) {
          throw Exception("Download URL not found in the response.");
        }

        // Initiate the actual download with the URL
        final fileResponse = await _dio2.get(
          downloadUrl,
          options: Options(responseType: ResponseType.stream),
          onReceiveProgress: (received, total) {
            if (total != -1) {
              print(
                  "Downloading: ${(received / total * 100).toStringAsFixed(0)}%");
            }
          },
        );

        // Ensure directory exists
        final fileDir = Directory(savePath);
        if (!fileDir.existsSync()) {
          fileDir.createSync(recursive: true);
        }

        final file = File('$savePath/${book.title}.epub');
        await file.writeAsBytes(await fileResponse.data!.toBytes());

        print("Download completed for ${book.title}");
        return savePath;
      } else {
        throw Exception(
            "Download failed: ${response.statusCode} ${response.statusMessage}");
      }
    } catch (e) {
      print("Error during download: $e");
      throw Exception("Download failed: $e");
    }
  }
}
