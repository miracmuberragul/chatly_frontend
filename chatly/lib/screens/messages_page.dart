import 'package:chatly/screens/add_chat_contact.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'chat_screen.dart';
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
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            //  Başlık ve + Butonu
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20,
              ),
              child: Row(
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F4156),
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

            //  Arama Çubuğu
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
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF2F4156)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFF2F4156),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            //  Mesaj Listesi
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

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUserId)
                            .get(),
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

                          return Dismissible(
                            key: Key(chatDocs[index].id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              color: Colors.red,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Chat'),
                                  content: const Text(
                                    'Are you sure you want to delete this conversation?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) async {
                              final chatId = chatDocs[index].id;
                              final messenger = ScaffoldMessenger.maybeOf(
                                context,
                              );

                              await FirebaseFirestore.instance
                                  .collection('chats')
                                  .doc(chatId)
                                  .delete();

                              if (messenger != null && mounted) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Conversation deleted'),
                                  ),
                                );
                              }
                            },
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF2F4156),
                                backgroundImage: profilePhoto.isNotEmpty
                                    ? NetworkImage(profilePhoto)
                                    : null,
                                child: profilePhoto.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              title: Text(username),
                              subtitle: Text(chatData['lastMessage'] ?? ''),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      otherUserId: otherUserId,
                                      username: username,
                                      isOnline: isOnline,
                                      profilePhotoUrl: profilePhoto,
                                    ),
                                  ),
                                );
                              },
                            ),
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
