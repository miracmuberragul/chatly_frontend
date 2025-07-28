import 'package:chatly/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// AuthPage'inizi doğru yoldan import ettiğinizden emin olun.
// Eğer AuthPage, lib/services/auth_page.dart konumundaysa, bu import doğrudur.
import 'package:chatly/services/auth_page.dart';

// Firebase yapılandırma dosyası. Bu dosya, `flutterfire configure` komutuyla otomatik olarak oluşturulur.
// Projenizde yoksa veya güncel değilse bu komutu çalıştırmanız gerekir.
import 'firebase_options.dart';

void main() async {
  // Flutter motorunun widget ağacını başlatmadan önce tüm binding'lerin
  // (örneğin Firebase gibi) doğru şekilde başlatıldığından emin olun.
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i uygulamanızla başlatın.
  // `DefaultFirebaseOptions.currentPlatform` Firebase CLI tarafından oluşturulan
  // platforma özel yapılandırma seçeneklerini kullanır.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Uygulamayı başlatın.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
