import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:chatly/models/message_model.dart';
import 'package:chatly/screens/full_image_view.dart';
import 'package:chatly/services/message_service.dart';
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
  final SocketService _socketService = SocketService();
  final TextEditingController _controller = TextEditingController();
  final MessageService _messageService = MessageService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late final String _chatId;

  bool _isOtherUserTyping = false;
  StreamSubscription? _socketSubscription;
  Timer? _typingTimer;
  StreamSubscription<List<MessageModel>>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    List<String> ids = [_currentUserId, widget.otherUserId];
    ids.sort();
    _chatId = ids.join('_');
    _listenAndMarkMessagesAsSeen();

    _socketSubscription = _socketService.events.listen((event) {
      if (event['type'] == 'typing' &&
          event['payload']['chatId'] == _chatId &&
          event['payload']['userId'] != _currentUserId) {
        if (mounted) setState(() => _isOtherUserTyping = true);
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isOtherUserTyping = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _typingTimer?.cancel();
    _messagesSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _formatLastSeen(Timestamp? lastSeen) {
    if (lastSeen == null) return 'statusOffline'.tr;
    final now = DateTime.now();
    final lastSeenDateTime = lastSeen.toDate();
    final difference = now.difference(lastSeenDateTime);

    if (difference.inMinutes < 1) return 'lastSeenNow'.tr;
    if (difference.inHours < 1)
      return 'lastSeenMinutes'.trParams({
        'minutes': difference.inMinutes.toString(),
      });
    if (difference.inDays < 1)
      return 'lastSeenAt'.trParams({
        'time': DateFormat.Hm().format(lastSeenDateTime),
      });
    return 'lastSeenOn'.trParams({
      'date': DateFormat.yMd().format(lastSeenDateTime),
    });
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
      type: 'text',
    );
    _controller.clear();
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

  void _sendImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        final ext = image.name.contains('.')
            ? image.name.split('.').last
            : 'jpg';
        final dataUri = 'data:image/$ext;base64,${base64Encode(bytes)}';

        if (dataUri.length > 900000) {
          Get.snackbar(
            'error'.tr,
            'imageTooLarge'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade600,
            colorText: Colors.white,
          );
          return;
        }

        _messageService.sendMessage(
          chatId: _chatId,
          senderId: _currentUserId,
          otherUserId: widget.otherUserId,
          imageUrl: dataUri,
          type: 'image',
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        '${'imageSendError'.tr}: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    }
  }

  ImageProvider? _profileImageProvider(String url) {
    if (url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(url.split(',').last));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          onPressed: () => Get.back(),
        ),
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.otherUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final isOnline = userData['isOnline'] ?? false;
            final lastSeen = userData['lastSeen'] as Timestamp?;

            return Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (widget.profilePhotoUrl.isNotEmpty) {
                      Get.to(
                        () => FullImageView(imageUrl: widget.profilePhotoUrl),
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
                          ? 'typing'.tr
                          : (isOnline
                                ? 'statusOnline'.tr
                                : _formatLastSeen(lastSeen)),
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: _isOtherUserTyping
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: cs.secondary,
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
                  return Center(
                    child: Text(
                      'error'.trParams({'error': snapshot.error.toString()}),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('sayHi'.tr));
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final bool isMe = message.senderId == _currentUserId;

                    if (!isMe && !message.seenBy.contains(_currentUserId)) {
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
                    if (message.type == 'image' && message.imageUrl != null) {
                      Widget imageWidget;
                      if (message.imageUrl!.startsWith('data:image')) {
                        imageWidget = Image.memory(
                          base64Decode(message.imageUrl!.split(',').last),
                          fit: BoxFit.cover,
                        );
                      } else {
                        imageWidget = Image.network(
                          message.imageUrl!,
                          fit: BoxFit.cover,
                        );
                      }
                      messageContent = GestureDetector(
                        onTap: () => Get.to(
                          () => FullImageView(imageUrl: message.imageUrl!),
                        ),
                        child: ClipRRect(
                          // Resimlerin köşelerini yuvarlatmak daha şık durur
                          borderRadius: BorderRadius.circular(12),
                          child: imageWidget,
                        ),
                      );
                    } else {
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
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isMe ? bubbleMe : bubbleOther,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isMe ? 16 : 4),
                            topRight: Radius.circular(isMe ? 4 : 16),
                            bottomLeft: const Radius.circular(16),
                            bottomRight: const Radius.circular(16),
                          ),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            messageContent,
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat.Hm().format(
                                    message.timestamp.toDate(),
                                  ),
                                  style: TextStyle(
                                    color: (isMe ? onBubbleMe : onBubbleOther)
                                        .withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
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
                          hintText: 'typeMessageHint'.tr,
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
                      decoration: const BoxDecoration(
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
}
