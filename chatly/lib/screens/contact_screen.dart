import 'package:chatly/screens/chat_screen.dart';
import 'package:chatly/screens/friend_request_screen.dart';
import 'package:chatly/services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/friendship_model.dart';
import '../models/user_model.dart';
import '../services/friendship_service.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _friendshipService = FriendshipService();
  final _chatService = ChatService();
  final _currentUser = FirebaseAuth.instance.currentUser!;

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  Set<String> _friendIds = {};
  Set<String> _pendingRequestIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      _allUsers = usersSnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .where((user) => user.uid != _currentUser.uid)
          .toList();

      final friendshipsSnapshot = await FirebaseFirestore.instance
          .collection('friendships')
          .where('memberIds', arrayContains: _currentUser.uid)
          .get();

      final friendIds = <String>{};
      final pendingIds = <String>{};

      for (var doc in friendshipsSnapshot.docs) {
        final friendship = FriendshipModel.fromJson(doc.data());
        final otherUserId = friendship.requesterId == _currentUser.uid
            ? friendship.receiverId
            : friendship.requesterId;

        if (friendship.status == 'accepted') {
          friendIds.add(otherUserId);
        } else if (friendship.status == 'pending' &&
            friendship.requesterId == _currentUser.uid) {
          pendingIds.add(otherUserId);
        }
      }

      if (mounted) {
        setState(() {
          _friendIds = friendIds;
          _pendingRequestIds = pendingIds;
          _filteredUsers = _allUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load contact data: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterContacts(String query) {
    if (query.isEmpty) {
      _filteredUsers = _allUsers;
    } else {
      _filteredUsers = _allUsers
          .where(
            (user) => user.username.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
    setState(() {});
  }

  void _sendFriendRequest(String receiverId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _friendshipService.sendFriendRequest(
        requesterId: _currentUser.uid,
        receiverId: receiverId,
      );
      setState(() {
        _pendingRequestIds.add(receiverId);
      });
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Friend request sent.')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    }
  }

  void _startChat(UserModel user) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final chatId = await _chatService.createChatWithFriend(
        _currentUser.uid,
        user.uid,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUserId: user.uid,
              username: user.username,
              isOnline: user.isOnline,
              profilePhotoUrl: user.profilePhotoUrl,
            ),
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to start chat: $e')),
      );
    }
  }

  Widget _buildTrailingWidget(UserModel user) {
    if (_friendIds.contains(user.uid)) {
      return IconButton(
        icon: const Icon(
          FontAwesomeIcons.solidMessage,
          color: Color(0xFF2F4156),
        ),
        onPressed: () => _startChat(user),
      );
    }

    if (_pendingRequestIds.contains(user.uid)) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
        child: const Text('Sent', style: TextStyle(color: Colors.white)),
      );
    }

    return ElevatedButton(
      onPressed: () => _sendFriendRequest(user.uid),
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F4156)),
      child: const Text('Add', style: TextStyle(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Contacts',
          style: TextStyle(
            color: Color(0xFF2F4156),
            fontWeight: FontWeight.bold,
            fontSize: 30,
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: TextField(
                onChanged: _filterContacts,
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FriendRequestScreen(),
                      ),
                    ),
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                      ? const Center(child: Text('No users found.'))
                      : ListView.builder(
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user.profilePhotoUrl != null
                                    ? NetworkImage(user.profilePhotoUrl!)
                                    : null,
                                backgroundColor: const Color(0xFF2F4156),
                                child: user.profilePhotoUrl == null
                                    ? const Icon(Icons.person, color: Colors.white)
                                    : null,
                              ),
                              title: Text(user.username),
                              trailing: _buildTrailingWidget(user),
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
