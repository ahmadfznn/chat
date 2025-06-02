import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class MediaStorage {
  static Future<String?> downloadMedia(String mediaUrl, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      String filePath = "${directory.path}/$fileName";
      if (File(filePath).existsSync()) {
        return filePath;
      }
      await Dio().download(mediaUrl, filePath);
      return filePath;
    } catch (e) {
      // ignore: avoid_print
      print("Gagal mengunduh media: $e");
      return null;
    }
  }
}
