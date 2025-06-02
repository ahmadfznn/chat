import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatusService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("status");
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  String? _userId;
  Timer? _typingTimer;

  StatusService() {
    _initUserId();
  }

  Future<void> _initUserId() async {
    if (_user == null) return;
    try {
      var userData = await db
          .collection("users")
          .where("email", isEqualTo: _user.email)
          .get();
      if (userData.docs.isNotEmpty) {
        _userId = userData.docs[0].id;
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error fetching user ID: $e");
    }
  }

  Stream<Map<String, dynamic>> getUserOnlineStatus(String userId) {
    DatabaseReference userStatusRef =
        FirebaseDatabase.instance.ref('status/connection/$userId');

    return userStatusRef.onValue.map((event) {
      final data = event.snapshot.value;

      if (data == null || data is! Map) {
        // ignore: avoid_print
        print("⚠️ Data masih null atau tidak valid di Firebase.");
        return {"status": false, "lastSeen": null};
      }

      final bool isOnline = data['online'] == true;
      final dynamic lastSeen =
          data.containsKey('lastSeen') ? data['lastSeen'] : null;

      return {"status": isOnline, "lastSeen": lastSeen};
    }).handleError((error) {
      // ignore: avoid_print
      print("❌ Error mengambil data dari Firebase: $error");
      return {"status": false, "lastSeen": null};
    });
  }

  Stream<Map<String, dynamic>> getUserTypingStatus(
      String roomId, String userId) {
    DatabaseReference userStatusRef =
        FirebaseDatabase.instance.ref('status/typing/$roomId/$userId');

    return userStatusRef.onValue.map((event) {
      final data = event.snapshot.value;

      if (data == null || data is! Map) {
        // ignore: avoid_print
        print("⚠️ Data masih null atau tidak valid di Firebase.");
        return {"status": false, "lastSeen": null};
      }

      final bool isTyping = data['typing'] == true;
      return {"status": isTyping};
    }).handleError((error) {
      // ignore: avoid_print
      print("❌ Error mengambil data dari Firebase: $error");
      return {"status": false};
    });
  }

  Future<void> setUserOnline() async {
    if (_userId == null) return;

    try {
      DatabaseReference userStatusRef =
          _dbRef.child("connection").child(_userId!);

      await userStatusRef.set({
        "online": true,
        "lastSeen": ServerValue.timestamp,
      });

      // ignore: avoid_print
      print("Status : Online");

      await userStatusRef.onDisconnect().set({
        "online": false,
        "lastSeen": ServerValue.timestamp,
      });
    } catch (e) {
      // ignore: avoid_print
      print("Error setting user online: $e");
    }
  }

  Future<void> setUserOffline() async {
    if (_userId == null) return;

    try {
      DatabaseReference userStatusRef =
          _dbRef.child("connection").child(_userId!);

      await userStatusRef.set({
        "online": false,
        "lastSeen": ServerValue.timestamp,
      });

      // ignore: avoid_print
      print("Status : Offline");
    } catch (e) {
      // ignore: avoid_print
      print("Error setting user offline: $e");
    }
  }

  void setTypingStatus(String chatRoomId, bool isTyping) async {
    if (_userId == null) return;

    try {
      DatabaseReference typingRef =
          _dbRef.child("typing").child(chatRoomId).child(_userId!);

      if (isTyping) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        typingRef.set({
          "typing": true,
          "timestamp": timestamp,
        });

        // ignore: avoid_print
        print("User is typing...");

        _typingTimer?.cancel();
        _typingTimer = Timer(Duration(seconds: 3), () async {
          final snapshot = await typingRef.get();
          if (snapshot.exists &&
              snapshot.child("timestamp").value == timestamp) {
            typingRef.set({"typing": false});
            // ignore: avoid_print
            print("User stopped typing...");
          }
        });
      } else {
        typingRef.set({"typing": false});
        // ignore: avoid_print
        print("User stopped typing...");
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error setting typing status: $e");
    }
  }
}
