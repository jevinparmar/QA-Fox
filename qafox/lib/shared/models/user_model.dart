import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/extensions/string_extensions.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String username;
  final String? designation;
  final String? bio;
  final String? photoUrl;
  final String? phoneNumber;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final String? fcmToken;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.username,
    this.designation,
    this.bio,
    this.photoUrl,
    this.phoneNumber,
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
    this.fcmToken,
  });

  String get initials => fullName.initials;

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return UserModel(
      id: id,
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      username: map['username'] as String? ?? '',
      designation: map['designation'] as String?,
      bio: map['bio'] as String?,
      photoUrl: map['photoUrl'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      isOnline: map['isOnline'] as bool? ?? false,
      lastSeen: parseDate(map['lastSeen']),
      createdAt: parseDate(map['createdAt']),
      fcmToken: map['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'username': username,
      'designation': designation,
      'bio': bio,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null
          ? Timestamp.fromDate(lastSeen!)
          : FieldValue.serverTimestamp(),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'fcmToken': fcmToken,
    };
  }

  UserModel copyWith({
    String? email,
    String? fullName,
    String? username,
    String? designation,
    String? bio,
    String? photoUrl,
    String? phoneNumber,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    String? fcmToken,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      designation: designation ?? this.designation,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
