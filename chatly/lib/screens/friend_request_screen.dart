import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FriendRequestScreen extends StatefulWidget {
  const FriendRequestScreen({super.key});

  @override
  State<FriendRequestScreen> createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends State<FriendRequestScreen> {
  // Şimdilik test verisi
  final List<String> friendRequests = [];

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
                final name = friendRequests[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF2F4156),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    name,
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
                        onPressed: () {
                          // Kabul et
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF2F4156)),
                        onPressed: () {
                          // Reddet
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
