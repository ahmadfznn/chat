import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImagePreviewPage extends StatefulWidget {
  final String imagePath;

  const ImagePreviewPage({super.key, required this.imagePath});

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  Uint8List? editedImage;

  void _editImage() async {
    var result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditor(
          image: File(widget.imagePath).readAsBytesSync(),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        editedImage = result;
      });
    }
  }

  Future<void> _uploadToFirebase() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in.")),
        );
        return;
      }

      final storageRef = FirebaseStorage.instance.ref();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final imageRef = storageRef.child('stories/$uid/$fileName.jpg');

      UploadTask uploadTask;
      if (editedImage != null) {
        uploadTask = imageRef.putData(editedImage!);
      } else {
        uploadTask = imageRef.putFile(File(widget.imagePath));
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('stories').add({
        'uid': uid,
        'imageUrl': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image uploaded to Firebase! 🚀")),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
  }

  void _uploadImage() {
    // Start upload, but immediately pop and notify previous page
    _uploadToFirebase();
    Navigator.pop(context, true); // Pass a result to trigger refresh
  }

  @override
  Widget build(BuildContext context) {
    final image = editedImage != null
        ? Image.memory(editedImage!)
        : Image.file(File(widget.imagePath));

    return Scaffold(
      appBar: AppBar(title: const Text("Preview & Edit")),
      body: Stack(
        children: [
          Center(child: image),
          Positioned(
            left: 16,
            bottom: 16,
            child: ElevatedButton.icon(
              onPressed: _uploadImage,
              icon: const Icon(Icons.upload),
              label: const Text("Upload"),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _editImage,
              child: const Icon(Icons.edit),
            ),
          )
        ],
      ),
    );
  }
}
