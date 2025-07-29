import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  /// Creates a new user document in Firestore if it doesn't already exist.
  Future<void> createUser(UserModel user) async {
    try {
      // Use the user's 'id' as the document ID.
            final docRef = _usersCollection.doc(user.uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // If the user does not exist, create the document.
        await docRef.set(user.toJson());
                log('User created successfully with ID: ${user.uid}');
      } else {
                log('User with ID ${user.uid} already exists.');
      }
    } catch (e) {
      log('Error creating user: $e');
      rethrow; // Rethrow the error to be handled by the caller.
    }
  }

  /// Fetches a user's profile information by their unique ID.
  Future<UserModel?> getUser(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return UserModel.fromJson(docSnapshot.data() as Map<String, dynamic>);
      }
      log('User not found with ID: $userId');
      return null;
    } catch (e) {
      log('Error fetching user by ID: $e');
      return null;
    }
  }

  /// Gets all users as a stream.
  Stream<List<UserModel>> getUsersStream(String currentUserId) {
    return _usersCollection
        .where('uid', isNotEqualTo: currentUserId) // Exclude the current user
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Updates the online status of a user.
  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    try {
      await _usersCollection.doc(userId).update({'isOnline': isOnline});
      log('Updated online status for user $userId to $isOnline');
    } catch (e) {
      log('Error updating user online status: $e');
      // Depending on the use case, you might want to rethrow the error.
    }
  }
}
