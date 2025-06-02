class UserModel {
  final String id;
  final String? name;
  final String username;
  final String? profilePicture;
  final String? phoneNumber;
  final String? bio;
  final String? status;
  final String? gender;
  final String? country;
  final bool isFriend;
  final bool visibility;
  final DateTime lastActivity;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.profilePicture,
    required this.phoneNumber,
    required this.bio,
    required this.status,
    required this.gender,
    required this.country,
    required this.isFriend,
    required this.visibility,
    required this.lastActivity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'profilePicture': profilePicture,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'status': status,
      'gender': gender,
      'country': country,
      'visibility': visibility ? 1 : 0,
      'isFriend': isFriend ? 1 : 0,
      'lastActivity': lastActivity.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      username: map['username'],
      profilePicture: map['profilePicture'],
      phoneNumber: map['phoneNumber'],
      bio: map['bio'],
      status: map['status'],
      gender: map['gender'],
      country: map['country'],
      visibility: (map['visibility'] ?? 0) == 1,
      isFriend: (map['isFriend'] ?? 0) == 1,
      lastActivity: DateTime.parse(map['lastActivity']),
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? profilePicture,
    String? phoneNumber,
    String? bio,
    String? status,
    String? gender,
    String? country,
    bool? isFriend,
    bool? visibility,
    DateTime? lastActivity,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      profilePicture: profilePicture ?? this.profilePicture,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      status: status ?? this.status,
      gender: gender ?? this.gender,
      country: country ?? this.country,
      isFriend: isFriend ?? this.isFriend,
      visibility: visibility ?? this.visibility,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }
}
