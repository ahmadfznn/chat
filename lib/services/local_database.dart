import 'package:chat/models/chat_room_model.dart';
import 'package:chat/models/message_model.dart';
import 'package:chat/models/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;
  static const String chatTable = "chats";
  static const String userTable = "users";
  static const String chatRoomsTable = "chat_rooms";
  static const String notificationSettingsTable = "notification_settings";
  static const String privacySettingsTable = "privacy_settings";
  static const String blockedContactsTable = "blocked_contacts";
  static const String chatSettingsTable = "chat_settings";
  static const String chatPreferencesTable = "chat_preferences";

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  LocalDatabase._init();

  /// Initialize the SQLite database and create tables if they don't exist.
  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'chat.db');
    return openDatabase(
      path,
      version: 2,
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
        await db.execute('''
        CREATE TABLE $notificationSettingsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          settings TEXT
        )
      ''');
        await db.execute('''
        CREATE TABLE $privacySettingsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          settings TEXT
        )
      ''');
        await db.execute('''
        CREATE TABLE $blockedContactsTable (
          id TEXT PRIMARY KEY,
          name TEXT
        )
      ''');
        await db.execute('''
        CREATE TABLE $chatSettingsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          settings TEXT
        )
      ''');
        await db.execute('''
        CREATE TABLE $chatPreferencesTable (
          chatId TEXT PRIMARY KEY,
          preferences TEXT
        )
      ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $notificationSettingsTable (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              settings TEXT
            )
          ''');
        }
        // Add privacy settings and blocked contacts tables if upgrading from older versions
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $privacySettingsTable (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              settings TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $blockedContactsTable (
              id TEXT PRIMARY KEY,
              name TEXT
            )
          ''');
        }
        // Add chat settings table if upgrading from older versions
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $chatSettingsTable (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              settings TEXT
            )
          ''');
        }
        // Add chat preferences table if upgrading from older versions
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $chatPreferencesTable (
              chatId TEXT PRIMARY KEY,
              preferences TEXT
            )
          ''');
        }
      },
    );
  }

  /// Insert or update a chat room.
  Future<void> upsertChatRoom(ChatRoomModel room) async {
    final db = await database;
    await db.insert(
      chatRoomsTable,
      room.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all chat rooms.
  Future<List<ChatRoomModel>> getChatRooms() async {
    final db = await database;
    final maps = await db.query(chatRoomsTable);
    return maps.map((map) => ChatRoomModel.fromMap(map)).toList();
  }

  /// Get a chat room by its ID.
  Future<ChatRoomModel?> getChatRoomById(String id) async {
    final db = await database;
    final maps =
        await db.query(chatRoomsTable, where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? ChatRoomModel.fromMap(maps.first) : null;
  }

  /// Get a chat room by recipient ID.
  Future<ChatRoomModel?> getChatRoomByRecipient(String id) async {
    final db = await database;
    final maps = await db
        .query(chatRoomsTable, where: 'recipientId = ?', whereArgs: [id]);
    return maps.isNotEmpty ? ChatRoomModel.fromMap(maps.first) : null;
  }

  /// Update a chat room.
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

  /// Delete a chat room by ID.
  Future<void> deleteRoom(String id) async {
    final db = await database;
    await db.delete(chatRoomsTable, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete chat rooms not present in Firestore.
  Future<void> deleteRoomsNotInFirestore(List<String> firestoreIds) async {
    final db = await database;
    if (firestoreIds.isEmpty) return;
    await db.delete(
      chatRoomsTable,
      where: "id NOT IN (${List.filled(firestoreIds.length, '?').join(',')})",
      whereArgs: firestoreIds,
    );
  }

  /// Search chat rooms by recipient name.
  Future<List<ChatRoomModel>> searchChatRoomsByRecipientName(
      String recipientName) async {
    final db = await database;
    final maps = await db.query(
      chatRoomsTable,
      where: 'recipientName LIKE ?',
      whereArgs: ['%$recipientName%'],
      orderBy: 'updatedAt DESC',
    );
    return maps.map((map) => ChatRoomModel.fromMap(map)).toList();
  }

  /// Insert or update a message.
  Future<void> upsertMessage(MessageModel message) async {
    final db = await database;
    await db.insert(
      chatTable,
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update a message's status.
  Future<void> updateMessageStatus(String messageId, int newStatus) async {
    final db = await database;
    await db.update(
      chatTable,
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Get all messages for a chat room.
  Future<List<MessageModel>> getMessages(String roomId) async {
    final db = await database;
    final maps =
        await db.query(chatTable, where: 'roomId = ?', whereArgs: [roomId]);
    return maps.map((map) => MessageModel.fromMap(map)).toList();
  }

  /// Get a message by its ID.
  Future<MessageModel?> getMessageById(String id) async {
    final db = await database;
    final maps = await db.query(chatTable, where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? MessageModel.fromMap(maps.first) : null;
  }

  /// Delete a message by its ID.
  Future<void> deleteMessage(String id) async {
    final db = await database;
    await db.delete(chatTable, where: 'id = ?', whereArgs: [id]);
  }

  /// Get all pending (unsent) messages for a chat room.
  Future<List<MessageModel>> getPendingMessages(String chatRoomId) async {
    final db = await database;
    final maps = await db.query(
      chatTable,
      where: 'roomId = ? AND status = ?',
      whereArgs: [chatRoomId, 0],
    );
    return maps.map((map) => MessageModel.fromMap(map)).toList();
  }

  /// Get all users except the given username.
  Future<List<UserModel>> getUsers(String username) async {
    final db = await database;
    final maps = await db
        .query(userTable, where: 'username != ?', whereArgs: [username]);
    return maps.map((map) => UserModel.fromMap(map)).toList();
  }

  /// Get a user by their ID.
  Future<UserModel?> getUserById(String id) async {
    final db = await database;
    final maps = await db.query(userTable, where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? UserModel.fromMap(maps.first) : null;
  }

  /// Insert or update a user.
  Future<void> upsertUser(UserModel user) async {
    final db = await database;
    await db.insert(userTable, user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Update a user.
  Future<void> updateUser(UserModel user) async {
    final db = await database;
    await db.update(userTable, user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Save or update notification settings (as JSON string).
  Future<void> upsertNotificationSettings(String settingsJson) async {
    final db = await database;
    // Only one row, always id=1
    await db.insert(
      notificationSettingsTable,
      {'id': 1, 'settings': settingsJson},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get notification settings (returns JSON string or null).
  Future<String?> getNotificationSettings() async {
    final db = await database;
    final maps = await db.query(notificationSettingsTable, where: 'id = ?', whereArgs: [1]);
    if (maps.isNotEmpty) {
      return maps.first['settings'] as String;
    }
    return null;
  }

  /// Save or update privacy settings (as JSON string).
  Future<void> upsertPrivacySettings(String settingsJson) async {
    final db = await database;
    await db.insert(
      privacySettingsTable,
      {'id': 1, 'settings': settingsJson},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get privacy settings (returns JSON string or null).
  Future<String?> getPrivacySettings() async {
    final db = await database;
    final maps = await db.query(privacySettingsTable, where: 'id = ?', whereArgs: [1]);
    if (maps.isNotEmpty) {
      return maps.first['settings'] as String;
    }
    return null;
  }

  /// Block a contact.
  Future<void> blockContact(String id, String name) async {
    final db = await database;
    await db.insert(
      blockedContactsTable,
      {'id': id, 'name': name},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Unblock a contact.
  Future<void> unblockContact(String id) async {
    final db = await database;
    await db.delete(blockedContactsTable, where: 'id = ?', whereArgs: [id]);
  }

  /// Get all blocked contacts.
  Future<List<Map<String, dynamic>>> getBlockedContacts() async {
    final db = await database;
    final maps = await db.query(blockedContactsTable);
    return maps;
  }

  /// Save or update chat settings (as JSON string).
  Future<void> upsertChatSettings(String settingsJson) async {
    final db = await database;
    await db.insert(
      chatSettingsTable,
      {'id': 1, 'settings': settingsJson},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get chat settings (returns JSON string or null).
  Future<String?> getChatSettings() async {
    final db = await database;
    final maps = await db.query(chatSettingsTable, where: 'id = ?', whereArgs: [1]);
    if (maps.isNotEmpty) {
      return maps.first['settings'] as String;
    }
    return null;
  }

  /// Save or update chat preferences for a specific chat (as JSON string).
  Future<void> upsertChatPreferences(String chatId, String preferencesJson) async {
    final db = await database;
    await db.insert(
      chatPreferencesTable,
      {'chatId': chatId, 'preferences': preferencesJson},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get chat preferences for a specific chat (returns JSON string or null).
  Future<String?> getChatPreferences(String chatId) async {
    final db = await database;
    final maps = await db.query(chatPreferencesTable, where: 'chatId = ?', whereArgs: [chatId]);
    if (maps.isNotEmpty) {
      return maps.first['preferences'] as String;
    }
    return null;
  }

  /// Clear all tables in the database.
  Future<void> clearDatabase() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.execute("DROP TABLE IF EXISTS $chatTable");
      await txn.execute("DROP TABLE IF EXISTS $chatRoomsTable");
      await txn.execute("DROP TABLE IF EXISTS $userTable");
      await txn.execute("DROP TABLE IF EXISTS $notificationSettingsTable");
      await txn.execute("DROP TABLE IF EXISTS $privacySettingsTable");
      await txn.execute("DROP TABLE IF EXISTS $blockedContactsTable");
      await txn.execute("DROP TABLE IF EXISTS $chatSettingsTable");
      await txn.execute("DROP TABLE IF EXISTS $chatPreferencesTable");
    });
    await _initDB();
  }

  /// Reset the database by deleting and recreating it.
  Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), 'chat.db');
    await deleteDatabase(path);
    _database = null;
    await _initDB();
  }
}
