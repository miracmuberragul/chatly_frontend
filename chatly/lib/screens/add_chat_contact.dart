import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart'; // <-- EKLENDİ

import '../models/user_model.dart';
import '../services/friendship_service.dart';
import 'chat_screen.dart';

class AddChatContactPage extends StatefulWidget {
  const AddChatContactPage({super.key});

  @override
  State<AddChatContactPage> createState() => _AddChatContactPageState();
}

class _AddChatContactPageState extends State<AddChatContactPage> {
  final FriendshipService _friendshipService = FriendshipService();
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchText = _searchController.text.toLowerCase();
        });
      }
    });
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
        title: Text('contactsTitle'.tr), // <-- DEĞİŞTİ
        centerTitle: true,
        elevation: 0,
        // Geri butonu artık GetX ile yönetiliyor.
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onBackground),
          onPressed: () => Get.back(),
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
                  hintText: 'searchContactsHint'.tr, // <-- DEĞİŞTİ
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: cs.surfaceVariant,
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
                  ? Center(child: Text('userNotLoggedIn'.tr)) // <-- DEĞİŞTİ
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
                          // Parametreli çeviri
                          return Center(
                            child: Text(
                              'errorOccurred'.trParams({
                                // <-- DEĞİŞTİ
                                'error': snapshot.error.toString(),
                              }),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text('noFriendsYet'.tr),
                          ); // <-- DEĞİŞTİ
                        }

                        final List<UserModel> allUsers = snapshot.data!;
                        final List<UserModel> filteredUsers = allUsers
                            .where(
                              (user) => (user.username?.toLowerCase() ?? '')
                                  .contains(_searchText),
                            )
                            .toList();

                        if (filteredUsers.isEmpty) {
                          return Center(
                            child: Text('noContactsFound'.tr),
                          ); // <-- DEĞİŞTİ
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
                                    leading: UserAvatar(
                                      user: user,
                                    ), // <-- YENİ WIDGET
                                    title: Text(
                                      user.username ?? 'unknownUser'.tr,
                                    ), // <-- DEĞİŞTİ
                                    subtitle: Text(user.email),
                                    onTap: () {
                                      // GetX ile navigasyon daha temiz
                                      Get.to(
                                        () => ChatScreen(
                                          // <-- DEĞİŞTİ
                                          otherUserId: user.uid,
                                          username: user.username,
                                          profilePhotoUrl:
                                              user.profilePhotoUrl ?? '',
                                          isOnline: user.isOnline,
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

// YENİ YARDIMCI WIDGET: Profil fotoğrafını gösterme mantığını basitleştirir.
class UserAvatar extends StatelessWidget {
  final UserModel user;
  const UserAvatar({super.key, required this.user});

  ImageProvider _getImageProvider() {
    final photoUrl = user.profilePhotoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      // Base64 formatındaki Data URI'ını işle
      if (photoUrl.startsWith('data:image')) {
        try {
          return MemoryImage(base64Decode(photoUrl.split(',').last));
        } catch (e) {
          debugPrint("Base64 Decode Error: $e");
        }
      }
      // Normal bir URL ise NetworkImage kullan
      else if (photoUrl.startsWith('http')) {
        return NetworkImage(photoUrl);
      }
    }
    // Hiçbir resim yoksa null döndür, bu durumda arka plan rengi ve baş harf gösterilecek.
    return const AssetImage('assets/images/logo.png'); // Veya null döndürün
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final imageProvider = _getImageProvider();

    return CircleAvatar(
      backgroundImage: imageProvider,
      backgroundColor: cs.primary, // Resim yoksa gösterilecek renk
      child:
          (imageProvider
              is AssetImage) // Eğer resim yoksa veya yüklenemediyse baş harfi göster
          ? Text(
              user.username?.isNotEmpty == true
                  ? user.username![0].toUpperCase()
                  : '?',
              style: TextStyle(color: cs.onPrimary),
            )
          : null,
    );
  }
}
