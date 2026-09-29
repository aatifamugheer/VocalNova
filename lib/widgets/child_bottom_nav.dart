import 'package:flutter/material.dart';

class ChildBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ChildBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          height: 70,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          indicatorColor: const Color(0xFFEDE7FF),
          labelBehavior:
              NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.mic_none_rounded),
              selectedIcon: Icon(Icons.mic_rounded),
              label: 'Practice',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Progress',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}