import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

import 'package:chatly/screens/splash_screen.dart';
import 'package:chatly/screens/home_page.dart';
import 'package:chatly/screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const Bootstrap());
}

class Bootstrap extends StatelessWidget {
  const Bootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThemeController>(
      future: ThemeController.init(),
      builder: (context, snap) {
        final controller = snap.data ?? ThemeController(ThemeMode.system);
        return ChangeNotifierProvider<ThemeController>.value(
          value: controller,
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
    final theme = context.watch<ThemeController>();
    // Debug: MyApp her rebuild olduğunda hangi mode’da?
    debugPrint('MyApp.build -> themeMode: ${theme.mode}');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chatly',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: context.watch<ThemeController>().mode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomePage(),
        '/auth': (context) => const AuthScreen(),
      },
    );
  }
}
