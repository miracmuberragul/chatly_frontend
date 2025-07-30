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

  /// Kullanıcının parolasını Firebase Authentication kullanarak değiştirir.
  /// Bu işlem, kullanıcının yakın zamanda kimlik doğrulaması yapılmasını gerektirir.
  ///
  /// [oldPassword]: Kullanıcının mevcut parolası.
  /// [newPassword]: Kullanıcının ayarlamak istediği yeni parola.
  /// [email]: Kullanıcının e-posta adresi (yeniden kimlik doğrulama için gerekli).
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String email,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) {
      log('Parola değiştirmek için kimliği doğrulanmış kullanıcı bulunamadı.');
      throw FirebaseAuthException(
        code: 'user-not-authenticated',
        message: 'Parola değiştirmek için oturum açmış bir kullanıcı olmalı.',
      );
    }

    try {
      // Kullanıcıyı eski parolasıyla yeniden doğrula
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);
      log('Kullanıcı başarıyla yeniden doğrulandı.');

      // Yeniden doğrulama başarılı olursa, parolayı güncelle
      await user.updatePassword(newPassword);
      log('Parola başarıyla değiştirildi: ${user.uid}');
    } on FirebaseAuthException catch (e) {
      log(
        'Parola değiştirme hatası (FirebaseAuthException): ${e.code} - ${e.message}',
      );
      // Spesifik Firebase hatalarını daha anlamlı mesajlarla fırlat
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw FirebaseAuthException(
          code: 'wrong-password',
          message: 'Yanlış eski parola.',
        );
      } else if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        throw FirebaseAuthException(
          code: 'invalid-user',
          message: 'Yeniden doğrulama için geçersiz kullanıcı veya e-posta.',
        );
      } else if (e.code == 'requires-recent-login') {
        throw FirebaseAuthException(
          code: 'requires-recent-login',
          message:
              'Güvenlik nedeniyle, lütfen yakın zamanda tekrar giriş yapın ve tekrar deneyin.',
        );
      } else {
        throw FirebaseAuthException(
          code: e.code,
          message: 'Parola güncellenirken bir hata oluştu: ${e.message}',
        );
      }
    } catch (e) {
      log('Parola değiştirme sırasında bilinmeyen bir hata oluştu: $e');
      throw Exception('Parola değiştirilirken bilinmeyen bir hata oluştu: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      log('Kullanıcı başarıyla çıkış yaptı.');
    } catch (e) {
      log('Çıkış yaparken hata oluştu: $e');
      rethrow; // Hatanın UI katmanında yakalanabilmesi için yeniden fırlat
    }
  }

  /// Updates the user's online status and last seen timestamp.
  Future<void> updateUserStatus(String userId, {required bool isOnline}) async {
    try {
      final Map<String, dynamic> updateData = {'isOnline': isOnline};
      if (!isOnline) {
        updateData['lastSeen'] = FieldValue.serverTimestamp();
      }

      await _usersCollection.doc(userId).update(updateData);
      log('Kullanıcı durumu güncellendi: $userId. Çevrimiçi: $isOnline');
    } catch (e) {
      log('Kullanıcı durumu güncellenirken hata oluştu: $e');
      rethrow;
    }
  }
}
