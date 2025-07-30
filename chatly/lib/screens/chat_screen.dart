import 'package:chatly/models/message_model.dart';
import 'package:chatly/services/message_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatly/services/storage_service.dart'; // Import StorageService
import 'dart:convert'; // For base64
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
    _chatId = ids.join('_'); // <- yazım düzeltildi (tema dışı, crash önleme)

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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Balon renkleri: marka ikincil tonunu "benim mesajım" için kullanıyoruz.
    final bubbleMe = isDark ? const Color(0xFFC8D9E6) : const Color(0xFF567C8D);
    final onBubbleMe = cs.onSecondary;
    final bubbleOther = cs.surface;
    final onBubbleOther = cs.onSurface;

    return Scaffold(
      backgroundColor: cs.tertiary,
      appBar: AppBar(
        backgroundColor: cs.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(FontAwesomeIcons.chevronLeft, color: cs.primary),
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
                  backgroundImage: widget.profilePhotoUrl.isNotEmpty
                      ? NetworkImage(widget.profilePhotoUrl)
                      : null,
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                  child: widget.profilePhotoUrl.isEmpty
                      ? const Icon(Icons.person, size: 18)
                      : null,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.username,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onBackground,
                      ),
                    ),
                    Text(
                      _isOtherUserTyping
                          ? 'typing...'
                          : (isOnline ? 'online' : _formatLastSeen(lastSeen)),
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: _isOtherUserTyping
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: cs.secondary, // durum rengi (marka uyumlu)
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
                return Column(
                  children: [
                    if (_isOtherUserTyping)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "${widget.username} is typing...",
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        reverse: true, // en yeni altta
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final bool isMe = message.senderId == _currentUserId;
                          final bool seen = message.seenBy.length > 1;

                          Widget messageContent;
                          if (message.type == 'image' && message.imageUrl != null) {
                            if (message.imageUrl!.startsWith('data:image')) {
                              // Handle base64 image
                              final base64Str = message.imageUrl!.split(',').last;
                              messageContent = Image.memory(
                                base64Decode(base64Str),
                                width: 180,
                                fit: BoxFit.cover,
                              );
                            } else if (message.imageUrl!.startsWith('http')) {
                              // Handle network image
                              messageContent = Image.network(
                                message.imageUrl!,
                                width: 180,
                                fit: BoxFit.cover,
                              );
                            } else {
                              // Handle invalid or unknown image URL format
                              messageContent = const Icon(Icons.broken_image, size: 40, color: Colors.red);
                            }
                          } else {
                            // Handle text message
                            messageContent = Text(
                              message.text ?? '',
                              style: TextStyle(
                                color: isMe ? onBubbleMe : onBubbleOther,
                                fontSize: 16,
                              ),
                            );
                          }

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: isMe ? bubbleMe : bubbleOther,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(isMe ? 12 : 0),
                                  topRight: Radius.circular(isMe ? 0 : 12),
                                  bottomLeft: const Radius.circular(12),
                                  bottomRight: const Radius.circular(12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  messageContent,
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        DateFormat.Hm().format(
                                          message.timestamp.toDate(),
                                        ),
                                        style: TextStyle(
                                          color:
                                              (isMe
                                                      ? onBubbleMe
                                                      : onBubbleOther)
                                                  .withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      if (isMe)
                                        Icon(
                                          seen ? Icons.done_all : Icons.check,
                                          size: 16,
                                          color: seen
                                              ? (isDark
                                                    ? Colors.blue[300]
                                                    : Colors.blue[600])
                                              : onBubbleMe.withOpacity(0.7),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Alt giriş alanı
          Container(
            color: cs.surface,
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
                      icon: Icon(Icons.add_a_photo, color: cs.primary),
                      onPressed: _sendImage,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: (_) => _onTyping(),
                        decoration: InputDecoration(
                          hintText: "Type a message",

                          filled: true,
                          fillColor: cs.scrim,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
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
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2F4156),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send, color: cs.background),
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
      // Use image picker directly instead of storage service
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null && image.path.isNotEmpty) {
        print('2. Image picked successfully: ${image.path}');
        print('3. Converting to base64...');
        final bytes = await image.readAsBytes();
        final ext =
            image.name.contains('.') ? image.name.split('.').last : 'jpg';
        final base64Str = base64Encode(bytes);
        final dataUri = 'data:image/$ext;base64,$base64Str';
        print('4. base64 length: ${dataUri.length}');

        if (dataUri.length > 900000) {
          print('Image too large for Firestore document.');
          // Optionally, show a snackbar to the user
          return;
        }

        print('5. Sending image message...');
        _messageService.sendMessage(
          chatId: _chatId,
          senderId: _currentUserId,
          otherUserId: widget.otherUserId,
          imageUrl: dataUri,
          type: 'image',
        );
        print('6. Image message sent.');
      } else {
        print('Image picking cancelled or failed.');
      }
    } catch (e) {
      print('An error occurred in _sendImage: $e');
      // Optionally, show an error message to the user
    }
  }
}
