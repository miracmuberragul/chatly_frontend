import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
// Firebase Storage disabled for base64 approach
import 'dart:convert';

import 'package:provider/provider.dart';
import '../theme/theme_controller.dart';

import '../services/user_service.dart';
import '../models/user_model.dart'; // Eğer tip olarak kullanmıyorsan kaldırabilirsin.

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
    _loadUserData(); // Firebase initialize burada yapılmaz; main.dart'ta yapıldı.
  }

  Future<void> _loadUserData() async {
    if (currentUser != null) {
      final userModel = await _userService.getUserById(currentUser!.uid);
      if (!mounted) return;
      if (userModel != null) {
        setState(() {
          _usernameController.text = userModel.username ?? '';
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
      // Otomatik olarak kaydet
      await _uploadProfilePhoto();
    }
  }

  Future<void> _uploadProfilePhoto() async {
    if (_imageFile == null || currentUser == null) return;

    try {
      // Convert selected image to base64 and store directly in Firestore
      final bytes = await _imageFile!.readAsBytes();
      final ext = _imageFile!.path.contains('.') ? _imageFile!.path.split('.').last : 'jpg';
      final base64Str = base64Encode(bytes);
      final dataUri = 'data:image/$ext;base64,$base64Str';

      if (dataUri.length > 900000) {
        _showSnackBar('Profile photo too large. Please choose a smaller one.');
        return;
      }

      await _userService.updateUserProfilePhoto(currentUser!.uid, dataUri);
      // Update local state

      if (!mounted) return;
      setState(() {
        _profilePhotoUrl = dataUri;
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

    // Username
    try {
      final existing = await _userService.getUserById(currentUser!.uid);
      final newUsername = _usernameController.text.trim();
      if (newUsername.isNotEmpty && newUsername != (existing?.username ?? '')) {
        await _userService.updateUsername(currentUser!.uid, newUsername);
        _showSnackBar('Username updated successfully!');
      }
    } catch (e) {
      _showSnackBar('Failed to update username: $e');
    }

    // Password
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

    // Photo
    if (_imageFile != null) {
      await _uploadProfilePhoto();
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final cs = Theme.of(context).colorScheme;

    // SegmentedButton seçimi: 'system' varsa, UI'da varsayılanı 'light' göster.
    final ThemeMode selectedMode = themeController.mode == ThemeMode.dark
        ? ThemeMode.dark
        : ThemeMode.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(radius: 50, backgroundImage: _imageProvider()),
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
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            'Edit',
                            style: TextStyle(
                              color: cs.primary,
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

              // ---------- Tema Seçimi (yalnızca Aydınlık/Karanlık) ----------
              const SizedBox(height: 24),
              const Text(
                'Tema',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode),
                  ),
                ],
                selected: {selectedMode},
                onSelectionChanged: (sel) {
                  final mode = sel.first;
                  themeController.setMode(mode);
                },
                showSelectedIcon: true, // seçili segmente ✓ ekler
                multiSelectionEnabled: false,
                emptySelectionAllowed: false,
              ),

              // ---------- Tema Seçimi Son ----------
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2F4156),
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
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Log Out',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider _imageProvider() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    }
    if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty) {
      if (_profilePhotoUrl!.startsWith('data:image')) {
        final bytes = base64Decode(_profilePhotoUrl!.split(',').last);
        return MemoryImage(bytes);
      } else if (_profilePhotoUrl!.startsWith('http')) {
        return NetworkImage(_profilePhotoUrl!);
      }
    }
    return const AssetImage('assets/images/logo.png');
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
      decoration: InputDecoration(labelText: label),
    );
  }
}
