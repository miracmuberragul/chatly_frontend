// lib/services/message_service.dart

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
    required String otherUserId,
    String? text,
    String? imageUrl,
    required String type,
  }) async {
    if ((type == 'text' && (text == null || text.trim().isEmpty)) ||
        (type == 'image' && (imageUrl == null || imageUrl.isEmpty))) {
      return;
    }

    try {
      final messagesCollection = _chatsCollection
          .doc(chatId)
          .collection('messages');
      final newMessage = MessageModel(
        id: messagesCollection.doc().id,
        chatId: chatId,
        senderId: senderId,
        text: text,
        imageUrl: imageUrl,
        type: type,
        timestamp: Timestamp.now(),
        seenBy: [senderId],
      );

      await _firestore.runTransaction((transaction) async {
        final newMessageRef = messagesCollection.doc(newMessage.id);
        final chatDocRef = _chatsCollection.doc(chatId);

        // 1. Set the new message in the subcollection
        transaction.set(newMessageRef, newMessage.toFirestore());

        // 2. Update the parent chat document with last message info
        transaction.set(chatDocRef, {
          'members': [senderId, otherUserId],
          'lastMessage': type == 'image'
              ? 'Photo'
              : newMessage
                    .text, // "Photo" metnini isterseniz çeviri anahtarı yapabilirsiniz.
          'lastMessageTimestamp': newMessage.timestamp,
          // *** EKLENEN SATIR ***
          'lastMessageType':
              type, // Mesajın tipini ('text' veya 'image') kaydet.
          // *** EKLENEN SATIR SONU ***
        }, SetOptions(merge: true));
      });
    } catch (e) {
      log('Error sending message: $e');
      rethrow;
    }
  }

  // ... (getMessagesStream ve diğer metotlar aynı kalır) ...

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
