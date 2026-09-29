import 'dart:async';
import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import 'account_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    Timer(const Duration(milliseconds: 1800), _continue);
  }

  Future<void> _continue() async {
    if (!mounted) return;
    final completed = await OnboardingScreen.hasCompleted();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            completed ? const AccountScreen() : const OnboardingScreen(),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7657F4), Color(0xFF9B79FF), Color(0xFFC5B5FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _controller, curve: Curves.easeIn),
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOutBack,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(34),
                    ),
                    child: const Center(
                      child: Text('🗣️', style: TextStyle(fontSize: 58)),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'VocalNova',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Speak • Practice • Grow',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
