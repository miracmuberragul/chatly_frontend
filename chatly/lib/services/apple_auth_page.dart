import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

String _generateNonce([int length = 32]) {
  final charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final rand = Random.secure();
  return List.generate(
    length,
    (_) => charset[rand.nextInt(charset.length)],
  ).join();
}

String _sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

Future<UserCredential> signInWithApple() async {
  final rawNonce = _generateNonce();
  final nonce = _sha256ofString(rawNonce);

  final appleCredential = await SignInWithApple.getAppleIDCredential(
    scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ],
    nonce: nonce,
  );

  final oauthCredential = OAuthProvider(
    "apple.com",
  ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

  final userCredential = await FirebaseAuth.instance.signInWithCredential(
    oauthCredential,
  );

  // Firestore’a kullanıcı bilgilerini kaydetmek istersen:
  final user = userCredential.user;
  if (user != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'username': appleCredential.givenName ?? 'Apple User',
      'profilePhotoUrl': null,
      'lastSeen': Timestamp.now(),
      'friends': [],
    }, SetOptions(merge: true));
  }

  return userCredential;
}

Future<void> signOutUser() async {
  await FirebaseAuth.instance.signOut();
}
