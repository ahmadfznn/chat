class ChatRoomModel {
  final String id;
  final bool? archived;
  final bool? hided;
  final bool? pinned;
  final String recipientId;
  final String recipientName;
  final String? recipientPhoto;
  final String? recipientBio;
  final String? lastMessage;
  final String? type;
  final int status;
  final int unread;
  final int updatedAt;

  ChatRoomModel(
      {required this.id,
      this.archived,
      this.hided,
      required this.recipientId,
      required this.recipientName,
      this.recipientPhoto,
      this.recipientBio,
      this.pinned,
      this.lastMessage,
      this.type,
      this.status = -1,
      this.unread = 0,
      required this.updatedAt});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'archived': archived ?? false ? 1 : 0,
      'hided': hided ?? false ? 1 : 0,
      'pinned': pinned ?? false ? 1 : 0,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'recipientPhoto': recipientPhoto,
      'recipientBio': recipientBio,
      'lastMessage': lastMessage,
      'type': type,
      'status': status,
      'unread': unread,
      'updatedAt': updatedAt
    };
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map) {
    return ChatRoomModel(
        id: map['id'],
        archived: (map['archived'] ?? 0) == 1,
        hided: (map['hided'] ?? 0) == 1,
        pinned: (map['pinned'] ?? 0) == 1,
        recipientId: map['recipientId'],
        recipientName: map['recipientName'],
        recipientPhoto: map['recipientPhoto'],
        recipientBio: map['recipientBio'],
        lastMessage: map['lastMessage'],
        type: map['type'],
        status: map['status'] ?? 0,
        unread: map['unread'] ?? 0,
        updatedAt: map['updatedAt']);
  }
}
