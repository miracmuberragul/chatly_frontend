// user_service.dart
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication için eklendi

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Firebase Auth instance'ı eklendi

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
  Future<UserModel?> getUserById(String userId) async {
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
  Stream<List<UserModel>> getUsersStream() {
    return _usersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Updates the user's profile photo URL.
  /// If newPhotoUrl is null, it removes the existing profile photo URL.
  Future<void> updateUserProfilePhoto(
    String userId,
    String? newPhotoUrl,
  ) async {
    try {
      await _usersCollection.doc(userId).update({
        'profilePhotoUrl': newPhotoUrl,
      });
      log('Profile photo updated successfully for user ID: $userId');
    } catch (e) {
      log('Error updating profile photo: $e');
      rethrow;
    }
  }

  /// Updates the user's username.
  Future<void> updateUsername(String userId, String newUsername) async {
    try {
      await _usersCollection.doc(userId).update({'username': newUsername});
      log('Username updated successfully for user ID: $userId');
    } catch (e) {
      log('Error updating username: $e');
      rethrow;
    }
  }

  /// Changes the user's password using Firebase Authentication.
  /// This requires the user to be recently authenticated.
  Future<void> changePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        log('Password changed successfully for user: ${user.uid}');
      } else {
        log('No authenticated user found to change password.');
        throw Exception('User not authenticated.');
      }
    } catch (e) {
      log('Error changing password: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      log('User signed out successfully.');
    } catch (e) {
      log('Error signing out: $e');
      rethrow; // Hatanın UI katmanında yakalanabilmesi için yeniden fırlat
    }
  }

  /// Updates the user's online status and last seen timestamp.
  Future<void> updateUserStatus(String userId, {required bool isOnline}) async {
    try {
      final Map<String, dynamic> updateData = {
        'isOnline': isOnline,
      };
      if (!isOnline) {
        updateData['lastSeen'] = FieldValue.serverTimestamp();
      }

      await _usersCollection.doc(userId).update(updateData);
      log('User status updated for user ID: $userId. Online: $isOnline');
    } catch (e) {
      log('Error updating user status: $e');
      rethrow;
    }
  }
}
