import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> members;
  final String lastMessage;
  final Timestamp lastMessageTimestamp;

  Chat({
    required this.id,
    required this.members,
    required this.lastMessage,
    required this.lastMessageTimestamp,
  });

  /// Creates a Chat instance from a Firestore document.
  factory Chat.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      members: List<String>.from(data['members'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTimestamp: data['lastMessageTimestamp'] ?? Timestamp.now(),
    );
  }
}
