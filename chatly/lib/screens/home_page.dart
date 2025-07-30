import 'package:chatly/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'messages_page.dart';
import 'contact_screen.dart';
import 'settings.dart'; // Ayarlar sayfan varsa

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _selectedIndex = 1;
  final UserService _userService = UserService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  final List<Widget> _pages = const [
    ContactScreen(),
    MessagesPage(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateUserStatus(isOnline: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateUserStatus(isOnline: false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final isOnline = state == AppLifecycleState.resumed;
    _updateUserStatus(isOnline: isOnline);
  }

  void _updateUserStatus({required bool isOnline}) {
    if (_userId != null) {
      _userService.updateUserStatus(_userId!, isOnline: isOnline);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                FontAwesomeIcons.users,
                color: _selectedIndex == 0
                    ? Color(0xFF71D7E1)
                    : Color(0xFF2F4156),
                size: 25,
              ),
              onPressed: () {
                setState(() => _selectedIndex = 0);
              },
            ),
            IconButton(
              icon: Icon(
                FontAwesomeIcons.solidMessage,
                color: _selectedIndex == 1
                    ? Color(0xFF71D7E1)
                    : Color(0xFF2F4156),
                size: 25,
              ),
              onPressed: () {
                setState(() => _selectedIndex = 1);
              },
            ),
            IconButton(
              icon: Icon(
                FontAwesomeIcons.gear,
                color: _selectedIndex == 2
                    ? Color(0xFF71D7E1)
                    : Color(0xFF2F4156),
                size: 25,
              ),
              onPressed: () {
                setState(() => _selectedIndex = 2);
              },
            ),
          ],
        ),
      ),
    );
  }
}
