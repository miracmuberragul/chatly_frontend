import 'package:chatly/screens/add_chat_contact.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'chat_screen.dart';
import 'full_image_view.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

final TextEditingController _searchController = TextEditingController();
String _searchQuery = '';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  int _selectedIndex = 1; // Ortadaki ikon (mesaj) aktif olacak

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
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
                    'Messages',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: cs.primary, // 0xFF2F4156
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
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase(); // küçük harfe çevir
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: cs.surfaceVariant, // 0xFFC8D9E6
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
                    return const Center(child: Text("You have no messages."));
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
                      );

                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUserId)
                            .snapshots(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            return const SizedBox();
                          }

                          final userData =
                              userSnapshot.data!.data() as Map<String, dynamic>;
                          final username = userData['username'] ?? 'Unknown';
                          final profilePhoto =
                              userData['profilePhotoUrl'] ?? '';
                          final isOnline = userData['isOnline'] ?? false;

                          if (_searchQuery.isNotEmpty &&
                              !username.toLowerCase().contains(_searchQuery)) {
                            return const SizedBox();
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
                                  final msgDoc = messageSnapshot.data!.docs.first;
                                  final msgData = msgDoc.data() as Map<String, dynamic>;
                                  final List<dynamic> seenByDyn = msgData['seenBy'] ?? [];
                                  final List<String> seenBy = seenByDyn.cast<String>();
                                  final String senderIdMsg = msgData['senderId'] ?? '';
                                  if (senderIdMsg != currentUserId &&
                                      !seenBy.contains(currentUserId)) {
                                    isUnread = true;
                                  }
                                }

                                return ListTile(
                                  leading: Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (profilePhoto.startsWith('data:image') || profilePhoto.startsWith('http')) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => FullImageView(imageUrl: profilePhoto),
                                              ),
                                            );
                                          }
                                        },
                                        child: CircleAvatar(
                                          radius: 24,
                                          backgroundImage: profilePhoto.isNotEmpty
                                              ? (profilePhoto.startsWith('data:image')
                                                  ? MemoryImage(base64Decode(profilePhoto.split(',').last))
                                                  : NetworkImage(profilePhoto) as ImageProvider)
                                              : null,
                                          backgroundColor: Colors.grey[400],
                                          child: profilePhoto.isEmpty
                                              ? const Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                  size: 24,
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
                                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Text(
                                    chatData['lastMessage'] ?? '',
                                    style: TextStyle(
                                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  trailing: isUnread
                                      ? const Icon(Icons.circle, color: Colors.blue, size: 10)
                                      : null,
                                  onTap: () {
                                    // Final check to ensure we don't pass an invalid URL
                                    final validProfilePhotoUrl =
                                        (profilePhoto.startsWith('http') || profilePhoto.startsWith('data:image'))
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
