import 'package:chatly/models/user_model.dart';
import 'package:chatly/screens/friend_request_screen.dart';
import 'package:chatly/services/friendship_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  String query = '';
  List<UserModel> allContacts = [];
  List<UserModel> filteredContacts = [];
  Set<String> sentRequests = {}; // 🔹 Gönderilen istekleri takip
  final friendshipService = FriendshipService();
  @override
  void initState() {
    super.initState();
    _loadContacts(); // 🔹 Kontakları yükle
  }

  void _loadContacts() {
    // 🔹 Burada Firestore'dan kullanıcıları yükleyin
    // Örnek olarak, tüm kullanıcıları alıyoruz
    FirebaseFirestore.instance.collection('users').get().then((snapshot) {
      setState(() {
        allContacts = snapshot.docs
            .map((doc) => UserModel.fromJson(doc.data()))
            .toList();
        filteredContacts = allContacts;
      });
    });
  }

  void _filterContacts(String input) {
    setState(() {
      query = input;
      filteredContacts = allContacts
          .where(
            (user) => user.username.toLowerCase().contains(input.toLowerCase()),
          )
          .toList();
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
            'Add new contact',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Search bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(primaryColor: const Color(0xFF2F4156)),
                child: TextField(
                  cursorColor: const Color(0xFF2F4156),
                  onChanged: _filterContacts,
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: const BorderSide(
                        color: Color(0xFF2F4156),
                        width: 2.0,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
              ),
            ),

            // 🔗 "Requests" link
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FriendRequestScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Requests',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2F4156),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 👥 Contact list
            Expanded(
              child: ListView.builder(
                itemCount: filteredContacts.length,
                itemBuilder: (context, index) {
                  final UserModel user = filteredContacts[index];
                  final alreadySent = sentRequests.contains(user.username);

                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF2F4156),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(user.username),

                    trailing: ElevatedButton(
                      onPressed: alreadySent
                          ? null
                          : () async {
                              try {
                                final currentUser =
                                    FirebaseAuth.instance.currentUser;
                                List<String> ids = [currentUser!.uid, user.uid];
                                // Firestore'a friend request gönder
                                await friendshipService.sendFriendRequest(
                                  currentUser!.uid,
                                  user.uid,
                                );

                                // UI'de güncelle
                                setState(() {
                                  sentRequests.add(user.username);
                                });

                                // Bildirim
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Friend request sent to ${user.username}',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to send request: $e'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alreadySent
                            ? Colors.grey
                            : const Color(0xFF2F4156),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        alreadySent ? 'Sent' : 'Add',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
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
