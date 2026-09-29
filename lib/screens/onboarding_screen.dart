import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const completedKey = 'vocalnova_onboarding_completed';

  static Future<bool> hasCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(completedKey) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(completedKey, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const pages = [
    ('🗣️', 'Practice speaking with confidence',
        'VocalNova turns speech practice into short, friendly activities made for children.'),
    ('🎮', 'Make practice feel like play',
        'Complete speaking missions, explore fun themes, and earn rewards while you practice.'),
    ('🌟', 'Practice your way',
        'Use VocalNova at home with your parent, or connect with a therapist for guided practice.'),
  ];

  Future<void> _finish() async {
    await OnboardingScreen.markCompleted();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AccountScreen()),
    );
  }

  void _next() {
    if (_page == pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == pages.length - 1;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Color(0xFF7657F4),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final p = pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 230,
                          height: 230,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEDE7FF),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(p.$1,
                                style: const TextStyle(fontSize: 92)),
                          ),
                        ),
                        const SizedBox(height: 42),
                        Text(
                          p.$2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.$3,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Color(0xFF77727F),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 4, 28, 24),
              child: Row(
                children: [
                  Row(
                    children: List.generate(
                      pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 7),
                        width: i == _page ? 25 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? const Color(0xFF7657F4)
                              : const Color(0xFFD9D2F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(last ? 'Get Started' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
