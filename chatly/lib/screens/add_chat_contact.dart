import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore'a direkt erişim için kalsın
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication'dan UID almak için
import '../models/user_model.dart'; // UserModel'e ihtiyacımız var.
import '../services/friendship_service.dart'; // FriendshipService'e ihtiyacımız var.
import '../services/user_service.dart'; // Tüm kullanıcıları almak için UserService'e ihtiyacımız var.
import 'chat_screen.dart';

class AddChatContactPage extends StatefulWidget {
  const AddChatContactPage({super.key});

  @override
  State<AddChatContactPage> createState() => _AddChatContactPageState();
}

class _AddChatContactPageState extends State<AddChatContactPage> {
  final FriendshipService _friendshipService = FriendshipService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });

    if (currentUserId == null) {
      debugPrint(
        "Hata: currentUserId null. Kullanıcı oturum açmamış olabilir.",
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, List<UserModel>> _groupUsers(List<UserModel> users) {
    final Map<String, List<UserModel>> grouped = {};
    for (var user in users) {
      if (user.username != null && user.username!.isNotEmpty) {
        final String firstLetter = user.username![0].toUpperCase();
        grouped[firstLetter] ??= [];
        grouped[firstLetter]!.add(user);
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        centerTitle: true,
        // Renkleri tema yönetsin; sabitleme yok.
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color:
                Theme.of(context).appBarTheme.foregroundColor ??
                cs.onBackground,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search contacts',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchText = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: cs.surfaceVariant, // 0xFFC8D9E6 benzeri
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Kişi Listesi
            Expanded(
              child: currentUserId == null
                  ? const Center(
                      child: Text(
                        "Oturum açmış kullanıcı bulunamadı. Lütfen giriş yapın.",
                      ),
                    )
                  : StreamBuilder<List<UserModel>>(
                      stream: _friendshipService.getAcceptedFriends(
                        currentUserId!,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Bir hata oluştu: ${snapshot.error}'),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'Henüz hiç arkadaşınız yok. Başlamak için kişileri ekleyin!',
                            ),
                          );
                        }

                        final List<UserModel> allUsers = snapshot.data!;
                        final List<UserModel> filteredUsers = allUsers.where((
                          user,
                        ) {
                          final usernameLower =
                              user.username?.toLowerCase() ?? '';
                          return usernameLower.contains(_searchText);
                        }).toList();

                        if (filteredUsers.isEmpty) {
                          return const Center(
                            child: Text(
                              'Aradığınız kriterlere uygun kişi bulunamadı.',
                            ),
                          );
                        }

                        final Map<String, List<UserModel>> groupedUsers =
                            _groupUsers(filteredUsers);
                        final sortedKeys = groupedUsers.keys.toList()..sort();

                        return ListView.builder(
                          itemCount: sortedKeys.length,
                          itemBuilder: (context, index) {
                            String letter = sortedKeys[index];
                            List<UserModel> users = groupedUsers[letter]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Text(
                                    letter,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: cs.secondary,
                                    ),
                                  ),
                                ),
                                ...users.map((user) {
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage:
                                          (user.profilePhotoUrl != null &&
                                              user.profilePhotoUrl!.isNotEmpty)
                                          ? NetworkImage(user.profilePhotoUrl!)
                                          : null,
                                      backgroundColor:
                                          (user.profilePhotoUrl == null ||
                                              user.profilePhotoUrl!.isEmpty)
                                          ? cs.primary
                                          : null,
                                      child:
                                          (user.profilePhotoUrl == null ||
                                              user.profilePhotoUrl!.isEmpty)
                                          ? Text(
                                              user.username![0].toUpperCase(),
                                              style: TextStyle(
                                                color: cs.onPrimary,
                                              ),
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      user.username ?? 'Bilinmeyen Kullanıcı',
                                    ),
                                    subtitle: Text(user.email),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            otherUserId: user.uid,
                                            username: user.username,
                                            profilePhotoUrl:
                                                user.profilePhotoUrl ?? '',
                                            isOnline: user.isOnline,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                              ],
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
