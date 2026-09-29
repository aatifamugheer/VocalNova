import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../widgets/child_bottom_nav.dart';
import 'practice_screen.dart';
import 'parent_home_screen.dart';
import 'therapist_home_screen.dart';

class ChildProfileScreen extends StatelessWidget {
  const ChildProfileScreen({
    super.key,
    this.child,
  });

  final ChildProfile? child;

  void _onNavTap(BuildContext context, int index) {
  if (index == 3) {
    return;
  }

  if (index == 0) {
    Navigator.pop(context);
    return;
  }

  if (index == 1) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeScreen(
          exerciseName: 'Adaptive Practice',
          child: child,
        ),
      ),
    );
    return;
  }

  if (index == 2) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Progress screen is coming next!',
        ),
      ),
    );
    return;
  }
}

  @override
  Widget build(BuildContext context) {
    final childName =
        child?.displayName.trim().isNotEmpty == true
            ? child!.displayName
            : 'Child';

    final age = _parseAge(child?.ageBand);

    final interests = child?.interests.isNotEmpty == true
        ? child!.interests
        : const <String>[];

    final targetSounds = child?.targetSounds.isNotEmpty == true
        ? child!.targetSounds
        : const <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6FF),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Color(0xFF17151D),
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _ProfileHeader(
              childName: childName,
              age: age,
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'About me',
              icon: Icons.face_rounded,
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.cake_rounded,
                    title: 'Age',
                    value: '$age years',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.record_voice_over_rounded,
                    title: 'Target sounds',
                    value: targetSounds.isEmpty
                        ? 'Not set'
                        : targetSounds.join(', '),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'My interests',
              icon: Icons.favorite_rounded,
              child: interests.isEmpty
                  ? const Text(
                      'No interests selected yet.',
                      style: TextStyle(
                        color: Color(0xFF77727F),
                      ),
                    )
                  : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: interests
                          .map(
                            (interest) => _InterestChip(
                              label: interest,
                              icon: _interestIcon(interest),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Practice settings',
              icon: Icons.tune_rounded,
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.flag_rounded,
                    title: 'Daily practice goal',
                    subtitle: '10 minutes',
                    onTap: () => _showComingSoon(
                      context,
                      'Daily practice goal',
                    ),
                  ),
                  _ActionTile(
                    icon: Icons.notifications_active_rounded,
                    title: 'Practice reminders',
                    subtitle: 'Reminders are off',
                    onTap: () => _showComingSoon(
                      context,
                      'Practice reminders',
                    ),
                  ),
                  _ActionTile(
                    icon: Icons.volume_up_rounded,
                    title: 'Voice & sound',
                    subtitle: 'Speech feedback enabled',
                    onTap: () => _showComingSoon(
                      context,
                      'Voice & sound',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Parent & therapist',
              icon: Icons.groups_rounded,
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.family_restroom_rounded,
                    title: 'Parent dashboard',
                    subtitle: 'View detailed progress',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ParentHomeScreen(),
                        ),
                      );
                    },
                  ),
                  _ActionTile(
                    icon: Icons.medical_services_rounded,
                    title: 'Therapist dashboard',
                    subtitle: 'Manage speech goals',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TherapistHomeScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'VocalNova • Keep practicing, keep growing 💜',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ChildBottomNav(
        currentIndex: 3,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }

  int _parseAge(String? ageBand) {
    if (ageBand == null || ageBand.trim().isEmpty) {
      return 0;
    }

    final match = RegExp(r'\d+').firstMatch(ageBand);

    if (match == null) {
      return 0;
    }

    return int.tryParse(match.group(0)!) ?? 0;
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be connected next.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _interestIcon(String interest) {
    final value = interest.toLowerCase();

    if (value.contains('dinosaur')) return Icons.pets_rounded;
    if (value.contains('animal')) return Icons.emoji_nature_rounded;
    if (value.contains('car')) return Icons.directions_car_rounded;
    if (value.contains('space')) return Icons.rocket_launch_rounded;
    if (value.contains('ocean')) return Icons.water_rounded;
    if (value.contains('super')) return Icons.auto_awesome_rounded;

    return Icons.favorite_rounded;
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.childName,
    required this.age,
  });

  final String childName;
  final int age;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7657F4),
            Color(0xFF9B79FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(45),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '😊',
                style: TextStyle(fontSize: 44),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hello there! 👋',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  childName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$age years old • Speech explorer',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFEDEAF5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0ECFF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF7657F4),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF7657F4),
          size: 23,
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF77727F),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF7657F4),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5FC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF7657F4),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}