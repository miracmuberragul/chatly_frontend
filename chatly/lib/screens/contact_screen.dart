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
  Map<String, String> friendshipStatus =
      {}; // 🔹 Arkadaşlık durumlarını takip et
  final friendshipService = FriendshipService();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return;

    try {
      // 1️⃣ Önce kullanıcıları hızlıca yükle ve göster
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final contacts = snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .where((user) => user.uid != currentUserUid)
          .toList();

      // Kullanıcıları hemen göster (butonlar Add olarak)
      setState(() {
        allContacts = contacts;
        filteredContacts = List.from(allContacts);
        // Başlangıçta hepsi 'none' olarak ayarla
        friendshipStatus = {for (var user in contacts) user.uid: 'none'};
      });

      // 2️⃣ Sonra arkadaşlık durumlarını arka planda yükle
      await _loadFriendshipStatuses(currentUserUid, contacts);
    } catch (e) {
      print('Error loading contacts: $e');
    }
  }

  // 🚀 Performans optimizasyonu: Tek sorguda tüm durumları al
  Future<void> _loadFriendshipStatuses(
    String currentUserUid,
    List<UserModel> contacts,
  ) async {
    try {
      // Tüm friendships'leri tek sorguda al
      final friendshipsQuery = await FirebaseFirestore.instance
          .collection('friendships')
          .where('memberIds', arrayContains: currentUserUid)
          .get();

      Map<String, String> statusMap = {
        for (var user in contacts) user.uid: 'none',
      };

      // Her friendship kaydını kontrol et
      for (var doc in friendshipsQuery.docs) {
        final data = doc.data();
        List<dynamic> memberIds = data['memberIds'];
        String status = data['status'];
        String requesterId = data['requesterId'];

        // Bu kullanıcının friendships'lerinden hangisi contact listesinde var?
        for (String memberId in memberIds) {
          if (memberId != currentUserUid && statusMap.containsKey(memberId)) {
            if (status == 'accepted') {
              statusMap[memberId] = 'friends';
            } else if (status == 'pending') {
              if (requesterId == currentUserUid) {
                statusMap[memberId] = 'sent';
              } else {
                statusMap[memberId] = 'received';
              }
            }
          }
        }
      }

      // UI'yi güncelle
      setState(() {
        friendshipStatus = statusMap;
      });
    } catch (e) {
      print('Error loading friendship statuses: $e');
    }
  }

  // 🔹 Arkadaşlık durumunu kontrol et
  Future<String> _checkFriendshipStatus(
    String currentUserId,
    String targetUserId,
  ) async {
    try {
      // Friendships koleksiyonundan kontrol et
      final friendshipsQuery = await FirebaseFirestore.instance
          .collection('friendships')
          .where('memberIds', arrayContains: currentUserId)
          .get();

      for (var doc in friendshipsQuery.docs) {
        final data = doc.data();
        List<dynamic> memberIds = data['memberIds'];
        String status = data['status'];
        String requesterId = data['requesterId'];
        String receiverId = data['receiverId'];

        // Bu friendship bu iki kullanıcı arasında mı?
        if (memberIds.contains(targetUserId)) {
          if (status == 'accepted') {
            return 'friends'; // Zaten arkadaş
          } else if (status == 'pending') {
            if (requesterId == currentUserId) {
              return 'sent'; // Ben göndermiş, karşı taraf henüz kabul etmemiş
            } else {
              return 'received'; // Karşı taraf göndermiş, ben henüz kabul etmemiş
            }
          }
        }
      }

      return 'none'; // Hiçbir ilişki yok
    } catch (e) {
      print('Error checking friendship status: $e');
      return 'none';
    }
  }

  void _filterContacts(String input) {
    setState(() {
      query = input;
      if (input.isEmpty) {
        filteredContacts = List.from(allContacts);
      } else {
        filteredContacts = allContacts
            .where(
              (user) =>
                  user.username!.toLowerCase().contains(input.toLowerCase()),
            )
            .toList();
      }
    });
  }

  // 🔹 Buton durumunu ve metnini belirle
  Widget _buildActionButton(UserModel user) {
    final status = friendshipStatus[user.uid] ?? 'none';

    switch (status) {
      case 'friends':
        return ElevatedButton(
          onPressed: null, // Disabled
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Friends', style: TextStyle(color: Colors.white)),
        );

      case 'sent':
        return ElevatedButton(
          onPressed: null, // Disabled
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Sent', style: TextStyle(color: Colors.white)),
        );

      case 'received':
        return ElevatedButton(
          onPressed: () => _acceptFriendRequest(user),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Accept', style: TextStyle(color: Colors.white)),
        );

      case 'none':
      default:
        return ElevatedButton(
          onPressed: () => _sendFriendRequest(user),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2F4156),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Add', style: TextStyle(color: Colors.white)),
        );
    }
  }

  // 🔹 Arkadaşlık isteği gönder
  void _sendFriendRequest(UserModel user) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await friendshipService.sendFriendRequest(
        requesterId: currentUser.uid,
        receiverId: user.uid,
      );

      // UI'de güncelle
      setState(() {
        friendshipStatus[user.uid] = 'sent';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request sent to ${user.username}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send request: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // 🔹 Arkadaşlık isteğini kabul et
  void _acceptFriendRequest(UserModel user) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // FriendshipService'i kullanarak isteği kabul et
      await friendshipService.acceptFriendRequest(
        user.uid, // requesterId
        currentUser.uid, // receiverId
      );

      // UI'de güncelle
      setState(() {
        friendshipStatus[user.uid] = 'friends';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are now friends with ${user.username}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept request: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
              child: filteredContacts.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2F4156),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredContacts.length,
                      itemBuilder: (context, index) {
                        final UserModel user = filteredContacts[index];

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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Friend request sent to ${user.username}',
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to send request: $e',
                                          ),
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
