import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friendship_model.dart';
import '../models/user_model.dart';

class FriendshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _friendshipCollection = 'friendships';
  final String _userCollection = 'users';

  /// Creates a new chat between the current user and a friend if it doesn't already exist.
  Future<String> createChatWithFriend(String currentUserId, String friendId) async {
    List<String> ids = [currentUserId, friendId];
    ids.sort();
    String chatId = ids.join('_');
    final chatDocRef = _firestore.collection('chats').doc(chatId);

    try {
      final chatSnapshot = await chatDocRef.get();
      if (chatSnapshot.exists) {
        log('Chat already exists: $chatId');
        return chatId;
      }
      await chatDocRef.set({
        'members': [currentUserId, friendId],
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
      log('New chat created with ID: $chatId');
      return chatId;
    } catch (e) {
      log('Error creating chat: $e');
      rethrow;
    }
  }

  // Arkadaşlık isteği gönder
  Future<void> sendFriendRequest(String requesterId, String receiverId) async {
    try {
      if (requesterId == receiverId) {
        throw Exception('Cannot send friend request to yourself.');
      }
      final existingRequest = await _firestore
          .collection(_friendshipCollection)
          .where('requesterId', isEqualTo: requesterId)
          .where('receiverId', isEqualTo: receiverId)
          .limit(1)
          .get();
      final existingRequestReverse = await _firestore
          .collection(_friendshipCollection)
          .where('requesterId', isEqualTo: receiverId)
          .where('receiverId', isEqualTo: requesterId)
          .limit(1)
          .get();
      if (existingRequest.docs.isNotEmpty || existingRequestReverse.docs.isNotEmpty) {
        throw Exception('Friend request already exists or you are already friends.');
      }
      final docRef = _firestore.collection(_friendshipCollection).doc();
      final friendship = FriendshipModel(
        id: docRef.id,
        requesterId: requesterId,
        receiverId: receiverId,
        status: 'pending',
        createdAt: Timestamp.now(),
      );
      await docRef.set(friendship.toJson());
    } catch (e) {
      log('Error sending friend request: $e');
      rethrow;
    }
  }

  // Arkadaşlık isteğini kabul et
  Future<void> acceptFriendRequest(String friendshipId) async {
    try {
      await _firestore
          .collection(_friendshipCollection)
          .doc(friendshipId)
          .update({'status': 'accepted', 'updatedAt': Timestamp.now()});
    } catch (e) {
      log('Error accepting friend request: $e');
      rethrow;
    }
  }

  // Arkadaşlık isteğini reddet
  Future<void> rejectFriendRequest(String friendshipId) async {
    try {
      await _firestore
          .collection(_friendshipCollection)
          .doc(friendshipId)
          .update({'status': 'rejected', 'updatedAt': Timestamp.now()});
    } catch (e) {
      log('Error rejecting friend request: $e');
      rethrow;
    }
  }

  // Arkadaşlığı sil/iptal et
  Future<void> deleteFriendship(String friendshipId) async {
    try {
      await _firestore.collection(_friendshipCollection).doc(friendshipId).delete();
    } catch (e) {
      log('Error deleting friendship: $e');
      rethrow;
    }
  }

  // Bir kullanıcının bekleyen arkadaşlık isteklerini alıcı olarak getir
  Stream<List<FriendshipModel>> getPendingRequestsForUser(String userId) {
    return _firestore
        .collection(_friendshipCollection)
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FriendshipModel.fromJson(doc.data())).toList());
  }

  // Bir kullanıcının gönderdiği bekleyen arkadaşlık isteklerini getir
  Stream<List<FriendshipModel>> getSentPendingRequestsByUser(String userId) {
    return _firestore
        .collection(_friendshipCollection)
        .where('requesterId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FriendshipModel.fromJson(doc.data())).toList());
  }

  // Bir kullanıcının kabul edilmiş arkadaşlarını getir
  Stream<List<UserModel>> getAcceptedFriendsOfUser(String userId) {
    return _firestore
        .collection(_friendshipCollection)
        .where('status', isEqualTo: 'accepted')
        .where(Filter.or(Filter('requesterId', isEqualTo: userId), Filter('receiverId', isEqualTo: userId)))
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return [];
      final friendUids = <String>{};
      for (var doc in snapshot.docs) {
        final friendship = FriendshipModel.fromJson(doc.data());
        if (friendship.requesterId == userId) {
          friendUids.add(friendship.receiverId);
        } else {
          friendUids.add(friendship.requesterId);
        }
      }
      if (friendUids.isEmpty) return [];
      final friendsQuerySnapshot = await _firestore
          .collection(_userCollection)
          .where(FieldPath.documentId, whereIn: friendUids.toList())
          .get();
      return friendsQuerySnapshot.docs.map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
    });
  }
}
