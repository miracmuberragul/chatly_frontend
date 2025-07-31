import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthPage {
  String? userId;

  // Hata aldığınız yer burasıydı. _googleSignIn'ı sınıfın bir özelliği olarak tanımlamalısınız.
  // Bu satırı AuthPage sınıfının hemen içine, diğer özelliklerin (userId gibi) yanına ekleyin.
  final GoogleSignIn _googleSignIn =
      GoogleSignIn(); // <-- Bu satırın yeri önemli!

  AuthPage() {
    userId = null;
  }

  /// Google ile oturum açma işlemini gerçekleştirir.
  /// Başarılı olursa Firebase'e kaydeder veya mevcut kullanıcıyı doğrular.
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint(
          'Google oturum açma işlemi kullanıcı tarafından iptal edildi.',
        );
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        userId = user.uid;

        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final snapshot = await userDoc.get();

        if (!snapshot.exists) {
          // Kullanıcı Firestore'a daha önce kaydedilmediyse (YENİ KULLANICI)
          await userDoc.set({
            'uid': user.uid,
            'name': user.displayName,
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
            'username': user.email?.split('@')[0] ?? 'user_${user.uid}',
          });
          debugPrint('Yeni kullanıcı Firestore\'a kaydedildi: ${user.email}');
        } else {
          // Kullanıcı zaten Firestore'da mevcut (MEVCUT KULLANICI GİRİŞİ)
          debugPrint('Mevcut kullanıcı Google ile giriş yaptı: ${user.email}');
        }

        // --- ÇÖZÜM: BAŞARILI GİRİŞ SONRASI YÖNLENDİRME ---
        // Hem yeni kullanıcı hem de mevcut kullanıcı için, işlem başarılı olduğunda
        // ana sayfaya yönlendir.
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
        // ----------------------------------------------------
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Kimlik Doğrulama Hatası: ${e.code} - ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Oturum açma hatası: ${e.message ?? "Bir hata oluştu."}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      log('Google Oturum Açma Genel Hatası: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beklenmedik bir hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// E-posta ve şifre ile yeni bir kullanıcı kaydı oluşturur.
  Future<void> signUpWithEmailPassword(
    BuildContext context,
    String email,
    String password,
    String username,
  ) async {
    try {
      // E-posta ve şifre ile Firebase'de yeni bir kullanıcı oluştur.
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user; // Oluşturulan kullanıcıyı al.
      userId = user?.uid; // userId'yi ata (null güvenli atama).

      if (user != null) {
        // Kullanıcı Firestore'a kaydedilmediyse kaydet.
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'username': username, // Kullanıcı adı
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('E-posta ile yeni kullanıcı kaydoldu: ${user.email}');

        // Başarılı kayıttan sonra '/home' sayfasına yönlendir.
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      // Firebase kimlik doğrulama hatalarını yakala.
      debugPrint(
        'Firebase Kimlik Doğrulama Hatası (Kayıt): ${e.code} - ${e.message}',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt hatası: ${e.message ?? "Bir hata oluştu."}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Diğer genel hataları yakala.
      debugPrint('Genel Kayıt Hatası: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beklenmedik bir hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// E-posta ve şifre ile mevcut bir kullanıcının oturumunu açar.
  Future<void> signInWithEmailPassword(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      // E-posta ve şifre ile Firebase'de oturum aç.
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      userId = userCredential.user?.uid; // userId'yi ata.
      debugPrint('Kullanıcı e-posta ile oturum açtı: $email');

      // Başarılı oturum açmadan sonra '/home' sayfasına yönlendir.
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      // Firebase kimlik doğrulama hatalarını yakala.
      debugPrint(
        'Firebase Kimlik Doğrulama Hatası (Giriş): ${e.code} - ${e.message}',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giriş hatası: ${e.message ?? "Bir hata oluştu."}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Diğer genel hataları yakala.
      debugPrint('Genel Giriş Hatası: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beklenmedik bir hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Mevcut kullanıcının oturumunu kapatır (hem Google hem Firebase).
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // _googleSignIn artık tanımlı
      await FirebaseAuth.instance.signOut();
      userId = null;
      debugPrint('Kullanıcı başarıyla oturumu kapattı.');
    } catch (e) {
      debugPrint('Oturum kapatma hatası: $e');
    }
  }
}
