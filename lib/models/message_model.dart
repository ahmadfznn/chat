class MessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String receiverId;
  final String message;
  final String type;
  final String? localPath;
  final String? thumbnailPath;
  final DateTime timestamp;
  int status;
  double uploadProgress;

  MessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.type,
    this.localPath,
    this.thumbnailPath,
    required this.timestamp,
    required this.status,
    this.uploadProgress = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'type': type,
      'localPath': localPath,
      'thumbnailPath': thumbnailPath,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status,
      'uploadProgress': uploadProgress,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      roomId: map['roomId'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      message: map['message'],
      type: map['type'],
      localPath: map['localPath'],
      thumbnailPath: map['thumbnailPath'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      status: map['status'],
      uploadProgress: map['uploadProgress'] ?? 0.0,
    );
  }

  MessageModel copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? receiverId,
    String? message,
    String? type,
    String? thumbnailPath,
    String? localPath,
    DateTime? timestamp,
    int? status,
  }) {
    return MessageModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      type: type ?? this.type,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      localPath: localPath ?? this.localPath,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}
