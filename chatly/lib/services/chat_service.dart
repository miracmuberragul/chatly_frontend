import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart'; // We will create this model next

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get a real-time stream of all chats a user is a member of.
  ///
  /// This listens for changes in the 'chats' collection where the user's ID
  /// is present in the 'members' array. It's ordered by the last message
  /// timestamp to show the most recent chats first.
  Stream<List<ChatModel>> getChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('members', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatModel.fromFirestore(doc);
          }).toList();
        });
  }
}
