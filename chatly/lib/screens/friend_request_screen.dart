import 'package:chatly/models/user_model.dart';
import 'package:chatly/services/friendship_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FriendRequestScreen extends StatefulWidget {
  const FriendRequestScreen({super.key});

  @override
  State<FriendRequestScreen> createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends State<FriendRequestScreen> {
  final FriendshipService _friendshipService = FriendshipService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late Future<List<UserModel>> _friendRequestsFuture;

  @override
  void initState() {
    super.initState();
    _loadFriendRequests();
  }

  void _loadFriendRequests() {
    _friendRequestsFuture = _friendshipService
        .getIncomingPendingFriendRequestsAsUsers(currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Requests',
          style: TextStyle(
            color: Color(0xFF2F4156),
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2F4156),
        automaticallyImplyLeading: true,
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _friendRequestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(FontAwesomeIcons.userPlus, size: 64, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'No friend requests',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                ],
              ),
            );
          }

          final friendRequests = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 20),
            itemCount: friendRequests.length,
            itemBuilder: (context, index) {
              final user = friendRequests[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    user.profilePhotoUrl ?? 'https://via.placeholder.com/150',
                  ),
                ),
                title: Text(user.username ?? 'No Name'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        if (user.uid != null) {
                          await _friendshipService.acceptFriendRequest(
                            user.uid,
                            currentUserId,
                          );
                          setState(() {
                            _loadFriendRequests();
                          });
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        if (user.uid != null) {
                          await _friendshipService.declineFriendRequest(
                            user.uid,
                            currentUserId,
                          );
                          setState(() {
                            _loadFriendRequests();
                          });
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
