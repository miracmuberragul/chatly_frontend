import 'package:flutter/material.dart';
import 'package:chatly/screens/auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    });

    _animation = Tween<double>(
      begin: 0,
      end: 1000,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(color: Colors.white),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Positioned(
                    left:
                        MediaQuery.of(context).size.width / 2 -
                        _animation.value / 2,
                    top:
                        MediaQuery.of(context).size.height / 2 -
                        _animation.value / 2,
                    child: Container(
                      width: _animation.value,
                      height: _animation.value,
                      decoration: const ShapeDecoration(
                        color: Color(0xFF2F4156),
                        shape: OvalBorder(),
                      ),
                    ),
                  );
                },
              ),
              Center(
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: Image.asset(
                    'assets/images/white_logo.png',
                    width: 300,
                    height: 300,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
