import 'package:chat/models/chat_room_model.dart';
import 'package:chat/models/message_model.dart';
import 'package:chat/models/user_model.dart';
import 'package:sqflite/sqflite.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;
  static const String chatTable = "chats";
  static const String userTable = "users";
  static const String chatRoomsTable = "chat_rooms";

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  LocalDatabase._init();

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'chat.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE $chatRoomsTable (
          id TEXT PRIMARY KEY,
          archived BOOL,
          pinned BOOL,
          hided BOOL,
          recipientId TEXT,
          recipientName TEXT,
          recipientPhoto TEXT,
          recipientBio TEXT,
          lastMessage TEXT,
          type TEXT,
          status INTEGER,
          unread INTEGER,
          updatedAt INTEGER
        )
      ''');

        await db.execute('''
        CREATE TABLE $chatTable (
          id TEXT PRIMARY KEY,
          roomId TEXT,
          senderId TEXT,
          receiverId TEXT,
          message TEXT,
          type TEXT,
          localPath TEXT,
          thumbnailPath TEXT,
          timestamp INTEGER,
          status INTEGER,
          uploadProgress DOUBLE,
          FOREIGN KEY (roomId) REFERENCES $chatRoomsTable (id) ON DELETE CASCADE
        )
      ''');

        await db.execute('''
        CREATE TABLE $userTable (
          id TEXT PRIMARY KEY,
          name TEXT,
          username TEXT,
          profilePicture TEXT,
          phoneNumber TEXT,
          bio TEXT,
          status INTEGER,
          gender TEXT,
          country TEXT,
          visibility BOOL,
          isFriend BOOL,
          lastActivity INTEGER
        )
      ''');
      },
    );
  }

  Future<void> insertChatRoom(ChatRoomModel room) async {
    final db = await database;
    await db.insert(
      chatRoomsTable,
      room.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatRoomModel>> getChatRooms() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(chatRoomsTable);
    return maps.map((map) => ChatRoomModel.fromMap(map)).toList();
  }

  Future<ChatRoomModel?> getChatRoomById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query(chatRoomsTable, where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return ChatRoomModel.fromMap(maps.first);
    }
    return null;
  }

  Future<ChatRoomModel?> getChatRoomByRecipient(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db
        .query(chatRoomsTable, where: 'recipientId = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return ChatRoomModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateChatRoom(ChatRoomModel room) async {
    final db = await database;
    await db.update(
      chatRoomsTable,
      room.toMap(),
      where: 'id = ?',
      whereArgs: [room.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteRoom(String id) async {
    final db = await database;
    await db.delete(chatRoomsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteRoomsNotInFirestore(List<String> firestoreIds) async {
    final db = await database;
    await db.delete(
      chatRoomsTable,
      where: "id NOT IN (${List.filled(firestoreIds.length, '?').join(',')})",
      whereArgs: firestoreIds,
    );
  }

  Future<List<ChatRoomModel>> searchChatRoomsByRecipientName(
      String recipientName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      chatRoomsTable,
      where: 'recipientName LIKE ?',
      whereArgs: ['%$recipientName%'],
      orderBy: 'updatedAt DESC',
    );

    return maps.map((map) => ChatRoomModel.fromMap(map)).toList();
  }

  Future<void> insertMessage(MessageModel message) async {
    final db = await database;
    await db.insert(chatTable, message.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateMessage(String? oldId, MessageModel message) async {
    final db = await database;
    await db.update(chatTable, message.toMap(),
        where: 'id = ?',
        whereArgs: [oldId ?? message.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertOrUpdateMessage(MessageModel message) async {
    final db = await database;
    await db.insert(
      chatTable,
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMessageStatus(String messageId, int newStatus) async {
    final db = await database;
    await db.update(
      chatTable,
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<List<MessageModel>> getMessages(String roomId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query(chatTable, where: 'roomId = ?', whereArgs: [roomId]);
    return maps.map((map) => MessageModel.fromMap(map)).toList();
  }

  Future<MessageModel?> getMessageById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query(chatTable, where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return MessageModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> deleteMessage(String id) async {
    final db = await database;
    await db.delete(chatTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MessageModel>> getPendingMessages(String chatRoomId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'roomId = ? AND status = ?',
      whereArgs: [chatRoomId, 0],
    );

    return List.generate(maps.length, (i) {
      return MessageModel.fromMap(maps[i]);
    });
  }

  Future<List<UserModel>> getUsers(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db
        .query(userTable, where: 'username != ?', whereArgs: [username]);
    return maps.map((map) => UserModel.fromMap(map)).toList();
  }

  Future<UserModel?> getUserById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query(userTable, where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> insertUser(UserModel user) async {
    final db = await database;
    await db.insert(userTable, user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateUser(UserModel user) async {
    final db = await database;
    await db.update(userTable, user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.execute("DROP TABLE IF EXISTS $chatTable");
      await txn.execute("DROP TABLE IF EXISTS $chatRoomsTable");
      await txn.execute("DROP TABLE IF EXISTS $userTable");
    });

    await _initDB();
  }

  Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), 'chat.db');
    await deleteDatabase(path);
    _database = null;

    await _initDB();
  }
}
