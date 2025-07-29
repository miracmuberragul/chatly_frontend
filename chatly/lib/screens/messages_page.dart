import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'chat_screen.dart'; // ChatScreen dosyanı import etmeyi unutma

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  int _selectedIndex = 1; // Ortadaki ikon (mesaj) aktif olacak

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            //  Başlık ve + Butonu
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20,
              ),
              child: Row(
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add, size: 28),
                    onPressed: () {
                      Navigator.pushNamed(context, '/contacts');
                    },
                  ),
                ],
              ),
            ),

            //  Arama Çubuğu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF2F4156)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFF2F4156),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            //  Mesaj Listesi
            Expanded(
              child: ListView.builder(
                itemCount: 5, // örnek kullanıcı sayısı
                itemBuilder: (context, index) {
                  final userName = 'Kullanıcı $index';

                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF2F4156),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(userName),
                    subtitle: const Text('Son mesaj...'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            userName: userName,
                            isOnline:
                                index % 2 == 0, // demo için online/offline
                            profileImageUrl: "https://via.placeholder.com/150",
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      //  Alt Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.users, color: Color(0xFF2F4156)),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.solidMessage, color: Color(0xFF71D7E1)),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.gear, color: Color(0xFF2F4156)),
            label: '',
          ),
        ],
      ),
    );
  }
}
