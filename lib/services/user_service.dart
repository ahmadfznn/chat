import 'dart:async';
import 'dart:io';
import 'package:chat/models/user_model.dart';
import 'package:chat/services/local_database.dart';
import 'package:chat/services/status_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDatabase _userDatabase = LocalDatabase.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final StreamController<List<UserModel>> _userController =
      StreamController.broadcast();
  StreamSubscription? _connectivitySubscription;
  bool _isOnline = true;

  Stream<List<UserModel>> get userStream => _userController.stream;

  UserService(String username) {
    _monitorConnectivity(username);
  }

  void _monitorConnectivity(String username) {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      // ignore: unrelated_type_equality_checks
      bool isNowOnline = (ConnectivityResult.none != result);
      if (isNowOnline != _isOnline) {
        _isOnline = isNowOnline;
        fetchUsers(username);
      }
    });
  }

  void fetchUsers(String username) async {
    if (_isOnline) {
      await _fetchFromFirestore(username);
    } else {
      await _fetchFromSQLite(username);
    }
  }

  Future<void> _fetchFromFirestore(String username) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where("username", isNotEqualTo: username)
          .get();

      List<UserModel> updatedUsers = [];

      for (var doc in snapshot.docs) {
        var d = doc.data() as Map<String, dynamic>;

        bool isFriend = await _checkFriendship(username, doc.id);

        updatedUsers.add(UserModel(
          id: doc.id,
          name: d['displayName'] ?? '',
          username: d['username'] ?? '',
          phoneNumber: d['phone_number'] ?? '',
          bio: d['bio'] ?? '',
          status: d['status'] ?? '',
          profilePicture: d['profile_picture'] ?? '',
          gender: d['gender'] ?? '',
          country: d['country'] ?? '',
          visibility: d['visibility'] == 'public',
          isFriend: isFriend,
          lastActivity:
              (d['lastActivity'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ));
      }

      for (var user in updatedUsers) {
        var existingUser = await _userDatabase.getUserById(user.id);
        if (existingUser == null) {
          await _userDatabase.upsertUser(user);
        } else {
          await _userDatabase.updateUser(user);
        }
      }

      _userController.add(updatedUsers);
    } catch (e) {
      // ignore: avoid_print
      print("Gagal mengambil data pengguna: $e");
    }
  }

  Future<bool> _checkFriendship(
      String currentUsername, String targetUserId) async {
    try {
      var userDoc = await _firestore
          .collection("users")
          .where("username", isEqualTo: currentUsername)
          .get();

      if (userDoc.docs.isEmpty) return false;

      var currentUserId = userDoc.docs.first.id;

      DocumentSnapshot friendshipDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection("relationships")
          .doc("friends")
          .get();

      Map<String, dynamic>? friend =
          friendshipDoc.data() as Map<String, dynamic>?;
      List<String> friendIds = (friend?['friend_id'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      return friendIds.contains(targetUserId);
    } catch (e) {
      // ignore: avoid_print
      print("Gagal mengecek status pertemanan: $e");
      return false;
    }
  }

  Future<void> toggleFriendship(
      Map<String, dynamic> user, String targetUserId) async {
    try {
      String currentUserId = user['id'];
      String username = user['username'];
      DocumentReference userRef =
          _firestore.collection('users').doc(currentUserId);
      DocumentReference targetRef =
          _firestore.collection('users').doc(targetUserId);

      DocumentSnapshot friendshipDoc =
          await userRef.collection("relationships").doc("friends").get();

      Map<String, dynamic>? friendshipData =
          friendshipDoc.data() as Map<String, dynamic>?;

      List<String> friendIds = (friendshipData?['friend_id'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      bool isFriend = friendIds.contains(targetUserId);

      if (isFriend) {
        await userRef.collection("relationships").doc("friends").update({
          "friend_id": FieldValue.arrayRemove([targetUserId])
        });

        await targetRef.collection("relationships").doc("friends").update({
          "friend_id": FieldValue.arrayRemove([currentUserId])
        });
      } else {
        await userRef.collection("relationships").doc("friends").set({
          "friend_id": FieldValue.arrayUnion([targetUserId])
        }, SetOptions(merge: true));

        await targetRef.collection("relationships").doc("friends").set({
          "friend_id": FieldValue.arrayUnion([currentUserId])
        }, SetOptions(merge: true));
      }

      UserModel? targetUser = await _userDatabase.getUserById(targetUserId);
      if (targetUser != null) {
        UserModel updatedUser = targetUser.copyWith(isFriend: !isFriend);
        await _userDatabase.updateUser(updatedUser);

        List<UserModel> updatedList = await _userDatabase.getUsers(username);
        _userController.add(updatedList);
      }

      // ignore: avoid_print
      print("Berhasil ${isFriend ? "menghapus" : "menambahkan"} teman!");
    } catch (e) {
      // ignore: avoid_print
      print("Gagal toggle friend: $e");
    }
  }

  Future<void> uploadProfilePicture(String userId, File imageFile) async {
    try {
      String filePath = "profile_pictures/$userId.jpg";
      TaskSnapshot snapshot = await _storage.ref(filePath).putFile(imageFile);

      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('users').doc(userId).update({
        "profile_picture": downloadUrl,
      });

      UserModel? existingUser = await _userDatabase.getUserById(userId);
      if (existingUser != null) {
        UserModel updatedUser =
            existingUser.copyWith(profilePicture: downloadUrl);
        await _userDatabase.updateUser(updatedUser);
      }

      // ignore: avoid_print
      print("✅ Profile picture uploaded & updated successfully!");
    } catch (e) {
      // ignore: avoid_print
      print("❌ Error uploading profile picture: $e");
    }
  }

  Future<void> updateProfile(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection("users").doc(id).update(data);
    } catch (e) {
      // ignore: avoid_print
      print("❌ Error update profile: $e");
    }
  }

  Future<void> deleteProfilePicture(String userId) async {
    try {
      String filePath = "profile_pictures/$userId.jpg";
      await _storage.ref(filePath).delete();

      await _firestore.collection('users').doc(userId).update({
        "profile_picture": FieldValue.delete(),
      });

      UserModel? existingUser = await _userDatabase.getUserById(userId);
      if (existingUser != null) {
        UserModel updatedUser = existingUser.copyWith(profilePicture: null);
        await _userDatabase.updateUser(updatedUser);
      }

      // ignore: avoid_print
      print("✅ Profile picture deleted successfully!");
    } catch (e) {
      // ignore: avoid_print
      print("❌ Error deleting profile picture: $e");
    }
  }

  Future<void> _fetchFromSQLite(String username) async {
    List<UserModel> users = await _userDatabase.getUsers(username);
    _userController.add(users);
  }

  Future<void> setUserSignInStatus(String userId, bool isSignin) async {
    try {
      final StatusService statusService = StatusService();

      await _firestore.collection('users').doc(userId).update({
        'isSignin': isSignin,
      });
      if (!isSignin) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('user_metadata')
            .doc('security')
            .update({'fcm': FieldValue.delete()});

        await statusService.setUserOffline();
      } else {
        await statusService.setUserOnline();
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error updating sign-in status: $e");
    }
  }

  Future<void> refreshUsers(String username) async {
    if (_isOnline) {
      await _fetchFromFirestore(username);
    } else {
      await _fetchFromSQLite(username);
    }
  }

  void dispose() {
    _userController.close();
    _connectivitySubscription?.cancel();
  }
}
