import 'package:cloud_firestore/cloud_firestore.dart';

class FriendshipModel {
  final String requesterId;
  final String receiverId;
  final String status; // Can be 'pending', 'accepted', or 'rejected'
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  FriendshipModel({
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    return FriendshipModel(
      requesterId: json['requesterId'] as String,
      receiverId: json['receiverId'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] as Timestamp,
      updatedAt: json['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requesterId': requesterId,
      'receiverId': receiverId,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
