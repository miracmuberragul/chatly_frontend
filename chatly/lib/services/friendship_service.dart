import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friendship_model.dart';
import '../models/user_model.dart';

class FriendshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _friendshipCollection = 'friendships';
  final String _userCollection = 'users';

  /// Creates a unique chat document for two users if it doesn't already exist.
  Future<String> createChatWithFriend(
    String currentUserId,
    String friendId,
  ) async {
    List<String> ids = [currentUserId, friendId];
    ids.sort();
    String chatId = ids.join('_');

    final chatDocRef = _firestore.collection('chats').doc(chatId);
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
  }

  Future<void> sendFriendRequest({
    required String requesterId,
    required String receiverId,
  }) async {
    try {
      final friendshipDoc = {
        'requesterId': requesterId,
        'receiverId': receiverId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'memberIds': [requesterId, receiverId],
      };
      await _firestore.collection(_friendshipCollection).add(friendshipDoc);
    } catch (e) {
      log('Error sending friend request: $e');
      rethrow;
    }
  }

  Stream<List<QueryDocumentSnapshot>> getFriendRequests(String userId) {
    return _firestore
        .collection(_friendshipCollection)
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<void> updateFriendshipStatus({
    required String docId,
    required String status,
  }) async {
    try {
      await _firestore.collection(_friendshipCollection).doc(docId).update({'status': status});
    } catch (e) {
      log('Error updating friendship status: $e');
      rethrow;
    }
  }

  Future<void> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_friendshipCollection)
          .where('memberIds', whereIn: [
        [userId, friendId],
        [friendId, userId]
      ]).get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      log('Error removing friend: $e');
      rethrow;
    }
  }

  Stream<bool> areFriends(String userId1, String userId2) {
    return _firestore
        .collection(_friendshipCollection)
        .where('status', isEqualTo: 'accepted')
        .where('memberIds', whereIn: [
          [userId1, userId2],
          [userId2, userId1]
        ])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.isNotEmpty;
        });
  }

  Future<void> acceptFriendRequest(String requesterId, String receiverId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_friendshipCollection)
          .where('requesterId', isEqualTo: requesterId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await _firestore.collection(_friendshipCollection).doc(docId).update({'status': 'accepted'});
      }
    } catch (e) {
      log('Error accepting friend request: $e');
      rethrow;
    }
  }

  Future<void> declineFriendRequest(String requesterId, String receiverId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_friendshipCollection)
          .where('requesterId', isEqualTo: requesterId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await _firestore.collection(_friendshipCollection).doc(docId).delete();
      }
    } catch (e) {
      log('Error declining friend request: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> getIncomingPendingFriendRequestsAsUsers(
    String currentUserId,
  ) async {
    try {
      final friendRequestSnapshot = await _firestore
          .collection(_friendshipCollection)
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (friendRequestSnapshot.docs.isEmpty) {
        return [];
      }

      final requesterIds = friendRequestSnapshot.docs
          .map((doc) => doc.data()['requesterId'] as String)
          .toList();

      final userQuerySnapshot = await _firestore
          .collection(_userCollection)
          .where(FieldPath.documentId, whereIn: requesterIds)
          .get();
      return userQuerySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      log('Error fetching incoming friend requests as users: $e');
      return [];
    }
  }

  /// Streams accepted friends for a specific user.
  Stream<List<UserModel>> getAcceptedFriends(String userId) {
    return _firestore
        .collection(_friendshipCollection)
        .where('status', isEqualTo: 'accepted')
        .where(
          Filter.or(
            Filter('requesterId', isEqualTo: userId),
            Filter('receiverId', isEqualTo: userId),
          ),
        )
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

          // Fetch user profiles for all friends in a single query.
          final friendsQuerySnapshot = await _firestore
              .collection(_userCollection)
              .where(FieldPath.documentId, whereIn: friendUids.toList())
              .get();

          return friendsQuerySnapshot.docs
              .map(
                (doc) => UserModel.fromJson(doc.data()),
              )
              .toList();
        });
  }

  // Tüm arkadaşlıkları listele (filtre yok)
  Stream<List<FriendshipModel>> getAllFriendships() {
    return _firestore
        .collection(_friendshipCollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendshipModel.fromJson(doc.data()))
              .toList(),
        );
  }
}
