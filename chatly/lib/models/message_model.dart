import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String? text; // Made nullable for image messages
  final Timestamp timestamp;
  final List<String> seenBy;
  final String type; // 'text' or 'image'
  final String? imageUrl; // URL for the image

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.text,
    required this.timestamp,
    required this.seenBy,
    required this.type,
    this.imageUrl,
  });

  // Factory constructor to create a MessageModel from a Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'], // Can be null
      timestamp: data['timestamp'] ?? Timestamp.now(),
      seenBy: List<String>.from(data['seenBy'] ?? []),
      type: data['type'] ?? 'text', // Default to 'text'
      imageUrl: data['imageUrl'], // Can be null
    );
  }

  // Factory constructor to create a MessageModel from a WebSocket event
  factory MessageModel.fromWebSocket(Map<String, dynamic> data) {
    return MessageModel(
      id: '', // WebSocket messages don't have a Firestore ID initially
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'],
      // Parse the ISO 8601 string timestamp from the event
      timestamp: Timestamp.fromDate(DateTime.parse(data['timestamp'])),
      seenBy: [], // Initially, a new message from socket hasn't been seen by anyone
      type: data['type'] ?? 'text', // Default to 'text'
      imageUrl: data['imageUrl'],
    );
  }

  // Method to convert a MessageModel instance to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'seenBy': seenBy,
      'type': type,
      'imageUrl': imageUrl,
    };
  }
}
