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
  final StreamController<List<MessageModel>> _messagesController = StreamController.broadcast();
  StreamSubscription? _connectivitySubscription;
  StreamSubscription<QuerySnapshot>? _firestoreSubscription;
  bool _isOnline = true;
  bool _isFetching = false;
  List<MessageModel> _messages = [];

  Stream<List<MessageModel>> get messagesStream => _messagesController.stream;

  MessageService(String chatRoomId, String userId) {
    _monitorConnectivity(chatRoomId, userId);
  }

  /// Monitor connectivity and sync messages when online.
  void _monitorConnectivity(String chatRoomId, String userId) {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) async {
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

  /// Fetch messages for a chat room, using Firestore if online, SQLite if offline.
  void fetchMessages(String chatRoomId, String userId) {
    if (_isOnline) {
      _fetchFromFirestore(chatRoomId, userId);
    } else {
      _fetchFromSQLite(chatRoomId);
    }
  }

  /// Fetch messages from Firestore and update local database.
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
            localImagePath = await MediaStorage.downloadMedia(d['message'], doc.id);
          }
          MessageModel? localMessage = await _messageDatabase.getMessageById(doc.id);
          if (localMessage != null) {
            localThumbnailPath = localMessage.thumbnailPath;
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
          await _messageDatabase.upsertMessage(message);
        }
      }
      _messages = newMessages.reversed.toList();
      _messagesController.add(List.from(_messages));
      _isFetching = false;
    });
  }

  /// Fetch messages from local SQLite database.
  void _fetchFromSQLite(String chatRoomId) async {
    List<MessageModel> messages = await _messageDatabase.getMessages(chatRoomId);
    _messages = messages;
    _messagesController.add(messages);
  }

  /// Mark a message as read in Firestore and local database.
  Future<void> markMessageAsRead(String chatRoomId, String messageId) async {
    await _firestore
        .collection('chatRoom')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .update({'status': 3});
    await _messageDatabase.updateMessageStatus(messageId, 3);
  }

  /// Sync pending (unsent) messages to Firestore.
  Future<void> _syncPendingMessages(String chatRoomId) async {
    List<MessageModel> pendingMessages = await _messageDatabase.getPendingMessages(chatRoomId);
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
        await _messageDatabase.upsertMessage(
          message.copyWith(id: ref.id, status: 1),
        );
      } catch (e) {
        // Optionally log error
      }
    }
  }

  /// Send a message (text, image, etc.) to Firestore and local database.
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
        await _messageDatabase.upsertMessage(newMessage);
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
        await _messageDatabase.upsertMessage(
          newMessage.copyWith(id: ref.id, status: 1),
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Add a local message to the stream (for optimistic UI updates).
  void addLocalMessage(MessageModel message) {
    _messages.add(message);
    _messagesController.add(List.from(_messages));
  }

  /// Update upload progress for a message.
  void updateUploadProgress(String messageId, double progress) {
    int index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      _messages[index].uploadProgress = progress;
      _messagesController.add(List.from(_messages));
    }
  }

  /// Delete messages for the current user ("delete for me").
  Future<bool> deleteChat(String roomId, List<String> messageIds, String userId) async {
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
            await _deleteFileIfNeeded(data);
            batch.delete(_firestore
                .collection('chatRoom')
                .doc(roomId)
                .collection('messages')
                .doc(id));
          }
        }
        await batch.commit();
        await _updateChatRoomLastMessage(roomId, userId);
      }
      for (String id in messageIds) {
        await _messageDatabase.deleteMessage(id);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a message for everyone (immediate delete from Firestore and storage).
  Future<bool> deleteMessageForEveryone(String roomId, String messageId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('chatRoom')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .get();
      if (!doc.exists) return false;
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;
      await _deleteFileIfNeeded(data);
      await _firestore
          .collection('chatRoom')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .delete();
      await _messageDatabase.deleteMessage(messageId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Helper: Delete file from Firebase Storage if message is image, video, or file.
  Future<void> _deleteFileIfNeeded(Map<String, dynamic> data) async {
    if (data.containsKey('type') &&
        (data['type'] == "image" || data['type'] == "video" || data['type'] == "file")) {
      try {
        String fileUrl = data['message'];
        Reference storageRef = FirebaseStorage.instance.refFromURL(fileUrl);
        await storageRef.delete();
      } catch (e) {
        // Optionally log error
      }
    }
  }

  /// Helper: Update chat room's last message after deletion.
  Future<void> _updateChatRoomLastMessage(String roomId, String userId) async {
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
    } else {
      var lastMessageData =
          isDeletedDoc.firstWhere((e) => !e['deleted_by'].contains(userId));
      await _firestore.collection('chatRoom').doc(roomId).update({
        'lastMessage': lastMessageData['message'] ?? '',
        'type': lastMessageData['type'] ?? 'text',
        'status': lastMessageData['status'] ?? 1,
        'updated_at': lastMessageData['timestamp'] ?? FieldValue.serverTimestamp(),
      });
    }
  }

  /// Dispose resources.
  void dispose() {
    _firestoreSubscription?.cancel();
    _messagesController.close();
    _connectivitySubscription?.cancel();
  }
}
