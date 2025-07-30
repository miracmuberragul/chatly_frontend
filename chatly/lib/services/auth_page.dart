import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthPage {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userDoc = _firestore.collection('users').doc(user.uid);
        final snapshot = await userDoc.get();

        if (!snapshot.exists) {
          await userDoc.set({
            'uid': user.uid,
            'name': user.displayName,
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
            'profilePhotoUrl': user.photoURL,
          });
        }

        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(context, 'Sign-in error: ${e.message}');
    } catch (e) {
      _showErrorSnackBar(context, 'An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<void> signUpWithEmailPassword(
    BuildContext context,
    String email,
    String password,
    String username,
  ) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      final User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'username': username,
          'createdAt': FieldValue.serverTimestamp(),
          'profilePhotoUrl': null,
        });

        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(context, 'Sign-up error: ${e.message}');
    } catch (e) {
      _showErrorSnackBar(
        context,
        'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  Future<void> signInWithEmailPassword(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(context, 'Sign-in error: ${e.message}');
    } catch (e) {
      _showErrorSnackBar(context, 'An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      debugPrint('User successfully signed out.');
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/welcome',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Sign-out error: $e');
      _showErrorSnackBar(context, 'Error signing out.');
    }
  }

  void _showErrorSnackBar(BuildContext context, String? message) {
    if (context.mounted && message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}
