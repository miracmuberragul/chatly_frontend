import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'messages_page.dart';
import 'contact_screen.dart';
//import 'settings_screen.dart'; // Ayarlar sayfan varsa

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
    Placeholder(),
  ];

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
                size: 30,
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
                size: 30,
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
                size: 30,
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
