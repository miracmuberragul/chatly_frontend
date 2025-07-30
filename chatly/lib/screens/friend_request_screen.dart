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

  Future<void> _acceptFriendRequest(String requesterId) async {
    await _friendshipService.acceptFriendRequest(requesterId, currentUserId);
    setState(() {
      _loadFriendRequests();
    });
  }

  Future<void> _rejectFriendRequest(String requesterId) async {
    await _friendshipService.rejectFriendRequest(requesterId, currentUserId);
    setState(() {
      _loadFriendRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Requests',
          style: TextStyle(
            color: cs.onBackground,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        // Arka/ön renkleri tema yönetsin; sabitleme yok.
        elevation: 0,
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
                children: [
                  Icon(
                    FontAwesomeIcons.userPlus,
                    size: 64,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No friend requests',
                    style: TextStyle(fontSize: 18, color: cs.onSurfaceVariant),
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

              Widget leadingAvatar;
              if (user.profilePhotoUrl != null &&
                  user.profilePhotoUrl!.isNotEmpty) {
                leadingAvatar = CircleAvatar(
                  backgroundImage: NetworkImage(user.profilePhotoUrl!),
                );
              } else {
                final initial = (user.username?.isNotEmpty ?? false)
                    ? user.username!.characters.first.toUpperCase()
                    : '?';
                leadingAvatar = CircleAvatar(
                  backgroundColor: cs.primary,
                  child: Text(initial, style: TextStyle(color: cs.onPrimary)),
                );
              }

              return ListTile(
                leading: leadingAvatar,
                title: Text(user.username ?? 'No Name'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Accept',
                      icon: Icon(Icons.check, color: cs.secondary),
                      onPressed: () {
                        if (user.uid != null) {
                          _acceptFriendRequest(user.uid!);
                        }
                      },
                    ),
                    IconButton(
                      tooltip: 'Reject',
                      icon: Icon(Icons.close, color: cs.error),
                      onPressed: () {
                        if (user.uid != null) {
                          _rejectFriendRequest(user.uid!);
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
