import 'dart:developer';
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
  List<UserModel> friendRequests = [];
  final friendshipService = FriendshipService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFriendRequests();
  }

  Future<void> _fetchFriendRequests() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      // Yeni eklediğimiz metodu kullanıyoruz
      final requests = await friendshipService
          .getIncomingPendingFriendRequestsAsUsers(currentUser.uid);
      setState(() {
        friendRequests = requests; // Doğrudan UserModel listesini atıyoruz
        _isLoading = false;
      });
    } catch (e) {
            log('Error fetching friend requests: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRequest(String requesterId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    try {
            await friendshipService.acceptFriendRequest(requesterId, currentUser.uid);
      setState(() {
        friendRequests.removeWhere((user) => user.uid == requesterId);
      });
    } catch (e) {
      log('Error accepting request: $e');
      // Optionally, show a snackbar to the user
    }
  }

  Future<void> _declineRequest(String requesterId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    try {
            await friendshipService.declineFriendRequest(requesterId, currentUser.uid);
      setState(() {
        friendRequests.removeWhere((user) => user.uid == requesterId);
      });
    } catch (e) {
      log('Error declining request: $e');
      // Optionally, show a snackbar to the user
    }
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
        foregroundColor: Color(0xFF2F4156),
        automaticallyImplyLeading: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : friendRequests.isEmpty
              ? Center(
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
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  itemCount: friendRequests.length,
                  itemBuilder: (context, index) {
                    final user = friendRequests[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(user.profilePhotoUrl ?? 'https://via.placeholder.com/150'),
                      ),
                      title: Text(
                        user.username ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                                                        onPressed: () => _acceptRequest(user.uid),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                                                        onPressed: () => _declineRequest(user.uid),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
