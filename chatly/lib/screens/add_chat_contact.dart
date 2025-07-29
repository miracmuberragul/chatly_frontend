import 'package:chatly/models/user_model.dart';
import 'package:chatly/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class AddChatContactPage extends StatefulWidget {
  const AddChatContactPage({super.key});

  @override
  State<AddChatContactPage> createState() => _AddChatContactPageState();
}

class _AddChatContactPageState extends State<AddChatContactPage> {
  final UserService _userService = UserService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Map<String, List<UserModel>> _groupUsers(List<UserModel> users) {
    final Map<String, List<UserModel>> groupedUsers = {};
    for (var user in users) {
            if (user.uid == _currentUserId) continue; // Don't show current user
                  final String firstLetter = (user.username != null && user.username!.isNotEmpty) ? user.username!.substring(0, 1).toUpperCase() : '#';
      if (groupedUsers[firstLetter] == null) {
        groupedUsers[firstLetter] = [];
      }
      groupedUsers[firstLetter]!.add(user);
    }
    return groupedUsers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // User List
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                                stream: _userService.getUsersStream(_currentUserId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No users found.'));
                  }

                  final groupedUsers = _groupUsers(snapshot.data!);
                  final sortedKeys = groupedUsers.keys.toList()..sort();

                  return ListView.builder(
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      final letter = sortedKeys[index];
                      final users = groupedUsers[letter]!;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              letter,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...users.map(
                              (user) => ListTile(
                                leading: CircleAvatar(
                                                                    backgroundImage: NetworkImage(user.profilePhotoUrl ?? 'https://via.placeholder.com/150'),
                                ),
                                                                                                title: Text(user.username ?? 'Unnamed User'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        otherUserId: user.uid,
                                        username: user.username ?? 'Unnamed User',
                                        isOnline: user.isOnline,
                                        profilePhotoUrl: user.profilePhotoUrl ?? 'https://via.placeholder.com/150',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
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
