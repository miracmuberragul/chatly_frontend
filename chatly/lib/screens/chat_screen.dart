import 'package:chatly/models/message_model.dart';
import 'package:chatly/services/message_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatly/services/storage_service.dart'; // Import StorageService
import 'dart:convert'; // For base64
import 'package:image_picker/image_picker.dart'; // Import image_picker

import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:intl/intl.dart';
import 'package:chatly/services/socket_service.dart';
import 'package:chatly/screens/full_image_view.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String username;
  final bool isOnline;
  final String profilePhotoUrl;

  const ChatScreen({
    required this.otherUserId,
    required this.username,
    required this.isOnline,
    required this.profilePhotoUrl,
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  DateTime? _lastTypingSent; // throttle typing events
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
  StreamSubscription<List<MessageModel>>? _messagesSubscription;

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

    // Join the specific chat room (connection already established in home page)
    _socketService.sendEvent('join_chat', {'chatId': _chatId});

    _listenAndMarkMessagesAsSeen();

    _socketSubscription = _socketService.events.listen((event) {
      print(
        '📡 Socket event received: ${event['event']} - chatId: ${event['chatId']} - userId: ${event['userId']}',
      );
      if (event['event'] == 'typing' &&
          event['chatId'] == _chatId &&
          event['userId'] != _currentUserId) {
        final isTyping = event['isTyping'] == true;
        print('✅ Typing event matched - isTyping: $isTyping');
        if (mounted) {
          setState(() {
            _isOtherUserTyping = isTyping;
          });
        }
        // Eğer typing false ise timer'ı iptal et
        if (!isTyping) {
          _typingTimer?.cancel();
        }
      } else if (event['event'] == 'chat_message' &&
          event['chatId'] == _chatId) {
        final message = MessageModel.fromWebSocket(event);
        print('New message received via WebSocket: ${message.text}');
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _socketSubscription?.cancel();
    _controller.dispose();
    _typingTimer?.cancel();
    _messagesSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTyping() {
    print('🔤 _onTyping called');
    final now = DateTime.now();
    if (_lastTypingSent == null ||
        now.difference(_lastTypingSent!) > const Duration(milliseconds: 500)) {
      _lastTypingSent = now;
      print(
        '🔤 Sending typing event - chatId: $_chatId, userId: $_currentUserId, isTyping: true',
      );
      _socketService.sendEvent('typing', {
        'chatId': _chatId,
        'userId': _currentUserId,
        'isTyping': true,
      });
    } else {
      print('🔤 Typing throttled - too soon');
    }
    // Kullanıcı yazmayı bıraktığında typing'i false yap
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      print('🔤 Typing stopped - sending isTyping: false');
      _socketService.sendEvent('typing', {
        'chatId': _chatId,
        'userId': _currentUserId,
        'isTyping': false,
      });
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // The message data to be sent
    final messageData = {
      'chatId': _chatId,
      'senderId': _currentUserId,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Send message via WebSocket
    _socketService.sendEvent('chat_message', messageData);

    // Also save to Firestore for persistence
    _messageService.sendMessage(
      chatId: _chatId,
      senderId: _currentUserId,
      otherUserId: widget.otherUserId,
      text: text,
      type: 'text',
    );

    _controller.clear();
    // Scroll to bottom after sending a message
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _listenAndMarkMessagesAsSeen() {
    _messagesSubscription?.cancel();
    _messagesSubscription = _messageService.getMessagesStream(_chatId).listen((
      messages,
    ) {
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

  // Fallback one-shot call in case listener attaches slightly late
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

    ImageProvider? _profileImageProvider(String url) {
      if (url.isEmpty) {
        return null;
      }
      if (url.startsWith('data:image')) {
        try {
          final bytes = base64Decode(url.split(',').last);
          return MemoryImage(bytes);
        } catch (_) {
          return null;
        }
      }
      return NetworkImage(url);
    }

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
                GestureDetector(
                  onTap: () {
                    if (widget.profilePhotoUrl.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FullImageView(imageUrl: widget.profilePhotoUrl),
                        ),
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: _profileImageProvider(
                      widget.profilePhotoUrl,
                    ),
                    backgroundColor: isDark
                        ? Colors.grey[700]
                        : Colors.grey[300],
                    child: widget.profilePhotoUrl.isEmpty
                        ? const Icon(Icons.person, size: 18)
                        : null,
                  ),
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
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final bool isMe = message.senderId == _currentUserId;
                          // Eğer bu kullanıcı için daha önce görülmediyse hemen işaretle
                          if (!isMe &&
                              !message.seenBy.contains(_currentUserId)) {
                            _messageService.markMessageAsSeen(
                              chatId: _chatId,
                              messageId: message.id,
                              userId: _currentUserId,
                            );
                          }
                          final bool seen = message.seenBy.contains(
                            widget.otherUserId,
                          );

                          Widget messageContent;
                          if (message.type == 'image' &&
                              message.imageUrl != null) {
                            Widget imageWidget;
                            if (message.imageUrl!.startsWith('data:image')) {
                              // base64 image
                              final base64Str = message.imageUrl!
                                  .split(',')
                                  .last;
                              imageWidget = Image.memory(
                                base64Decode(base64Str),
                                width: 180,
                                fit: BoxFit.cover,
                              );
                            } else if (message.imageUrl!.startsWith('http')) {
                              // network image
                              imageWidget = Image.network(
                                message.imageUrl!,
                                width: 180,
                                fit: BoxFit.cover,
                              );
                            } else {
                              imageWidget = const Icon(
                                Icons.broken_image,
                                size: 40,
                                color: Colors.red,
                              );
                            }

                            // Wrap with tap-to-fullscreen if valid image
                            if (message.imageUrl!.startsWith('data:image') ||
                                message.imageUrl!.startsWith('http')) {
                              messageContent = GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullImageView(
                                        imageUrl: message.imageUrl!,
                                      ),
                                    ),
                                  );
                                },
                                child: imageWidget,
                              );
                            } else {
                              messageContent = imageWidget;
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
        final ext = image.name.contains('.')
            ? image.name.split('.').last
            : 'jpg';
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
