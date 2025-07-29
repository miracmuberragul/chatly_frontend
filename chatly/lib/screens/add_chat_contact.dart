import 'package:flutter/material.dart';

//  model class
class ChatUser {
  final String name;
  const ChatUser({required this.name});
}

class AddChatContactPage extends StatelessWidget {
  const AddChatContactPage({super.key});

  //  veri (database gelene kadar kullanılacak)
  final Map<String, List<ChatUser>> groupedUsers = const {
    'A': [ChatUser(name: 'AHMET'), ChatUser(name: 'AHMET2')],
    'B': [ChatUser(name: 'BETÜL')],
    'C': [ChatUser(name: 'CELİLE')],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            //  Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            //  Kişi Listesi
            Expanded(
              child: ListView.builder(
                itemCount: groupedUsers.length,
                itemBuilder: (context, index) {
                  String letter = groupedUsers.keys.elementAt(index);
                  List<ChatUser> users = groupedUsers[letter]!;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          letter,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...users.map(
                          (user) => Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(user.name),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
