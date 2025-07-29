import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get a reference to the chats collection
  CollectionReference get _chatsCollection => _firestore.collection('chats');

  /// Send a new message to a specific chat
    Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String otherUserId, // Required to create the chat document correctly
    required String text,
  }) async {
    if (text.trim().isEmpty) return; // Do not send empty messages

    try {
      // Get a reference to the 'messages' subcollection for the given chat
      final messagesCollection = _chatsCollection
          .doc(chatId)
          .collection('messages');

      // Create a new message object
      final newMessage = MessageModel(
        id: messagesCollection.doc().id, // Firestore will generate the ID
        chatId: chatId,
        senderId: senderId,
        text: text,
        timestamp: Timestamp.now(),
        seenBy: [senderId], // Initially, only the sender has 'seen' the message
      );

      // Use a transaction to ensure both operations (adding a message and updating the chat doc) succeed or fail together.
      await _firestore
          .runTransaction((transaction) async {
            // 1. Get a reference to the new message document.
            final newMessageRef = messagesCollection.doc(newMessage.id);

            // 2. Get a reference to the parent chat document.
            final chatDocRef = _chatsCollection.doc(chatId);

            // 3. Set the new message in the subcollection.
            transaction.set(newMessageRef, newMessage.toFirestore());

            // 4. Update the parent chat document with the last message info.
                        // 4. Create or update the parent chat document with the last message info and members.
            transaction.set(
              chatDocRef,
              {
                'members': [senderId, otherUserId],
                'lastMessage': newMessage.text,
                'lastMessageTimestamp': newMessage.timestamp,
              },
              SetOptions(merge: true), // Use merge to avoid overwriting existing fields
            );
          })
          .catchError((error) {
            log('Error sending message and updating chat: $error');
            throw error;
          });
    } catch (e) {
      log('Error sending message: $e');
      // Optionally, re-throw or handle the error as needed
      rethrow;
    }
  }

  /// Get a real-time stream of messages for a specific chat
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _chatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // Order by newest first
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Fetch a paginated list of older messages.
  Future<List<MessageModel>> getMessagesPaginated(
    String chatId, {
    required DocumentSnapshot? lastVisible,
    int limit = 20,
  }) async {
    Query query = _chatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (lastVisible != null) {
      query = query.startAfterDocument(lastVisible);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
  }

  /// Mark a specific message as seen by the current user.
  Future<void> markMessageAsSeen({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'seenBy': FieldValue.arrayUnion([userId]),
          });
    } catch (e) {
      log('Error marking message as seen: $e');
      // Handle error as needed
    }
  }
}
