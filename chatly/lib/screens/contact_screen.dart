import 'dart:convert';
import 'package:chatly/models/user_model.dart';
import 'package:chatly/screens/friend_request_screen.dart';
import 'package:chatly/services/friendship_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  String query = '';
  List<UserModel> allContacts = [];
  List<UserModel> filteredContacts = [];
  Map<String, String> friendshipStatus = {};
  final friendshipService = FriendshipService();
  bool _isLoading = true; // <-- YÜKLENME DURUMU İÇİN EKLENDİ

  @override
  void initState() {
    super.initState();
    // Eskileri yerine yeni, birleşik fonksiyonu çağır
    _loadAndFilterContacts();
  }

  // --- YENİ BİRLEŞİK YÜKLEME FONKSİYONU ---
  // Bu fonksiyon, kullanıcıları ve arkadaşlık durumlarını aynı anda çeker,
  // arkadaş olanları listeye hiç eklemeden filtreler ve setState'i sadece bir kez çağırır.
  // Bu sayede listenin titremesi (flicker) sorunu ortadan kalkar.
  Future<void> _loadAndFilterContacts() async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // Kullanıcıları ve arkadaşlıkları aynı anda çek (daha performanslı)
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').get(),
        FirebaseFirestore.instance
            .collection('friendships')
            .where('memberIds', arrayContains: currentUserUid)
            .get(),
      ]);

      final usersSnapshot = results[0] as QuerySnapshot;
      final friendshipsSnapshot = results[1] as QuerySnapshot;

      // 1. Önce arkadaşlık durum haritasını oluştur
      final statusMap = <String, String>{};
      for (var doc in friendshipsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final memberIds = List<String>.from(data['memberIds']);
        final status = data['status'] as String;
        final requesterId = data['requesterId'] as String;

        // Diğer kullanıcının ID'sini bul
        final otherUserId = memberIds.firstWhere((id) => id != currentUserUid);

        if (status == 'accepted') {
          statusMap[otherUserId] = 'friends';
        } else if (status == 'pending') {
          statusMap[otherUserId] = (requesterId == currentUserUid)
              ? 'sent'
              : 'received';
        }
      }

      // 2. Kullanıcı listesini oluştururken "friends" olanları doğrudan filtrele
      final finalContacts = usersSnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .where((user) {
            // Mevcut kullanıcıyı ve zaten arkadaş olanları listeye hiç ekleme
            final isCurrentUser = user.uid == currentUserUid;
            final isFriend = statusMap[user.uid] == 'friends';
            return !isCurrentUser && !isFriend;
          })
          .toList();

      // 3. setState'i SADECE BİR KEZ çağır
      if (mounted) {
        setState(() {
          // Durum haritasını her kullanıcı için ayarla (arkadaş olmayanlar 'none' olacak)
          friendshipStatus = {
            for (var user in finalContacts)
              user.uid: statusMap[user.uid] ?? 'none',
          };
          allContacts = finalContacts;
          filteredContacts = List.from(allContacts);
          _isLoading = false; // Yükleme tamamlandı
        });
      }
    } catch (e) {
      print('Error loading and filtering contacts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Artık _loadContacts ve _loadFriendshipStatuses fonksiyonlarına ihtiyaç yok.

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

  // _cancelFriendRequest, _sendFriendRequest, ve _buildActionButton fonksiyonları aynı kalabilir.
  // ... (Bu fonksiyonlar değişmediği için kısaltıldı)
  void _cancelFriendRequest(UserModel user) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      await friendshipService.declineFriendRequest(currentUser.uid, user.uid);
      setState(() => friendshipStatus[user.uid] = 'none');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('requestCanceled'.trParams({'name': user.username!})),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'cancelRequestFailed'.trParams({'error': e.toString()}),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _sendFriendRequest(UserModel user) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      await friendshipService.sendFriendRequest(
        requesterId: currentUser.uid,
        receiverId: user.uid,
      );
      setState(() => friendshipStatus[user.uid] = 'sent');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('requestSent'.trParams({'name': user.username!})),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('sendRequestFailed'.trParams({'error': e.toString()})),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildActionButton(UserModel user) {
    final status = friendshipStatus[user.uid] ?? 'none';
    switch (status) {
      case 'sent':
        return ElevatedButton(
          onPressed: () => _cancelFriendRequest(user),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('cancel'.tr, style: const TextStyle(color: Colors.white)),
        );
      case 'received':
        return ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FriendRequestScreen(),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'viewRequest'.tr,
            style: const TextStyle(color: Colors.white),
          ),
        );
      case 'friends':
        // Bu durum artık listede görünmeyeceği için teorik olarak gereksiz,
        // ama güvenlik için burada bırakılabilir.
        return const SizedBox.shrink();
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
          child: Text('add'.tr, style: const TextStyle(color: Colors.white)),
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
            // --- HEADER VE ARAMA ÇUBUĞU (DEĞİŞİKLİK YOK) ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20,
              ),
              child: Row(
                children: [
                  Text(
                    'addNewContact'.tr,
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                onChanged: _filterContacts,
                decoration: InputDecoration(
                  hintText: 'searchContactHint'.tr,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: cs.surfaceVariant,
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FriendRequestScreen(),
                      ),
                    ),
                    child: Text(
                      'requests'.tr,
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
            // --- GÜNCELLENEN LİSTE GÖRÜNÜMÜ ---
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2F4156),
                      ),
                    )
                  : (filteredContacts.isEmpty
                        ? Center(child: Text('noContactsFound'.tr))
                        : ListView.builder(
                            itemCount: filteredContacts.length,
                            itemBuilder: (context, index) {
                              final UserModel user = filteredContacts[index];
                              final profilePhotoUrl = user.profilePhotoUrl;
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundImage:
                                      (profilePhotoUrl != null &&
                                          profilePhotoUrl.isNotEmpty)
                                      ? (profilePhotoUrl.startsWith(
                                              'data:image',
                                            )
                                            ? MemoryImage(
                                                base64Decode(
                                                  profilePhotoUrl
                                                      .split(',')
                                                      .last,
                                                ),
                                              )
                                            : NetworkImage(profilePhotoUrl)
                                                  as ImageProvider)
                                      : null,
                                  backgroundColor: Color(0xFF2F4156),
                                  child:
                                      (profilePhotoUrl == null ||
                                          profilePhotoUrl.isEmpty)
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 24,
                                        )
                                      : null,
                                ),
                                title: Text(user.username!),
                                trailing: _buildActionButton(user),
                              );
                            },
                          )),
            ),
          ],
        ),
      ),
    );
  }
}
