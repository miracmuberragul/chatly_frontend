import 'package:chatly/models/user_model.dart';
import 'package:chatly/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore'a direkt erişim için kalsın
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication'dan UID almak için
import '../models/user_model.dart'; // UserModel'e ihtiyacımız var.
import '../services/friendship_service.dart'; // FriendshipService'e ihtiyacımız var.
import '../services/user_service.dart'; // Tüm kullanıcıları almak için UserService'e ihtiyacımız var.

class AddChatContactPage extends StatefulWidget {
  const AddChatContactPage({super.key});

  @override
  State<AddChatContactPage> createState() => _AddChatContactPageState();
}

class _AddChatContactPageState extends State<AddChatContactPage> {
  final FriendshipService _friendshipService = FriendshipService();
  final UserService _userService = UserService(); // UserService'i de ekliyoruz
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  // Mevcut kullanıcının ID'si
  // FirebaseAuth.instance.currentUser!.uid ile gerçek kullanıcı ID'sini alıyoruz.
  // Uygulama başlamadan önce Firebase'in initialize edildiğinden emin olun.
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });

    // currentUserId null ise kullanıcıyı oturum açmaya yönlendirme gibi bir mantık ekleyebilirsiniz.
    if (currentUserId == null) {
      // Örneğin: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
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

  // Gelen kullanıcı listesini baş harflerine göre gruplayan fonksiyon.
  Map<String, List<UserModel>> _groupUsers(List<UserModel> users) {
    final Map<String, List<UserModel>> grouped = {};

    for (var user in users) {
      if (user.username != null && user.username!.isNotEmpty) {
        final String firstLetter = user.username![0].toUpperCase();
        if (grouped[firstLetter] == null) {
          grouped[firstLetter] = [];
        }
        grouped[firstLetter]!.add(user);
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kişiler'),
        centerTitle: true,
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ?? Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color ?? Colors.black,
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
                  hintText: 'Kişi Ara...',
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
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Kişi Listesi için StreamBuilder kullanımı
            Expanded(
              child: currentUserId == null
                  ? const Center(
                      child: Text(
                        "Oturum açmış kullanıcı bulunamadı. Lütfen giriş yapın.",
                      ),
                    )
                  : StreamBuilder<List<UserModel>>(
                      // Buradaki stream'i hangi kullanıcıları göstermek istediğinize göre değiştirebilirsiniz.
                      // Eğer tüm kullanıcıları gösterip arkadaşlık isteği gönderme mantığı ise:
                      // stream: _userService.getUsersStream(),
                      // Eğer sadece kabul edilmiş arkadaşları göstermek ise (mevcut mantık):
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

                        // Veri başarıyla geldiyse:
                        final List<UserModel> allUsers = snapshot.data!;
                        // Arama metnine göre filtreleme
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
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ),
                                ...users.map(
                                  (user) => ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage:
                                          user.profilePhotoUrl != null &&
                                              user.profilePhotoUrl!.isNotEmpty
                                          ? NetworkImage(user.profilePhotoUrl!)
                                          : null,
                                      child:
                                          user.profilePhotoUrl == null ||
                                              user.profilePhotoUrl!.isEmpty
                                          ? Text(
                                              user.username![0].toUpperCase(),
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      user.username ?? 'Bilinmeyen Kullanıcı',
                                    ),
                                    subtitle: Text(user.email),
                                    onTap: () {
                                      // TODO: Buraya tıklayınca sohbet ekranına gitme veya profilini görüntüleme mantığı eklenebilir.
                                      // Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(contact: user)));
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${user.username} ile sohbet başlatıldı!',
                                          ),
                                        ),
                                      );
                                    },
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.chat_bubble_outline,
                                      ),
                                      onPressed: () {
                                        // TODO: Buraya sohbet başlatma veya başka bir eylem eklenebilir
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${user.username} ile sohbet başlatıldı!',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ), // Ayırıcı
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
