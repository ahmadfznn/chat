import 'dart:io';
import 'package:flutter/material.dart';

class PhotoPreviewPage extends StatelessWidget {
  final String imagePath;

  const PhotoPreviewPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Preview Foto")),
      body: Column(
        children: [
          Expanded(
            child: Image.file(File(imagePath), fit: BoxFit.contain),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text("Upload"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                Navigator.pop(context, imagePath);
              },
            ),
          ),
        ],
      ),
    );
  }
}
