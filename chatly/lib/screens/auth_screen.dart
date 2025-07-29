import 'dart:io';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();

  String username = '';
  String email = '';
  String password = '';
  String confirmPassword = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Image.asset('assets/images/logo.png', height: 130),
                  const SizedBox(height: 25),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isLogin
                          ? 'Login to your account'
                          : 'Create your Account',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (!_isLogin)
                    Column(
                      children: [
                        TextFormField(
                          decoration: _inputDecoration('Username'),
                          onChanged: (value) => username = value,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('Email'),
                    onChanged: (value) => email = value,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    obscureText: true,
                    decoration: _inputDecoration('Password'),
                    onChanged: (value) => password = value,
                  ),
                  const SizedBox(height: 16),

                  if (!_isLogin)
                    Column(
                      children: [
                        TextFormField(
                          obscureText: true,
                          decoration: _inputDecoration('Confirm Password'),
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
                        backgroundColor: const Color(0xFF2F4156),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {},
                      child: Text(
                        _isLogin ? 'Sign in' : 'Sign up',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: const [
                      Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text("or"),
                      ),
                      Expanded(child: Divider(thickness: 1)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (Platform.isAndroid)
                    _socialLoginButton(
                      logoPath: 'assets/images/google.png',
                      label: 'Sign in with Google',
                      onTap: () {
                        debugPrint("Google Login Tapped");
                      },
                    )
                  else if (Platform.isIOS)
                    _socialLoginButton(
                      logoPath: 'assets/images/apple.png',
                      label: 'Sign in with Apple',

                      onTap: () async {
                        print("Apple Login Tapped");
                        try {
                          final userCredential = await _appleAuthPage
                              .signInWithApple();
                          print(
                            'Apple Sign-In başarılı: ${userCredential.user?.email}',
                          );
                          // Giriş sonrası yönlendirme veya state güncelle
                        } catch (e) {
                          print('Apple Sign-In hatası: $e');
                          // Hata mesajı gösterebilirsin
                        }
                      },
                    ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin
                            ? "Don't have any account?"
                            : "Already have an account?",
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          _isLogin ? 'Sign up' : 'Login',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 28, 97, 176),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.grey[100],
    );
  }

  Widget _socialLoginButton({
    required String logoPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(logoPath, width: 24, height: 24, fit: BoxFit.contain),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
