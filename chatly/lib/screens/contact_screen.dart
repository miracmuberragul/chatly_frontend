import 'package:chatly/models/user_model.dart';
import 'package:chatly/screens/friend_request_screen.dart';
import 'package:chatly/services/friendship_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  String query = '';
  List<UserModel> allContacts = [];
  List<UserModel> filteredContacts = [];
  Set<String> sentRequests = {};
  final friendshipService = FriendshipService();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() {
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
            (user) =>
                user.username!.toLowerCase().contains(input.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20,
              ),
              child: Row(
                children: [
                  Text(
                    'Add new contact',
                    style: TextStyle(
                      color: cs.primary, // 0xFF2F4156
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                onChanged: _filterContacts,
                decoration: InputDecoration(
                  hintText: 'Search contact',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: cs.surfaceVariant, // 0xFFC8D9E6 benzeri
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

            // "Requests" link
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
                    child: Text(
                      'Requests',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contact list
            Expanded(
              child: ListView.builder(
                itemCount: filteredContacts.length,
                itemBuilder: (context, index) {
                  final UserModel user = filteredContacts[index];
                  final alreadySent = sentRequests.contains(user.username);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.primary,
                      child: Icon(Icons.person, color: cs.onPrimary),
                    ),
                    title: Text(user.username!),
                    trailing: ElevatedButton(
                      onPressed: alreadySent
                          ? null
                          : () async {
                              try {
                                final currentUser =
                                    FirebaseAuth.instance.currentUser;
                                await friendshipService.sendFriendRequest(
                                  requesterId: currentUser!.uid,
                                  receiverId: user.uid,
                                );
                                setState(() {
                                  sentRequests.add(user.username!);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Friend request sent to ${user.username}',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to send request: $e'),
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
                        style: TextStyle(
                          color: alreadySent
                              ? Colors.white
                              : const Color(0xFFFFFFFF),
                        ),
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
