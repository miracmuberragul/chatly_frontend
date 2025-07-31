// lib/main.dart (Sadece Dil için SharedPreferences Kullanılan Hali)

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- EKLENDİ

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'l10n/translations.dart';
import 'screens/splash_screen.dart';
import 'screens/home_page.dart';
import 'screens/auth_screen.dart';

void main() async {
  // Platform kanallarının hazır olmasını sağla.
  WidgetsFlutterBinding.ensureInitialized();

  // Asenkron servisleri başlat.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const Bootstrap());
}

class Bootstrap extends StatelessWidget {
  const Bootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    // ThemeController'ı Provider ile sağlamaya devam ediyoruz. Bu kısım doğru.
    return FutureBuilder<ThemeController>(
      future:
          ThemeController.init(), // Bu metodun SharedPreferences kullandığını varsayıyorum.
      builder: (context, themeSnapshot) {
        if (!themeSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final themeController = themeSnapshot.data!;
        return ChangeNotifierProvider<ThemeController>.value(
          value: themeController,
          child: const MyApp(),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Tema yönetimi için Provider'ı dinlemeye devam et.
    final themeController = context.watch<ThemeController>();

    // Dili okumak için FutureBuilder kullanalım. Bu, en güvenli yöntemdir.
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, prefsSnapshot) {
        // SharedPreferences yüklenene kadar bekleme ekranı göster.
        if (!prefsSnapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        // SharedPreferences yüklendiğinde dil ayarını oku.
        final prefs = prefsSnapshot.data!;
        final storedLanguageCode = prefs.getString('locale');

        // Kaydedilmiş bir dil varsa onu, yoksa cihaz dilini veya İngilizce'yi kullan.
        final Locale initialLocale = storedLanguageCode != null
            ? Locale(storedLanguageCode)
            : Get.deviceLocale ?? const Locale('en', 'US');

        // GetMaterialApp'i bu bilgilerle oluştur.
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Chatly',

          // Tema Ayarları (Provider'dan geliyor, değişmedi)
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.mode,

          // Dil Ayarları (SharedPreferences ve GetX ile)
          translations: AppTranslations(),
          locale: initialLocale,
          fallbackLocale: const Locale('en', 'US'),

          // Rota Ayarları
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/home': (context) => const HomePage(),
            '/auth': (context) => const AuthScreen(),
          },
        );
      },
    );
  }
}
