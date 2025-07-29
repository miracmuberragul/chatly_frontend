import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthPage {
  late final String userId;

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn()
          .signIn(); //google seçtik
      if (googleUser == null) {
        // User canceled the sign-in, no action needed
        return;
      }

      final googleAuth = await googleUser.authentication;
      //kimlik bilgileri alınıyor ve firebasele kimlik doğrulaması yapılıyor
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final snapshot = await userDoc.get();

        // Add user to Firestore if not already saved
        if (!snapshot.exists) {
          await userDoc.set({
            'uid': user.uid,
            'name': user.displayName,
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
          });
          debugPrint('New user saved to Firestore: ${user.email}');
        } else {
          debugPrint('User already exists in Firestore: ${user.email}');
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sign-in error: ${e.message ?? "An error occurred."}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Google Sign-In General Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Email/Password Sign-Up (üye kayıt)
  Future<void> signUpWithEmailPassword(
    BuildContext context,
    String email,
    String password,
    String username,
  ) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;
      userId = user?.uid ?? '';
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'username': username,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('New user signed up with email: ${user.email}');

        // ✅ Yönlendirme
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/messages');
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error (Sign Up): ${e.code} - ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sign-up error: ${e.message ?? "An error occurred."}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('General Sign-Up Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Email/Password Sign-In(giriş)
  Future<void> signInWithEmailPassword(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('User signed in with email: $email');

      // ✅ Yönlendirme
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/messages');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error (Sign In): ${e.code} - ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sign-in error: ${e.message ?? "An error occurred."}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('General Sign-In Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      debugPrint('User successfully signed out.');
    } catch (e) {
      debugPrint('Sign-out error: $e');
    }
  }
}
