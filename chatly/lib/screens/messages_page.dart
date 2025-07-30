import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late io.Socket _socket;

  // Local state to hold user data, allowing updates from sockets
  final Map<String, UserModel> _usersData = {};

  @override
  void initState() {
    super.initState();
    _connectToSocket();
  }

  void _connectToSocket() {
    try {
      _socket = io.io(
        'http://192.168.1.110:3000',
        io.OptionBuilder().setTransports(['websocket']).build(),
      );

      _socket.onConnect((_) {
        if (mounted) {
          _auth.currentUser?.uid;
          _socket.emit('user_online', {'userId': _auth.currentUser!.uid});
        }
      });

      // Listen for real-time status updates
      _socket.on('user_status_changed', (data) {
        if (mounted && data is Map<String, dynamic>) {
          final userId = data['userId'];
          final isOnline = data['isOnline'];
          if (_usersData.containsKey(userId)) {
            setState(() {
              _usersData[userId]!.isOnline = isOnline;
            });
          }
        }
      });

      _socket.onDisconnect((_) {});
    } catch (e) {
      log('Socket connection error: $e');
    }
  }

  @override
  void dispose() {
    _socket.dispose();
    super.dispose();
  }

  // Combined stream to get chats and then fetch all user data at once
  Stream<List<Map<String, dynamic>>> _getChatsWithUserDetails() {
    return _chatService.getChatsStream(_auth.currentUser!.uid).asyncMap((
      chats,
    ) async {
      if (chats.isEmpty) return [];

      // Get unique IDs of all other users in the chats
      final otherUserIds = chats
          .map(
            (chat) =>
                chat.members.firstWhere((id) => id != _auth.currentUser!.uid),
          )
          .toSet()
          .toList();

      // Fetch all user data in a single query
      if (otherUserIds.isNotEmpty) {
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: otherUserIds)
            .get();

        // Update local user data cache
        for (var doc in usersSnapshot.docs) {
          final user = UserModel.fromJson(doc.data());
          _usersData[user.uid] = user;
        }
      }

      // Combine chat with user data
      return chats.map((chat) {
        final otherUserId = chat.members.firstWhere(
          (id) => id != _auth.currentUser!.uid,
        );
        return {'chat': chat, 'user': _usersData[otherUserId]};
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.all(10.0),
          child: Text(
            'Messages',
            style: TextStyle(
              color: Color(0xFF2F4156),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2F4156),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getChatsWithUserDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No active chats. Start a new conversation!'),
              );
            }

            final chatItems = snapshot.data!;

            return ListView.builder(
              itemCount: chatItems.length,
              itemBuilder: (context, index) {
                final item = chatItems[index];
                final ChatModel chat = item['chat'];
                final UserModel? user = item['user'];

                if (user == null) {
                  return const ListTile(title: Text('User not found'));
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.profilePhotoUrl != null
                        ? NetworkImage(user.profilePhotoUrl!)
                        : null,
                    backgroundColor: const Color(0xFF2F4156),
                    child: user.profilePhotoUrl == null
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Text(user.username),
                  subtitle: Text(
                    chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: user.isOnline
                      ? const Icon(Icons.circle, color: Colors.green, size: 12)
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: chat.id,
                          otherUserId: user.uid,
                          username: user.username,
                          isOnline: user.isOnline,
                          profilePhotoUrl: user.profilePhotoUrl,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
