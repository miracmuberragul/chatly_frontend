import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';
import '../theme/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
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
    _loadUserData();
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
      if (!mounted) return;
      setState(() {
        _imageFile = File(pickedImage.path);
      });
      await _uploadProfilePhoto();
    }
  }

  Future<void> _uploadProfilePhoto() async {
    if (_imageFile == null || currentUser == null) return;

    try {
      final bytes = await _imageFile!.readAsBytes();
      final ext = _imageFile!.path.contains('.')
          ? _imageFile!.path.split('.').last
          : 'jpg';
      final base64Str = base64Encode(bytes);
      final dataUri = 'data:image/$ext;base64,$base64Str';

      if (dataUri.length > 900000) {
        _showSnackBar('profilePhotoTooLarge'.tr, isError: true);
        return;
      }

      await _userService.updateUserProfilePhoto(currentUser!.uid, dataUri);

      if (!mounted) return;
      setState(() {
        _profilePhotoUrl = dataUri;
      });
      _showSnackBar('profilePhotoUpdatedSuccessfully'.tr);
    } catch (e) {
      _showSnackBar('${'errorUploadingProfilePhoto'.tr}: $e', isError: true);
    }
  }

  Future<void> _saveSettings() async {
    if (currentUser == null) {
      _showSnackBar('noAuthenticatedUserFound'.tr, isError: true);
      return;
    }

    // Kullanıcı adı güncelleme
    try {
      final existing = await _userService.getUserById(currentUser!.uid);
      final newUsername = _usernameController.text.trim();
      if (newUsername.isNotEmpty && newUsername != (existing?.username ?? '')) {
        await _userService.updateUsername(currentUser!.uid, newUsername);
        _showSnackBar('usernameUpdatedSuccessfully'.tr);
      }
    } catch (e) {
      _showSnackBar('${'errorUpdatingUsername'.tr}: $e', isError: true);
    }

    // Parola güncelleme
    if (_oldPasswordController.text.isNotEmpty ||
        _passwordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty) {
      if (_oldPasswordController.text.isEmpty) {
        _showSnackBar('enterCurrentPasswordToChange'.tr, isError: true);
        return;
      }
      if (_passwordController.text.isEmpty ||
          _confirmPasswordController.text.isEmpty) {
        _showSnackBar('enterAndConfirmNewPassword'.tr, isError: true);
        return;
      }
      if (_passwordController.text == _confirmPasswordController.text) {
        try {
          await _userService.changePassword(
            oldPassword: _oldPasswordController.text,
            newPassword: _passwordController.text,
            email: currentUser!.email!,
          );
          _showSnackBar('passwordUpdatedSuccessfully'.tr);
          _oldPasswordController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
        } on FirebaseAuthException catch (e) {
          _showSnackBar(e.message ?? 'errorUpdatingPassword'.tr, isError: true);
        } catch (e) {
          _showSnackBar(
            '${'unknownErrorUpdatingPassword'.tr}: $e',
            isError: true,
          );
        }
      } else {
        _showSnackBar('newPasswordsDoNotMatch'.tr, isError: true);
      }
    }

    if (_imageFile != null) {
      await _uploadProfilePhoto();
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        isError ? 'error'.tr : 'info'.tr,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
      );
    }
  }

  ImageProvider _imageProvider() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    }
    if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty) {
      if (_profilePhotoUrl!.startsWith('data:image')) {
        try {
          final bytes = base64Decode(_profilePhotoUrl!.split(',').last);
          return MemoryImage(bytes);
        } catch (e) {
          debugPrint("Base64 Decode Error: $e");
          return const AssetImage('assets/images/logo.png');
        }
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

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final cs = Theme.of(context).colorScheme;
    final selectedMode = themeController.mode == ThemeMode.dark
        ? ThemeMode.dark
        : ThemeMode.light;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'settings'.tr,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
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
                            'edit'.tr,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'language'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final currentLang = Get.locale?.languageCode ?? 'en';
                      final newLocale = currentLang == 'en'
                          ? const Locale('tr', 'TR')
                          : const Locale('en', 'US');

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('locale', newLocale.languageCode);

                      Get.updateLocale(newLocale);

                      setState(() {});
                    },
                    child: Text(Get.locale?.languageCode.toUpperCase() ?? 'EN'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'username'.tr,
                controller: _usernameController,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'email'.tr,
                controller: _emailController,
                enabled: false,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'currentPassword'.tr,
                controller: _oldPasswordController,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'newPassword'.tr,
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'confirmNewPassword'.tr,
                controller: _confirmPasswordController,
                obscureText: true,
              ),
              const SizedBox(height: 24),
              Text(
                'theme'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text('light'.tr),
                    icon: const Icon(Icons.light_mode),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text('dark'.tr),
                    icon: const Icon(Icons.dark_mode),
                  ),
                ],
                selected: {selectedMode},
                onSelectionChanged: (sel) {
                  themeController.setMode(sel.first);
                },
                showSelectedIcon: true,
                multiSelectionEnabled: false,
                emptySelectionAllowed: false,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F4156),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'saveSettings'.tr,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await _userService.signOut();
                  if (!mounted) return;
                  Get.offAllNamed('/auth');
                },
                icon: const Icon(Icons.logout),
                label: Text(
                  'logOut'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
