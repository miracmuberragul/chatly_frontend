import 'dart:convert';

import 'package:chatly/models/user_model.dart';
import 'package:chatly/screens/friend_request_screen.dart';
import 'package:chatly/services/friendship_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // <-- EKLENDİ

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

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  // --- BU BÖLÜMLERDE HİÇBİR MANTIK DEĞİŞİKLİĞİ YOKTUR ---
  void _loadContacts() async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      final contacts = snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .where((user) => user.uid != currentUserUid)
          .toList();
      setState(() {
        allContacts = contacts;
        filteredContacts = List.from(allContacts);
        friendshipStatus = {for (var user in contacts) user.uid: 'none'};
      });
      await _loadFriendshipStatuses(currentUserUid, contacts);
    } catch (e) {
      print('Error loading contacts: $e');
    }
  }

  Future<void> _loadFriendshipStatuses(
    String currentUserUid,
    List<UserModel> contacts,
  ) async {
    try {
      final friendshipsQuery = await FirebaseFirestore.instance
          .collection('friendships')
          .where('memberIds', arrayContains: currentUserUid)
          .get();
      Map<String, String> statusMap = {
        for (var user in contacts) user.uid: 'none',
      };
      for (var doc in friendshipsQuery.docs) {
        final data = doc.data();
        List<dynamic> memberIds = data['memberIds'];
        String status = data['status'];
        String requesterId = data['requesterId'];
        for (String memberId in memberIds) {
          if (memberId != currentUserUid && statusMap.containsKey(memberId)) {
            if (status == 'accepted') {
              statusMap[memberId] = 'friends';
            } else if (status == 'pending') {
              statusMap[memberId] = (requesterId == currentUserUid)
                  ? 'sent'
                  : 'received';
            }
          }
        }
      }
      setState(() => friendshipStatus = statusMap);
    } catch (e) {
      print('Error loading friendship statuses: $e');
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
  // --- MANTIK DEĞİŞİKLİĞİ OLMAYAN BÖLÜM SONU ---

  void _cancelFriendRequest(UserModel user) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      await friendshipService.declineFriendRequest(currentUser.uid, user.uid);
      setState(() => friendshipStatus[user.uid] = 'none');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'requestCanceled'.trParams({'name': user.username!}),
          ), // <-- DEĞİŞTİ
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'cancelRequestFailed'.trParams({'error': e.toString()}),
          ), // <-- DEĞİŞTİ
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
          content: Text(
            'requestSent'.trParams({'name': user.username!}),
          ), // <-- DEĞİŞTİ
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'sendRequestFailed'.trParams({'error': e.toString()}),
          ), // <-- DEĞİŞTİ
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
        return ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'friends'.tr,
            style: const TextStyle(color: Colors.white),
          ),
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20,
              ),
              child: Row(
                children: [
                  Text(
                    'addNewContact'.tr, // <-- DEĞİŞTİ
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
                  hintText: 'searchContactHint'.tr, // <-- DEĞİŞTİ
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
                      'requests'.tr, // <-- DEĞİŞTİ
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
            Expanded(
              child: filteredContacts.isEmpty && allContacts.isNotEmpty
                  ? Center(child: Text('noContactsFound'.tr)) // <-- DEĞİŞTİ
                  : (allContacts.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2F4156),
                            ),
                          )
                        : (() {
                            final visibleContacts = filteredContacts
                                .where(
                                  (user) =>
                                      friendshipStatus[user.uid] != 'friends',
                                )
                                .toList();
                            if (visibleContacts.isEmpty) {
                              return Center(
                                child: Text(
                                  'allUsersAreFriends'.tr, // <-- DEĞİŞTİ
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: visibleContacts.length,
                              itemBuilder: (context, index) {
                                final UserModel user = visibleContacts[index];
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
                                                    as ImageProvider
                                              : NetworkImage(profilePhotoUrl))
                                        : null,
                                    backgroundColor: const Color(0xFF2F4156),
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
                            );
                          })()),
            ),
          ],
        ),
      ),
    );
  }
}
