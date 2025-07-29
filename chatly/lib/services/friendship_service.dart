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

  /// Sends a friend request from the requester to the receiver.
  Future<void> sendFriendRequest(String requesterId, String receiverId) async {
    if (requesterId == receiverId) return;
    try {
      // Use a consistent ID format for requests to prevent duplicates.
      List<String> ids = [requesterId, receiverId];
      ids.sort();
      final friendshipId = ids.join('_');

      final docRef = _firestore
          .collection(_friendshipCollection)
          .doc(friendshipId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        log('Friendship or request already exists: $friendshipId');
        return; // Avoid creating a duplicate request.
      }

      await docRef.set({
        'id': friendshipId,
        'requesterId': requesterId, // Keep track of who sent the request
        'receiverId': receiverId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      });
      log('Friend request sent from $requesterId to $receiverId');
    } catch (e) {
      log('Error sending friend request: $e');
      throw Exception('Failed to send friend request.');
    }
  }

  /// Accepts a pending friend request.
  Future<void> acceptFriendRequest(String friendshipId) async {
    try {
      await _firestore
          .collection(_friendshipCollection)
          .doc(friendshipId)
          .update({
            'status': 'accepted',
            'updatedAt': FieldValue.serverTimestamp(),
          });
      log('Friend request accepted: $friendshipId');
    } catch (e) {
      log('Error accepting friend request: $e');
      throw Exception('Failed to accept friend request.');
    }
  }

  /// Rejects a pending friend request by deleting it.
  Future<void> rejectFriendRequest(String friendshipId) async {
    try {
      await _firestore
          .collection(_friendshipCollection)
          .doc(friendshipId)
          .delete();
      log('Friend request rejected and deleted: $friendshipId');
    } catch (e) {
      log('Error rejecting friend request: $e');
      throw Exception('Failed to reject friend request.');
    }
  }

  /// Deletes an existing friendship.
  Future<void> deleteFriendship(String friendshipId) async {
    try {
      await _firestore
          .collection(_friendshipCollection)
          .doc(friendshipId)
          .delete();
      log('Friendship deleted: $friendshipId');
    } catch (e) {
      log('Error deleting friendship: $e');
      throw Exception('Failed to delete friendship.');
    }
  }

  /// Streams pending friend requests for a specific user (where they are the receiver).
  Stream<List<FriendshipModel>> getPendingFriendRequests(String userId) {
    return _firestore
        .collection(_friendshipCollection)
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FriendshipModel.fromJson(doc.data()))
              .toList();
        });
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
                (doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>),
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
