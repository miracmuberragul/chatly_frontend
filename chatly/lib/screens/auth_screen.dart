import 'dart:io';
import 'package:chatly/services/apple_auth_page.dart';
import 'package:flutter/material.dart';
import 'package:chatly/services/auth_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AppleAuthPage _appleAuthPage = AppleAuthPage();
  final AuthPage _authPage = AuthPage();
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();

  String username = '';
  String email = '';
  String password = '';
  String confirmPassword = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark =
        Theme.of(context).brightness == Brightness.dark; // <-- EKLENDİ

    return Scaffold(
      // backgroundColor'u temaya bırak
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Logo: dark modda white_logo.png ve biraz daha büyük yükseklik
                  Image.asset(
                    isDark
                        ? 'assets/images/image.png'
                        : 'assets/images/logo.png',
                    height: isDark
                        ? 130
                        : 130, // karanlıkta biraz daha büyük çiz
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(height: 25),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isLogin
                          ? 'Login to your account'
                          : 'Create your Account',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cs.onBackground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (!_isLogin)
                    Column(
                      children: [
                        TextFormField(
                          decoration: _inputDecoration(context, 'Username'),
                          onChanged: (value) => username = value,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(context, 'Email'),
                    onChanged: (value) => email = value,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    obscureText: true,
                    decoration: _inputDecoration(context, 'Password'),
                    onChanged: (value) => password = value,
                  ),
                  const SizedBox(height: 16),

                  if (!_isLogin)
                    Column(
                      children: [
                        TextFormField(
                          obscureText: true,
                          decoration: _inputDecoration(
                            context,
                            'Confirm Password',
                          ),
                          onChanged: (value) => confirmPassword = value,
                        ),
                        const SizedBox(height: 24),
                      ],
                    )
                  else
                    const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          if (_isLogin) {
                            _authPage.signInWithEmailPassword(
                              context,
                              email,
                              password,
                            );
                          } else {
                            _authPage.signUpWithEmailPassword(
                              context,
                              email,
                              password,
                              username,
                            );
                          }
                        }
                      },
                      child: Text(
                        _isLogin ? 'Sign in' : 'Sign up',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                   // Social Login Buttons
                  _socialLoginButton(
                    context: context,
                    logoPath:
                        'assets/images/google.png', // Ensure this path is correct and image is in pubspec.yaml
                    label: 'Sign in with Google',
                    onTap: () {
                      _authPage.signInWithGoogle(context);
                    },
                  ),

                  // Add more social login buttons here if needed (e.g., Apple, Facebook)
                  // const SizedBox(height: 16),
                  // _socialLoginButton(
                  //   context: context,
                  //   logoPath: 'assets/images/apple.png',
                  //   label: 'Sign in with Apple',
                  //   onTap: () {
                  //     // TODO: Implement Apple sign-in
                  //   },
                  // ),
                  const SizedBox(height: 20),


                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin
                            ? "Don't have any account?"
                            : "Already have an account?",
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          _isLogin ? 'Sign up' : 'Login',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Tema-dostu input dekorasyonu
  InputDecoration _inputDecoration(BuildContext context, String label) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: cs.surfaceVariant, // 0xFFC8D9E6 benzeri açık panel
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  // Tema-dostu sosyal login butonu
  Widget _socialLoginButton({
    required BuildContext context,
    required String logoPath,
    required String label,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final shadowColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.black26
        : Colors.black12;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(logoPath, width: 24, height: 24, fit: BoxFit.contain),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: cs.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
