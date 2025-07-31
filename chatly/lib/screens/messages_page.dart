import 'package:chatly/screens/add_chat_contact.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'full_image_view.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart'; // <-- EKLENDİ

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  // int _selectedIndex = 1; // Bu state kullanılmıyor, kaldırılabilir.

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(body: Center(child: Text('userNotLoggedIn'.tr)));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Başlık ve + Butonu
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20,
              ),
              child: Row(
                children: [
                  Text(
                    'messagesTitle'.tr, // <-- DEĞİŞTİ
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddChatContactPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Arama Çubuğu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                // onChanged listener'ı zaten var.
                decoration: InputDecoration(
                  hintText: 'searchHint'.tr, // <-- DEĞİŞTİ
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: cs.surfaceVariant,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: cs.primary),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: cs.primary, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Mesaj Listesi
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .where('members', arrayContains: currentUserId)
                    .orderBy('lastMessageTimestamp', descending: true)
                    .snapshots(),
                builder: (context, chatSnapshot) {
                  if (chatSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!chatSnapshot.hasData ||
                      chatSnapshot.data!.docs.isEmpty) {
                    return Center(child: Text("noMessages".tr)); // <-- DEĞİŞTİ
                  }

                  final chatDocs = chatSnapshot.data!.docs;

                  return ListView.builder(
                    itemCount: chatDocs.length,
                    itemBuilder: (context, index) {
                      final chatData =
                          chatDocs[index].data() as Map<String, dynamic>;
                      final members = List<String>.from(
                        chatData['members'] ?? [],
                      );
                      final otherUserId = members.firstWhere(
                        (id) => id != currentUserId,
                        orElse: () => '',
                      );

                      if (otherUserId.isEmpty) return const SizedBox.shrink();

                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUserId)
                            .snapshots(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            return const SizedBox.shrink();
                          }

                          final userData =
                              userSnapshot.data!.data() as Map<String, dynamic>;
                          final username =
                              userData['username'] ??
                              'unknownUser'.tr; // <-- DEĞİŞTİ
                          final profilePhoto =
                              userData['profilePhotoUrl'] ?? '';
                          final isOnline = userData['isOnline'] ?? false;

                          if (_searchQuery.isNotEmpty &&
                              !username.toLowerCase().contains(_searchQuery)) {
                            return const SizedBox.shrink();
                          }

                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('chats')
                                .doc(chatDocs[index].id)
                                .collection('messages')
                                .orderBy('timestamp', descending: true)
                                .limit(1)
                                .snapshots(),
                            builder: (context, messageSnapshot) {
                              bool isUnread = false;
                              if (messageSnapshot.hasData &&
                                  messageSnapshot.data!.docs.isNotEmpty) {
                                final msgData =
                                    messageSnapshot.data!.docs.first.data()
                                        as Map<String, dynamic>;
                                final seenBy = List<String>.from(
                                  msgData['seenBy'] ?? [],
                                );
                                if (msgData['senderId'] != currentUserId &&
                                    !seenBy.contains(currentUserId)) {
                                  isUnread = true;
                                }
                              }

                              return ListTile(
                                leading: Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (profilePhoto.startsWith(
                                              'data:image',
                                            ) ||
                                            profilePhoto.startsWith('http')) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => FullImageView(
                                                imageUrl: profilePhoto,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: CircleAvatar(
                                        // *** DEĞİŞİKLİK 1: Yarıçapı küçülttük ***
                                        radius:
                                            22, // Örneğin 22 (veya 20, 21) daha standart bir boyuttur.
                                        backgroundImage: profilePhoto.isNotEmpty
                                            ? (profilePhoto.startsWith(
                                                    'data:image',
                                                  )
                                                  ? MemoryImage(
                                                      base64Decode(
                                                        profilePhoto
                                                            .split(',')
                                                            .last,
                                                      ),
                                                    )
                                                  : NetworkImage(profilePhoto)
                                                        as ImageProvider)
                                            : null,
                                        backgroundColor: Colors.grey[400],
                                        child: profilePhoto.isEmpty
                                            ? const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                // *** DEĞİŞİKLİK 2: İkon boyutunu da yarıçapla uyumlu hale getirdik ***
                                                size: 22,
                                              )
                                            : null,
                                      ),
                                    ),
                                    if (isOnline)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          height: 12,
                                          width: 12,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Text(
                                  username,
                                  style: TextStyle(
                                    fontWeight: isUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  chatData['lastMessage'] != null
                                      ? (chatData['lastMessage'].length > 30
                                            ? '${chatData['lastMessage'].substring(0, 30)}...'
                                            : chatData['lastMessage'])
                                      : '',
                                  style: TextStyle(
                                    fontWeight: isUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: isUnread
                                    ? const Icon(
                                        Icons.circle,
                                        color: Colors.blue,
                                        size: 10,
                                      )
                                    : null,
                                onTap: () {
                                  final validProfilePhotoUrl =
                                      (profilePhoto.startsWith('http') ||
                                          profilePhoto.startsWith('data:image'))
                                      ? profilePhoto
                                      : '';
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        otherUserId: otherUserId,
                                        username: username,
                                        isOnline: isOnline,
                                        profilePhotoUrl: validProfilePhotoUrl,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
