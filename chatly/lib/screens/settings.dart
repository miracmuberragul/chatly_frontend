import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import '../services/user_service.dart'; // Import your UserService
import '../models/user_model.dart'; // Import your UserModell

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  File? _imageFile;
  String? _profilePhotoUrl;
  final UserService _userService = UserService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  @override
  void initState() {
    super.initState();
    _initializeFirebaseAndLoadUserData();
  }

  Future<void> _initializeFirebaseAndLoadUserData() async {
    await Firebase.initializeApp();
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser != null) {
      final userModel = await _userService.getUserById(currentUser!.uid);
      if (userModel != null) {
        setState(() {
          _usernameController.text = userModel.username!;
          _emailController.text = currentUser!.email ?? '';
          _profilePhotoUrl = userModel.profilePhotoUrl;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
      });
    }
  }

  Future<void> _uploadProfilePhoto() async {
    if (_imageFile == null || currentUser == null) return;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${currentUser!.uid}.jpg');
      await storageRef.putFile(_imageFile!);
      final downloadUrl = await storageRef.getDownloadURL();

      await _userService.updateUserProfilePhoto(currentUser!.uid, downloadUrl);
      setState(() {
        _profilePhotoUrl = downloadUrl;
      });
      _showSnackBar('Profile photo updated successfully!');
    } catch (e) {
      _showSnackBar('Failed to upload profile photo: $e');
    }
  }

  Future<void> _saveSettings() async {
    if (currentUser == null) {
      _showSnackBar('No authenticated user found.');
      return;
    }

    // Update username
    if (_usernameController.text.isNotEmpty &&
        _usernameController.text !=
            (await _userService.getUserById(currentUser!.uid))?.username) {
      try {
        await _userService.updateUsername(
          currentUser!.uid,
          _usernameController.text,
        );
        _showSnackBar('Username updated successfully!');
      } catch (e) {
        _showSnackBar('Failed to update username: $e');
      }
    }

    // Update password
    if (_passwordController.text.isNotEmpty) {
      if (_passwordController.text == _confirmPasswordController.text) {
        try {
          await _userService.changePassword(_passwordController.text);
          _showSnackBar('Password updated successfully!');
          _passwordController.clear();
          _confirmPasswordController.clear();
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            _showSnackBar('Please re-authenticate to change your password.');
          } else {
            _showSnackBar('Failed to update password: ${e.message}');
          }
        } catch (e) {
          _showSnackBar('Failed to update password: $e');
        }
      } else {
        _showSnackBar('Passwords do not match.');
      }
    }

    // Upload profile photo if a new one was picked
    if (_imageFile != null) {
      await _uploadProfilePhoto();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2F4156),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF2F4156),
                      radius: 50,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_profilePhotoUrl != null &&
                                        _profilePhotoUrl!.isNotEmpty
                                    ? NetworkImage(_profilePhotoUrl!)
                                    : const AssetImage(
                                        'assets/images/logo.png',
                                      ))
                                as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              color: Color(0xFF2F4156),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Username',
                controller: _usernameController,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Email',
                controller: _emailController,
                enabled: false,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'New Password',
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Confirm Password',
                controller: _confirmPasswordController,
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F4156),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await _userService.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/auth');
                },
                icon: const Icon(Icons.logout, color: Color(0xFF2F4156)),
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Color(0xFF2F4156),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled ? Colors.grey[100] : Colors.grey[300],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
