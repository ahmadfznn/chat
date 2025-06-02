import 'dart:async';
import 'package:chat/models/message_model.dart';
import 'package:chat/services/local_database.dart';
import 'package:chat/services/media_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDatabase _messageDatabase = LocalDatabase.instance;

  final StreamController<List<MessageModel>> _messagesController =
      StreamController.broadcast();

  StreamSubscription? _connectivitySubscription;
  StreamSubscription<QuerySnapshot>? _firestoreSubscription;

  bool _isOnline = true;
  bool _isFetching = false;

  List<MessageModel> _messages = [];

  Stream<List<MessageModel>> get messagesStream => _messagesController.stream;

  MessageService(String chatRoomId, String userId) {
    _monitorConnectivity(chatRoomId, userId);
  }

  void _monitorConnectivity(String chatRoomId, String userId) {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) async {
      bool isNowOnline = (result != ConnectivityResult.none);
      if (isNowOnline != _isOnline) {
        _isOnline = isNowOnline;
        if (_isOnline) {
          await _syncPendingMessages(chatRoomId);
        }
        fetchMessages(chatRoomId, userId);
      }
    });
  }

  void fetchMessages(String chatRoomId, String userId) {
    if (_isOnline) {
      _fetchFromFirestore(chatRoomId, userId);
    } else {
      _fetchFromSQLite(chatRoomId, userId);
    }
  }

  // void _fetchFromFirestore(String roomId, bool isInitialLoad) {
  //   if (_isFetching || (!_hasMore && !isInitialLoad)) return;
  //   _isFetching = true;

  //   Query query = _firestore
  //       .collection('chatRoom')
  //       .doc(roomId)
  //       .collection('messages')
  //       .orderBy('timestamp', descending: true)
  //       .limit(20);

  //   if (!isInitialLoad && _lastDocument != null) {
  //     query = query.startAfterDocument(_lastDocument!);
  //   }

  //   _firestoreSubscription?.cancel();

  //   _firestoreSubscription = query.snapshots().listen((snapshot) async {
  //     if (snapshot.docs.isEmpty) {
  //       _hasMore = false;
  //       _isFetching = false;
  //       if (!_messagesController.isClosed) {
  //         _messagesController.add([]);
  //       }
  //       return;
  //     }

  //     _lastDocument = snapshot.docs.last;

  //     List<MessageModel> newMessages = [];
  //     for (var doc in snapshot.docs) {
  //       var d = doc.data() as Map<String, dynamic>;
  //       String? localImagePath;
  //       if (d['type'] != 'text') {
  //         localImagePath =
  //             await MediaStorage.downloadMedia(d['message'], doc.id);
  //       }

  //       MessageModel message = MessageModel(
  //         id: doc.id,
  //         roomId: roomId,
  //         senderId: d['senderId'],
  //         receiverId: d['receiverId'],
  //         message: d['message'],
  //         type: d['type'],
  //         localPath: localImagePath,
  //         timestamp: (d['timestamp'] as Timestamp).toDate(),
  //         status: d['status'] ?? 0,
  //       );

  //       if (message.status == 1) {
  //         await _firestore
  //             .collection('chatRoom')
  //             .doc(roomId)
  //             .collection('messages')
  //             .doc(message.id)
  //             .update({'status': 2});
  //         message.status = 2;
  //       }

  //       newMessages.add(message);
  //       await _messageDatabase.insertOrUpdateMessage(message);
  //     }

  //     newMessages = newMessages.reversed.toList();

  //     if (isInitialLoad) {
  //       _messages = newMessages;
  //     } else {
  //       _messages.insertAll(0, newMessages);
  //     }

  //     if (!_messagesController.isClosed) {
  //       _messagesController.add(List.from(_messages));
  //     }

  //     _isFetching = false;
  //   });
  // }

  void _fetchFromFirestore(String roomId, String userId) {
    if (_isFetching) return;
    _isFetching = true;

    _firestoreSubscription?.cancel();

    _firestoreSubscription = _firestore
        .collection('chatRoom')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isEmpty) {
        _messagesController.add([]);
        _isFetching = false;
        return;
      }

      List<MessageModel> newMessages = [];

      for (var doc in snapshot.docs) {
        var d = doc.data();
        List<dynamic> deletedBy = d['deleted_by'] ?? [];

        if (!deletedBy.contains(userId)) {
          String? localImagePath;
          String? localThumbnailPath;

          if (d['type'] != 'text') {
            localImagePath =
                await MediaStorage.downloadMedia(d['message'], doc.id);
          }

          MessageModel? localMessage =
              await _messageDatabase.getMessageById(doc.id);
          if (localMessage != null) {
            localThumbnailPath = localMessage.thumbnailPath;
            print(
                "Thumbnail 7 : ${localMessage.id} - ${localMessage.thumbnailPath}");
          }

          int currentStatus = d['status'] ?? 0;

          if (d['senderId'] != userId && currentStatus == 2) {
            await _firestore
                .collection('chatRoom')
                .doc(roomId)
                .collection('messages')
                .doc(doc.id)
                .update({'status': 3});
            currentStatus = 3;
          }
          // print("Thumbnail 8 : ${localMessage!.thumbnailPath}");

          MessageModel message = MessageModel(
            id: doc.id,
            roomId: roomId,
            senderId: d['senderId'],
            receiverId: d['receiverId'],
            message: d['message'],
            type: d['type'],
            thumbnailPath: localThumbnailPath,
            localPath: localImagePath,
            timestamp: d['timestamp'] is Timestamp
                ? (d['timestamp'] as Timestamp).toDate()
                : DateTime.now(),
            status: currentStatus,
          );

          newMessages.add(message);
          await _messageDatabase.insertOrUpdateMessage(message);
          print("Thumbnail 9 : ${message.thumbnailPath}");
        }
      }

      _messages = newMessages.reversed.toList();
      _messagesController.add(List.from(_messages));

      _isFetching = false;
    });
  }

  Future<void> markMessageAsRead(String chatRoomId, String messageId) async {
    await _firestore
        .collection('chatRoom')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .update({'status': 3});

    await _messageDatabase.updateMessageStatus(messageId, 3);
  }

  void _fetchFromSQLite(String chatRoomId, String userId) async {
    List<MessageModel> messages =
        await _messageDatabase.getMessages(chatRoomId);
    _messages = messages;
    _messagesController.add(messages);
  }

  Future<void> _syncPendingMessages(String chatRoomId) async {
    List<MessageModel> pendingMessages =
        await _messageDatabase.getPendingMessages(chatRoomId);
    for (var message in pendingMessages) {
      try {
        DocumentReference ref = await _firestore
            .collection('chatRoom')
            .doc(chatRoomId)
            .collection('messages')
            .add({
          'senderId': message.senderId,
          'receiverId': message.receiverId,
          'message': message.message,
          'type': message.type,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 1,
        });

        await _messageDatabase.updateMessage(
            null,
            MessageModel(
              id: ref.id,
              roomId: message.roomId,
              senderId: message.senderId,
              receiverId: message.receiverId,
              message: message.message,
              type: message.type,
              localPath: message.localPath,
              timestamp: message.timestamp,
              status: 1,
            ));
      } catch (e) {
        // ignore: avoid_print
        print("Gagal mengirim pesan offline: $e");
      }
    }
  }

  Future<bool> sendMessage(Map<String, dynamic> message) async {
    try {
      bool isTextMessage = message['type'] == "text";
      bool isOnline = _isOnline;

      MessageModel newMessage = MessageModel(
        id: "0",
        roomId: message['roomId'],
        senderId: message['userId'],
        receiverId: message['receiverId'],
        message: message['message'],
        type: message['type'],
        localPath: message['localPath'],
        timestamp: DateTime.now(),
        status: isOnline ? 1 : 0,
      );

      if (isTextMessage) {
        await _messageDatabase.insertMessage(newMessage);
        _messages.add(newMessage);
        _messagesController.add(List.from(_messages));
      }

      if (isOnline) {
        DocumentReference ref = await _firestore
            .collection('chatRoom')
            .doc(message['roomId'])
            .collection('messages')
            .add({
          'deleted_by': [],
          'senderId': message['userId'],
          'receiverId': message['receiverId'],
          'message': message['message'],
          'type': message['type'],
          'status': 1,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('chatRoom').doc(message['roomId']).update({
          'lastMessage': isTextMessage ? message['message'] : '',
          'type': message['type'],
          'status': 1,
          'updated_at': FieldValue.serverTimestamp(),
        });

        await _messageDatabase.updateMessage(
          isTextMessage ? "0" : message['id'],
          newMessage.copyWith(id: ref.id, status: 1),
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  void addLocalMessage(MessageModel message) {
    _messages.add(message);
    _messagesController.add(List.from(_messages));
  }

  void updateUploadProgress(String messageId, double progress) {
    int index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      _messages[index].uploadProgress = progress;
      _messagesController.add(List.from(_messages));
    }
  }

  Future<bool> deleteChat(
      String roomId, List<String> messageIds, String userId) async {
    try {
      if (roomId.isEmpty) return false;

      if (_isOnline) {
        WriteBatch batch = _firestore.batch();

        for (String id in messageIds) {
          DocumentSnapshot doc = await _firestore
              .collection('chatRoom')
              .doc(roomId)
              .collection('messages')
              .doc(id)
              .get();

          if (!doc.exists) continue;

          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

          if (data == null) continue;

          List<dynamic> deletedBy = List.from(data['deleted_by'] ?? []);

          if (!deletedBy.contains(userId)) {
            deletedBy.add(userId);
          }

          if (deletedBy.length < 2) {
            batch.update(
                _firestore
                    .collection('chatRoom')
                    .doc(roomId)
                    .collection('messages')
                    .doc(id),
                {'deleted_by': deletedBy});
          } else {
            if (data.containsKey('type') &&
                (data['type'] == "image" ||
                    data['type'] == "video" ||
                    data['type'] == "file")) {
              try {
                String fileUrl = data['message'];
                Reference storageRef =
                    FirebaseStorage.instance.refFromURL(fileUrl);
                await storageRef.delete();
                print(
                    "🔥 File $fileUrl berhasil dihapus dari Firebase Storage");
              } catch (e) {
                print("⚠️ Gagal menghapus file dari Firebase Storage: $e");
              }
            }
            batch.delete(_firestore
                .collection('chatRoom')
                .doc(roomId)
                .collection('messages')
                .doc(id));
          }
        }

        await batch.commit();

        QuerySnapshot remainingMessages = await _firestore
            .collection('chatRoom')
            .doc(roomId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .get();

        var isDeletedDoc = remainingMessages.docs
            .map((e) => e.data() as Map<String, dynamic>)
            .toList();

        var isDeleted = isDeletedDoc.every((e) =>
            (e['deleted_by'] is List) && (e['deleted_by'].contains(userId)));

        if (isDeleted) {
          await _firestore.collection('chatRoom').doc(roomId).update({
            'lastMessage': '',
            'type': 'text',
            'status': 0,
            'updated_at': FieldValue.serverTimestamp(),
          });
          print("✅ Semua pesan dihapus, chatRoom diperbarui.");
        } else {
          var lastMessageData =
              isDeletedDoc.firstWhere((e) => !e['deleted_by'].contains(userId));

          await _firestore.collection('chatRoom').doc(roomId).update({
            'lastMessage': lastMessageData['message'] ?? '',
            'type': lastMessageData['type'] ?? 'text',
            'status': lastMessageData['status'] ?? 1,
            'updated_at':
                lastMessageData['timestamp'] ?? FieldValue.serverTimestamp(),
          });
        }
      }

      for (String id in messageIds) {
        await _messageDatabase.deleteMessage(id);
      }

      print(
          "✅ Chat dengan ID ${messageIds.join(", ")} berhasil dihapus (local).");
      return true;
    } catch (e) {
      print("❌ Error menghapus chat: $e");
      return false;
    }
  }

  void dispose() {
    _firestoreSubscription?.cancel();
    _messagesController.close();
    _connectivitySubscription?.cancel();
  }
}
