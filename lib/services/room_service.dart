import 'dart:async';
import 'package:chat/controller/chat_controller.dart';
import 'package:chat/models/chat_room_model.dart';
import 'package:chat/services/local_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDatabase _roomDatabase = LocalDatabase.instance;
  final ChatController chatController = Get.put(ChatController());

  final StreamController<List<ChatRoomModel>> _chatRoomsController =
      StreamController.broadcast();
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _firestoreSubscription;

  bool _isOnline = true;
  List rooms = [];
  List<ChatRoomModel> _originalRooms = [];

  Stream<List<ChatRoomModel>> get chatRoomsStream =>
      _chatRoomsController.stream;

  RoomService(String userId) {
    _monitorConnectivity(userId);
  }

  void _monitorConnectivity(String userId) {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      // ignore: unrelated_type_equality_checks
      bool isNowOnline = (ConnectivityResult.none != result);
      if (isNowOnline != _isOnline) {
        _isOnline = isNowOnline;
        fetchChatRooms(userId);
      }
    });
  }

  void fetchChatRooms(String userId) {
    print("fetchChatRooms() dipanggil dengan _isOnline = $_isOnline");
    if (_isOnline) {
      print("Fetching dari Firestore...");
      _fetchFromFirestore(userId);
    } else {
      print("Fetching dari SQLite...");
      _fetchFromSQLite();
    }
  }

  void _fetchFromFirestore(String userId) {
    _firestoreSubscription?.cancel();

    _firestoreSubscription = _firestore
        .collection('chatRoom')
        .where("participants", arrayContains: userId)
        .orderBy("updated_at", descending: true)
        .snapshots()
        .listen((snapshot) async {
      if (_chatRoomsController.isClosed) return;

      List<ChatRoomModel> updatedRooms = [];

      for (var doc in snapshot.docs) {
        var d = doc.data();
        var recipientId =
            d["participants"].firstWhere((value) => value != userId);

        var recipient =
            await _firestore.collection("users").doc(recipientId).get();

        ChatRoomModel room = ChatRoomModel(
          id: doc.id,
          archived: (d['archived_by'] as List).contains(userId),
          pinned: (d['pinned_by'] as List).contains(userId),
          hided: (d['hided_by'] as List).contains(userId),
          recipientId: recipient.id ?? '',
          recipientName: recipient.data()?['displayName'] ?? '',
          recipientBio: recipient.data()?['bio'] ?? '',
          recipientPhoto: recipient.data()?['profile_picture'] ?? '',
          lastMessage: d['lastMessage'] ?? '',
          type: d['type'] ?? '',
          status: d['status'] ?? -1,
          unread: d['unread'] ?? 0,
          updatedAt: d['updated_at'] is Timestamp
              ? (d['updated_at'] as Timestamp).millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch,
        );

        updatedRooms.add(room);

        var existingRoom = await _roomDatabase.getChatRoomById(room.id);
        if (existingRoom == null) {
          await _roomDatabase.insertChatRoom(room);
        } else if (existingRoom.updatedAt != room.updatedAt) {
          await _roomDatabase.updateChatRoom(room);
        }
      }

      print("_originalRooms sebelum diisi: $_originalRooms");
      _originalRooms = updatedRooms;
      print("_originalRooms setelah diisi: $_originalRooms");

      if (!_chatRoomsController.isClosed) {
        _chatRoomsController.add(updatedRooms);
      }
    });
  }

  void _fetchFromSQLite() async {
    List<ChatRoomModel> rooms = await _roomDatabase.getChatRooms();
    _chatRoomsController.add(rooms);
  }

  Future<Map<String, dynamic>> openRoom(
      String userId, String recipientId) async {
    try {
      if (!_isOnline) {
        var localRoom = await _roomDatabase.getChatRoomByRecipient(recipientId);
        if (localRoom != null) {
          return {"status": true, "data": localRoom};
        } else {
          ChatRoomModel newLocalRoom = ChatRoomModel(
            id: "offline_${DateTime.now().millisecondsSinceEpoch}",
            archived: false,
            pinned: false,
            hided: false,
            recipientId: recipientId,
            recipientName: "",
            recipientBio: "",
            recipientPhoto: "",
            lastMessage: "",
            type: "",
            status: 0,
            unread: 0,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );

          await _roomDatabase.insertChatRoom(newLocalRoom);

          return {"status": true, "data": newLocalRoom};
        }
      }

      var existingRoomQuery = await _firestore
          .collection('chatRoom')
          .where('participants', arrayContains: userId)
          .get();

      ChatRoomModel? foundRoom;

      for (var doc in existingRoomQuery.docs) {
        var data = doc.data();
        List participants = data['participants'];

        if (participants.contains(recipientId)) {
          var recipient =
              await _firestore.collection("users").doc(recipientId).get();
          foundRoom = ChatRoomModel(
            id: doc.id,
            archived: (data['archived_by'] as List).contains(userId),
            pinned: (data['pinned_by'] as List).contains(userId),
            hided: (data['hided_by'] as List).contains(userId),
            recipientId: recipientId,
            recipientName: recipient.data()!['displayName'] ?? '',
            recipientBio: recipient.data()!['bio'] ?? '',
            recipientPhoto: recipient.data()!['profile_picture'] ?? '',
            lastMessage: data['lastMessage'] ?? '',
            type: data['type'] ?? '',
            status: data['status'] ?? 0,
            unread: data['unread'] ?? 0,
            updatedAt: data['updated_at'].millisecondsSinceEpoch ?? '',
          );
          break;
        }
      }

      if (foundRoom != null) {
        var existingRoom = await _roomDatabase.getChatRoomById(foundRoom.id);
        if (existingRoom == null) {
          await _roomDatabase.insertChatRoom(foundRoom);
        }

        return {"status": true, "data": foundRoom};
      }

      DocumentReference newRoomRef =
          await _firestore.collection('chatRoom').add({
        "participants": [userId, recipientId],
        "lastMessage": "",
        'type': '',
        'status': 0,
        "updated_at": FieldValue.serverTimestamp(),
        "archived_by": [],
        "pinned_by": [],
        "hided_by": [],
      });
      var recipient =
          await _firestore.collection("users").doc(recipientId).get();

      ChatRoomModel newRoom = ChatRoomModel(
        id: newRoomRef.id,
        archived: false,
        pinned: false,
        hided: false,
        recipientId: recipientId,
        recipientName: recipient.data()!['displayName'] ?? '',
        recipientBio: recipient.data()!['bio'] ?? '',
        recipientPhoto: recipient.data()!['profile_picture'] ?? '',
        lastMessage: "",
        type: "",
        status: 0,
        unread: 0,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _roomDatabase.insertChatRoom(newRoom);

      return {"status": true, "data": newRoom};
    } catch (e) {
      return {"status": false, "error": e.toString()};
    }
  }

  Future<void> deleteChatRooms(List<String> chatRoomIds) async {
    try {
      if (chatRoomIds.isEmpty) return;

      if (_isOnline) {
        WriteBatch batch = _firestore.batch();
        for (String id in chatRoomIds) {
          batch.delete(_firestore.collection('chatRoom').doc(id));
        }
        await batch.commit();
      }

      for (String id in chatRoomIds) {
        await _roomDatabase.deleteRoom(id);
      }

      // fetchChatRooms(chatController.userId);
      // ignore: avoid_print
      print("ChatRoom dengan ID ${chatRoomIds.join(", ")} berhasil dihapus.");
    } catch (e) {
      // ignore: avoid_print
      print("Error menghapus chatRoom: $e");
    }
  }

  void searchRoom(String query) {
    print("Mencari dengan query: $query");

    if (query.isEmpty) {
      print("Mengembalikan data asli: $_originalRooms");
      _chatRoomsController.add(_originalRooms);
      return;
    }

    List<ChatRoomModel> filteredRooms = _originalRooms
        .where((room) =>
            room.recipientName.toLowerCase().contains(query.toLowerCase()))
        .toList();

    print("Data sebelum update stream: $_originalRooms");
    print("Data hasil filter: $filteredRooms");

    if (!_chatRoomsController.isClosed) {
      _chatRoomsController.add(filteredRooms);
    }
  }

  void dispose() {
    _chatRoomsController.close();
    _connectivitySubscription?.cancel();
    _firestoreSubscription?.cancel();
  }
}
