import 'package:chatly/models/chat_model.dart';
import 'package:chatly/models/user_model.dart';
import 'package:chatly/services/chat_service.dart';
import 'package:chatly/services/user_service.dart';
import 'package:chatly/screens/add_chat_contact.dart';
import 'package:chatly/screens/friend_request_screen.dart';
import 'package:chatly/screens/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'chat_screen.dart';
import 'dart:async';
import 'package:chatly/services/socket_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  StreamSubscription? _socketSubscription;

  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _socketService.connect(currentUserId);

    _socketSubscription = _socketService.events.listen((event) {
      final eventType = event['type'];
      final payload = event['payload'];
      if (payload == null || payload['userId'] == null) return;

      if (eventType == 'user_online') {
        _userService.updateUserOnlineStatus(payload['userId'], true);
      } else if (eventType == 'user_offline') {
        _userService.updateUserOnlineStatus(payload['userId'], false);
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _socketService.dispose();
    super.dispose();
  }

  int _selectedIndex = 1;
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    Widget buildNoChatsWidget() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              FontAwesomeIcons.solidCommentDots,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'No chats yet',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            SizedBox(height: 10),
            Text(
              'Tap on the + icon to start a new chat.',
              style: TextStyle(fontSize: 14, color: Colors.black45),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20,
              ),
              child: Row(
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
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
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Chat List
            Expanded(
              child: StreamBuilder<List<ChatModel>>(
                stream: _chatService.getChatsStream(currentUserId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    // If there are no chats, show a list of users to start a chat with.
                    return StreamBuilder<List<UserModel>>(
                      stream: _userService.getUsersStream(currentUserId),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (userSnapshot.hasError) {
                          return Center(
                            child: Text('Error: ${userSnapshot.error}'),
                          );
                        }
                        if (!userSnapshot.hasData ||
                            userSnapshot.data!.isEmpty) {
                          return buildNoChatsWidget(); // Show this only if there are no users to chat with
                        }

                        final users = userSnapshot.data!;
                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(
                                  user.profilePhotoUrl ??
                                      'https://via.placeholder.com/150',
                                ),
                              ),
                              title: Text(user.username ?? 'No Name'),
                              subtitle: Text(
                                user.isOnline ? 'Online' : 'Offline',
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      otherUserId: user.uid,
                                      username: user.username ?? 'No Name',
                                      isOnline: user.isOnline,
                                      profilePhotoUrl:
                                          user.profilePhotoUrl ?? '',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  }

                  final chats = snapshot.data!;
                  return ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final otherUserId = chat.members.firstWhere(
                        (id) => id != currentUserId,
                        orElse: () => '',
                      );

                      if (otherUserId.isEmpty) return const SizedBox.shrink();

                      return FutureBuilder<UserModel?>(
                        future: _userService.getUser(otherUserId),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return const ListTile(title: Text('Loading...'));
                          }
                          final otherUser = userSnapshot.data!;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                otherUser.profilePhotoUrl ??
                                    'https://via.placeholder.com/150',
                              ),
                              backgroundColor: Colors.grey[300],
                              child:
                                  (otherUser.profilePhotoUrl == null ||
                                      otherUser.profilePhotoUrl!.isEmpty)
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(
                              otherUser.username ?? 'No Name',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              chat.lastMessage,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    otherUserId: otherUserId,
                                    username: otherUser.username ?? 'No Name',
                                    isOnline: otherUser.isOnline,
                                    profilePhotoUrl:
                                        otherUser.profilePhotoUrl ??
                                        'https://via.placeholder.com/150',
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
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) return; // Already on this page

          setState(() {
            _selectedIndex = index;
          });

          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FriendRequestScreen(),
              ),
            ).then(
              (_) => setState(() => _selectedIndex = 1),
            ); // Reset index when returning
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            ).then(
              (_) => setState(() => _selectedIndex = 1),
            ); // Reset index when returning
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.users, color: Color(0xFF2F4156)),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.solidMessage, color: Color(0xFF71D7E1)),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.gear, color: Color(0xFF2F4156)),
            label: '',
          ),
        ],
      ),
    );
  }
}
