import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class UserController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      QuerySnapshot<Map<String, dynamic>> userDoc = await _firestore
          .collection("users")
          .where("email", isEqualTo: user.email)
          .get();

      if (userDoc.docs.isEmpty) {
        return null;
      }

      return userDoc.docs[0].data();
    } catch (e) {
      // ignore: avoid_print
      print("Error saat mengambil data user: $e");
      return null;
    }
  }

  Future<void> uploadProfilePicture(File imageFile, String id) async {
    try {
      String filePath = "profile_pictures/$id.jpg";
      TaskSnapshot snapshot = await _storage.ref(filePath).putFile(imageFile);

      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection("users").doc(id).update({
        "profile_picture": downloadUrl,
      });
    } catch (e) {
      // ignore: avoid_print
      print("Error uploading profile picture: $e");
    }
  }

  Future<void> deleteProfilePicture(String id) async {
    try {
      String filePath = "profile_pictures/$id.jpg";
      await _storage.ref(filePath).delete();

      await _firestore.collection("users").doc(id).update({
        "profile_picture": FieldValue.delete(),
      });
    } catch (e) {
      // ignore: avoid_print
      print("Error deleting profile picture: $e");
    }
  }

  Future<File?> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }
}
