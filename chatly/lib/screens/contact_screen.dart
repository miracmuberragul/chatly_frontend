import 'package:chatly/screens/friend_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(10.0),
          child: const Text(
            'Add new contact',
            style: TextStyle(
              color: Color(0xFF2F4156),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: Theme(
              data: Theme.of(context).copyWith(primaryColor: Color(0xFF2F4156)),
              child: TextField(
                cursorColor: Color(0xFF2F4156),
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide(
                      color: Colors.grey,
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide(
                      color: Color(0xFF2F4156),
                      width: 2.0,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  focusColor: Color(0xFF2F4156),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FriendRequestScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Requests',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2F4156),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Contact List will be displayed here.',
              style: TextStyle(fontSize: 20, color: Colors.black54),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                FontAwesomeIcons.users,
                color: Color(0xFF71D7E1),
                size: 30,
              ),
              onPressed: () {
                // Navigate to add contact
              },
            ),
            IconButton(
              icon: Icon(
                FontAwesomeIcons.solidMessage,
                color: Color(0xFF2F4156),
                size: 30,
              ),
              onPressed: () {
                // Navigate to chat
              },
            ),
            IconButton(
              icon: Icon(
                FontAwesomeIcons.gear,
                color: Color(0xFF2F4156),
                size: 30,
              ),
              onPressed: () {
                // Navigate to settings
              },
            ),
          ],
        ),
      ),
    );
  }
}
