import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final Timestamp timestamp;
  final List<String> seenBy;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.seenBy,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      text: json['text'] as String,
      timestamp: json['timestamp'] as Timestamp,
      seenBy: List<String>.from(json['seenBy'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'seenBy': seenBy,
    };
  }

  // Factory constructor to create a MessageModel from a Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      seenBy: List<String>.from(data['seenBy'] ?? []),
    );
  }

  // Method to convert a MessageModel object to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      // id is not included here because it's the document ID
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'seenBy': seenBy,
    };
  }
}
