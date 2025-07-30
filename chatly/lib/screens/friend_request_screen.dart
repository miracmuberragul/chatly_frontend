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
