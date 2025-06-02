import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'image_preview_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _picker = ImagePicker();

  void _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (_) => ImagePreviewPage(imagePath: image.path),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CameraAwesomeBuilder.awesome(
            enablePhysicalButton: true,
            saveConfig: SaveConfig.photoAndVideo(),
            progressIndicator: const CircularProgressIndicator(
              color: Colors.blue,
            ),
            onMediaTap: (mediaCapture) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImagePreviewPage(
                      imagePath: mediaCapture.captureRequest.path!),
                ),
              );
            },
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: "gallery_btn",
              onPressed: _pickFromGallery,
              child: const Icon(Icons.photo_library),
            ),
          )
        ],
      ),
    );
  }
}
