import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'parent_registration_screen.dart';
import 'therapist_registration_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7657F4), Color(0xFF9B79FF)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text('💜', style: TextStyle(fontSize: 32)),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Your VocalNova\njourney starts here ✨',
                style: TextStyle(
                  fontSize: 31,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF17151D),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Create an account or log in to continue. '
                'You can practice at home or connect with a therapist later.',
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.5,
                  color: Color(0xFF77727F),
                ),
              ),
              const SizedBox(height: 28),
              _FeatureStrip(
                icon: Icons.auto_awesome_rounded,
                title: 'Personalized practice',
                subtitle: 'Activities adapt to the child.',
              ),
              const SizedBox(height: 10),
              _FeatureStrip(
                icon: Icons.family_restroom_rounded,
                title: 'Home or therapist supported',
                subtitle: 'Choose what works for your family.',
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _showCreateAccount(context),
                  child: const Text('Create Account'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text('Log In'),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'You can use VocalNova at home or with a therapist.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8A8492),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateAccount(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDAD6E3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Choose your account',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Select the role that matches how you use VocalNova.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF77727F), fontSize: 14),
                ),
                const SizedBox(height: 20),
                _RoleCard(
                  icon: Icons.family_restroom_rounded,
                  title: 'Parent / Guardian',
                  subtitle: 'Create your account and a child profile.',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ParentRegistrationScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  icon: Icons.medical_services_rounded,
                  title: 'Therapist',
                  subtitle: 'Create an account and manage students.',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TherapistRegistrationScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDEAF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0ECFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF7657F4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF77727F),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9FD),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8E4F1)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF7657F4),
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF77727F),
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF77727F)),
          ],
        ),
      ),
    );
  }
}
