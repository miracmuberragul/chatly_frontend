import 'package:chatly/models/user_model.dart';
import 'package:chatly/services/auth_page.dart';
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
  // Şimdilik test verisi
  List<UserModel> friendRequests = [];
  final friendshipService = FriendshipService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
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
      print('Error fetching friend requests: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasRequests = friendRequests.isNotEmpty;

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
      body: hasRequests
          ? ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: friendRequests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = friendRequests[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF2F4156),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    user.username,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Color(0xFF2F4156)),
                        onPressed: () async {
                          final currentUser = FirebaseAuth.instance.currentUser;
                          if (currentUser == null) return;
                          List<String> ids = [currentUser.uid, user.uid];
                          ids.sort();
                          String friendshipId = ids.join('_');

                          await friendshipService.acceptFriendRequest(
                            friendshipId,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF2F4156)),
                        onPressed: () async {
                          final currentUser = FirebaseAuth.instance.currentUser;
                          if (currentUser == null) return;
                          List<String> ids = [currentUser.uid, user.uid];
                          ids.sort();
                          String friendshipId = ids.join('_');

                          await friendshipService.rejectFriendRequest(
                            friendshipId,
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            )
          : Center(
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
            ),
    );
  }
}
