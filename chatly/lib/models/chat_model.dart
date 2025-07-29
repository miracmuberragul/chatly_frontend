import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> members;
  final String lastMessage;
  final Timestamp lastMessageTimestamp;

  ChatModel({
    required this.id,
    required this.members,
    required this.lastMessage,
    required this.lastMessageTimestamp,
  });

  /// Creates a ChatModel instance from a Firestore document.
  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      members: List<String>.from(data['members'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTimestamp: data['lastMessageTimestamp'] ?? Timestamp.now(),
    );
  }

  /// Converts a ChatModel instance to a map for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'members': members,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp,
    };
  }
}
