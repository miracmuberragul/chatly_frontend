import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? profilePhotoUrl;
  final Timestamp? lastSeen;
  final List<String>? friends;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.profilePhotoUrl,
    this.lastSeen,
    this.friends,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      lastSeen: json['lastSeen'] as Timestamp?,
      friends: (json['friends'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'uid': uid,
      'username': username,
      'email': email,
      'profilePhotoUrl': profilePhotoUrl,
      'lastSeen': lastSeen,
      'friends': friends,
    };
    return data;
  }
}
