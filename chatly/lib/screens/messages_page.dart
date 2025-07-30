import 'package:chatly/screens/add_chat_contact.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'chat_screen.dart';

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

                  final filteredUsers = users.where((doc) {
                    final userData = doc.data() as Map<String, dynamic>;
                    final username = userData['username']?.toLowerCase() ?? '';
                    return username.contains(_searchQuery);
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final userData =
                          filteredUsers[index].data() as Map<String, dynamic>;
                      final userId = filteredUsers[index].id;
                      final username = userData['username'] ?? 'Unknown';
                      final profilePhoto = userData['profilePhotoUrl'] ?? '';
                      final isOnline = userData['isOnline'] ?? false;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2F4156),
                          backgroundImage: profilePhoto.isNotEmpty
                              ? NetworkImage(profilePhoto)
                              : null,
                          child: profilePhoto.isEmpty
                              ? const Icon(Icons.person, color: Colors.white)
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
