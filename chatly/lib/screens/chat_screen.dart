import 'package:chatly/models/message_model.dart';
import 'package:chatly/services/message_service.dart';
import 'package:chatly/services/storage_service.dart'; // Import StorageService
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:chatly/services/socket_service.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String username;
  final bool isOnline;
  final String profilePhotoUrl;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.username,
    required this.isOnline,
    required this.profilePhotoUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String _formatLastSeen(Timestamp? lastSeen) {
    if (lastSeen == null) return 'offline';
    final now = DateTime.now();
    final lastSeenDateTime = lastSeen.toDate();
    final difference = now.difference(lastSeenDateTime);

    if (difference.inMinutes < 1) {
      return 'last seen just now';
    } else if (difference.inHours < 1) {
      return 'last seen ${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return 'last seen at ${DateFormat.Hm().format(lastSeenDateTime)}';
    } else {
      return 'last seen on ${DateFormat.yMd().format(lastSeenDateTime)}';
    }
  }

  final SocketService _socketService = SocketService();
  bool _isOtherUserTyping = false;
  StreamSubscription? _socketSubscription;
  Timer? _typingTimer;

  final TextEditingController _controller = TextEditingController();
  final MessageService _messageService = MessageService();
  final StorageService _storageService =
      StorageService(); // Add StorageService instance
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late final String _chatId;

  @override
  void initState() {
    super.initState();
    List<String> ids = [_currentUserId, widget.otherUserId];
    ids.sort();
    _chatId = ids.join('_');

    _markMessagesAsSeen();

    _socketSubscription = _socketService.events.listen((event) {
      if (event['type'] == 'typing' &&
          event['payload']['chatId'] == _chatId &&
          event['payload']['userId'] != _currentUserId) {
        if (mounted) {
          setState(() {
            _isOtherUserTyping = true;
          });
        }
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isOtherUserTyping = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _typingTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTyping() {
    _socketService.sendEvent('typing', {
      'chatId': _chatId,
      'userId': _currentUserId,
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _messageService.sendMessage(
      chatId: _chatId,
      senderId: _currentUserId,
      otherUserId: widget.otherUserId,
      text: text,
      type: 'text', // Specify message type as text
    );
    _controller.clear();
  }

  void _markMessagesAsSeen() {
    // Listen to the stream of messages, take the first list that comes through,
    // and mark any unread messages as seen.
    _messageService.getMessagesStream(_chatId).first.then((messages) {
      for (final message in messages) {
        if (message.senderId != _currentUserId &&
            !message.seenBy.contains(_currentUserId)) {
          _messageService.markMessageAsSeen(
            chatId: _chatId,
            messageId: message.id,
            userId: _currentUserId,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color myColor = Color(0xFF567C8D);

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: myColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.otherUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(); // Loading state
            }
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final isOnline = userData['isOnline'] ?? false;
            final lastSeen = userData['lastSeen'] as Timestamp?;

            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: (widget.profilePhotoUrl.startsWith('http'))
                      ? NetworkImage(widget.profilePhotoUrl)
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: (widget.profilePhotoUrl.startsWith('http'))
                      ? null
                      : const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.username,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _isOtherUserTyping
                          ? 'typing...'
                          : isOnline
                          ? 'online'
                          : _formatLastSeen(lastSeen),
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: _isOtherUserTyping
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _messageService.getMessagesStream(_chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Say hi!'));
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true, // To show latest messages at the bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    print('Building message: type=${message.type}, url=${message.imageUrl}');
                    final bool isMe = message.senderId == _currentUserId;
                    final bool seen = message.seenBy.length > 1;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isMe
                              ? myColor.withAlpha((255 * 0.9).round())
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            message.type == 'image'
                                ? (message.imageUrl != null && message.imageUrl!.startsWith('http'))
                                    ? Image.network(message.imageUrl!)
                                    : const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.broken_image, color: Colors.white, size: 40),
                                          SizedBox(height: 4),
                                          Text('Image error', style: TextStyle(color: Colors.white)),
                                        ],
                                      )
                                : Text(
                                    message.text ?? '', // Handle potential null text
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat.Hm().format(
                                    message.timestamp.toDate(),
                                  ),
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white70
                                        : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (isMe)
                                  Icon(
                                    seen ? Icons.done_all : Icons.check,
                                    size: 16,
                                    color: seen
                                        ? Colors.blue[400]
                                        : Colors.white70,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.white, // Alt arka plan tamamen beyaz
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.photo, color: myColor),
                      onPressed: _sendImage,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "Type a message",
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: myColor,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendImage() async {
    print('1. _sendImage function called.');
    try {
      final XFile? image = await _storageService.pickImage();

      if (image != null) {
        print('2. Image picked successfully: ${image.path}');
        // Show a loading indicator if you want
        print('3. Uploading image to storage...');
        final String? imageUrl = await _storageService.uploadImage(_chatId, image);

        if (imageUrl != null) {
          print('4. Image uploaded successfully. URL: $imageUrl');
          print('5. Sending image message...');
          _messageService.sendMessage(
            chatId: _chatId,
            senderId: _currentUserId,
            otherUserId: widget.otherUserId,
            imageUrl: imageUrl,
            type: 'image',
          );
          print('6. Image message sent.');
        } else {
          print('Error: Image URL is null after upload.');
        }
      } else {
        print('Image picking cancelled or failed.');
      }
    } catch (e) {
      print('An error occurred in _sendImage: $e');
    }
  }
}
