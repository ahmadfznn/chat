import 'package:chat/pages/camera_page.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class Story extends StatefulWidget {
  const Story({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  // ignore: library_private_types_in_public_api
  _StoryState createState() => _StoryState();
}

class _StoryState extends State<Story> {
  Future<void> _openCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraPage()),
    );

    if (result != null) {
      _uploadStory(result);
    }
  }

  Future<void> _uploadStory(String filePath) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(seconds: 2));

    // ignore: use_build_context_synchronously
    Navigator.pop(context);
    debugPrint("✅ Upload sukses: $filePath");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _openCamera,
        backgroundColor: const Color(0xFF2fbffb),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: Icon(IconsaxPlusBold.camera, size: 30),
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              spacing: 5,
              children: [
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.blue, width: 4),
                      borderRadius: BorderRadius.circular(100)),
                  child: Center(
                    child: IconButton(
                      icon: Icon(IconsaxPlusBold.add_circle,
                          color: Colors.blue, size: 30),
                      onPressed: _openCamera,
                    ),
                  ),
                ),
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.blue, width: 4),
                      borderRadius: BorderRadius.circular(100)),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset("assets/img/user.png"),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
