import 'package:chatly/screens/add_chat_contact.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'chat_screen.dart';

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
                    .collection('users')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No user"));
                  }

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData =
                          users[index].data() as Map<String, dynamic>;
                      final userId = users[index].id;
                      final username = userData['username'] ?? 'Unknown';
                      final profilePhoto = userData['profilePhotoUrl'] ?? '';
                      final isOnline = userData['isOnline'] ?? false;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.primary,
                          backgroundImage: profilePhoto.isNotEmpty
                              ? NetworkImage(profilePhoto)
                              : null,
                          child: profilePhoto.isEmpty
                              ? Icon(Icons.person, color: cs.onPrimary)
                              : null,
                        ),
                        title: Text(username),
                        subtitle: const Text('Last message...'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                otherUserId: userId,
                                username: username,
                                isOnline: isOnline,
                                profilePhotoUrl: profilePhoto,
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
          ],
        ),
      ),
    );
  }
}
