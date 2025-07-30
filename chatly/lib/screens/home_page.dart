import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'messages_page.dart';
import 'contact_screen.dart';
import 'settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;

  final List<Widget> _pages = const [
    ContactScreen(),
    MessagesPage(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.users),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.solidMessage),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.gear),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
