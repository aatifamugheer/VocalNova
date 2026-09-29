import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../widgets/child_bottom_nav.dart';
import 'practice_screen.dart';
import 'child_progress_screen.dart';
import 'child_profile_screen.dart';

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({
    super.key,
    this.child,
  });

  final ChildProfile? child;

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  int _currentIndex = 0;

  ChildProfile? get child => widget.child;

  String get childName {
    final name = child?.displayName.trim();

    if (name == null || name.isEmpty) {
      return 'there';
    }

    return name;
  }

  List<String> get targetSounds {
    return child?.targetSounds
            .map((sound) => sound.trim().toLowerCase())
            .where((sound) => sound.isNotEmpty)
            .toList() ??
        [];
  }

  List<String> get targetWords {
  return child?.targetWords
          .map((word) => word.trim().toLowerCase())
          .where((word) => word.isNotEmpty)
          .toList() ??
      [];
}

  List<String> get interests {
    return child?.interests
            .map((interest) => interest.trim())
            .where((interest) => interest.isNotEmpty)
            .toList() ??
        [];
  }

  String get favoriteInterest {
    if (interests.isEmpty) {
      return 'your favorite things';
    }

    return interests.first;
  }

  void _onChildNavTap(int index) {
    if (index == _currentIndex) return;

    if (index == 0) {
      setState(() {
        _currentIndex = 0;
      });
      return;
    }

    if (index == 1) {
      Navigator.push(
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
  final currentChild = child;

  if (currentChild == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Child profile is not available yet.',
        ),
      ),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChildProgressScreen(
        childId: currentChild.childId,
        childName: currentChild.displayName,
        child: currentChild,
      ),
    ),
  );
  return;
}

    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChildProfileScreen(
            child: child,
          ),
        ),
      );
    }
  }

  void _openPractice(String activityName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeScreen(
          exerciseName: activityName,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildGreeting(),
            ),
            SliverToBoxAdapter(
              child: _buildDailyMission(),
            ),
            SliverToBoxAdapter(
              child: _buildPersonalizedHeader(),
            ),
            SliverToBoxAdapter(
              child: _buildActivities(),
            ),
            SliverToBoxAdapter(
              child: _buildMotivationCard(),
            ),
            const SliverPadding(
              padding: EdgeInsets.only(bottom: 20),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ChildBottomNav(
        currentIndex: _currentIndex,
        onTap: _onChildNavTap,
      ),
    );
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi $childName! 👋',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF241B55),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ready for a fun voice adventure?',
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF716A86),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFDED5FF),
                  Color(0xFFF0EBFF),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(
              child: Text(
                '🌟',
                style: TextStyle(fontSize: 34),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMission() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7657F4),
            Color(0xFF9A7BFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7657F4).withAlpha(35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(35),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '⭐',
                    style: TextStyle(fontSize: 25),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  "Today's Mission",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '0 / 3',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Complete 3 fun activities',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Small steps today = stronger speech tomorrow! 🚀',
            style: TextStyle(
              color: Colors.white.withAlpha(220),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _missionStep('1'),
              _missionLine(),
              _missionStep('2'),
              _missionLine(),
              _missionStep('3'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _missionStep(String number) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withAlpha(100),
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF7657F4),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'To do',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _missionLine() {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(
          left: 8,
          right: 8,
          bottom: 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white38,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildPersonalizedHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE8FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                '🧠',
                style: TextStyle(fontSize: 27),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Just for you, $childName!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C216B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Activities picked around $favoriteInterest and your speech goals.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF716A86),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivities() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        children: [
          _buildActivityCard(
            title: 'Sound Adventure',
            subtitle: 'Warm up with your target sounds!',
            badge: 'Recommended for you',
            emoji: '🎤',
            colors: const [
              Color(0xFFDDF8E9),
              Color(0xFFC7F1DA),
            ],
            buttonColor: const Color(0xFF159B70),
            chips: targetSounds.isEmpty
                ? ['personalized']
                : targetSounds.take(3).toList(),
            onTap: () => _openPractice('Sound Adventure'),
          ),
          const SizedBox(height: 14),
          _buildActivityCard(
            title: 'Word Explorer',
            subtitle: 'Say words clearly and collect rewards!',
            badge: 'Build your streak',
            emoji: '🐶',
            colors: const [
              Color(0xFFFFF0D8),
              Color(0xFFFFE5BD),
            ],
            buttonColor: const Color(0xFFE87524),
            chips: targetWords.isEmpty
                ? ['new words']
                : targetWords.take(3).toList(),
            onTap: () => _openPractice('Word Explorer'),
          ),
          const SizedBox(height: 14),
          _buildActivityCard(
            title: 'Picture Quest',
            subtitle: 'Look, think, say and earn a star!',
            badge: 'Fun challenge',
            emoji: '🖼️',
            colors: const [
              Color(0xFFEAE4FF),
              Color(0xFFDCD2FF),
            ],
            buttonColor: const Color(0xFF6540E8),
            chips: const ['6 pictures'],
            onTap: () => _openPractice('Picture Quest'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String subtitle,
    required String badge,
    required String emoji,
    required List<Color> colors,
    required Color buttonColor,
    required List<String> chips,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withAlpha(180),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(130),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(170),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: buttonColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF21194E),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF5F5875),
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 5,
                  children: chips
                      .map(
                        (chip) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(180),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            chip,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF40395A),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 54,
            height: 54,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 27,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF5EFFF),
            Color(0xFFE8DEFF),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          const Text(
            '🏆',
            style: TextStyle(fontSize: 44),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Every practice makes you stronger!',
                  style: TextStyle(
                    color: Color(0xFF6540E8),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep going, $childName! 🌟',
                  style: const TextStyle(
                    color: Color(0xFF716A86),
                    fontSize: 13,
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