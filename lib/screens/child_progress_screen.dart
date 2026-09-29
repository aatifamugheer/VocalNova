import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../services/firestore_service.dart';
import '../widgets/child_bottom_nav.dart';
import 'child_profile_screen.dart';
import 'practice_screen.dart';

class ChildProgressScreen extends StatefulWidget {
  final String childId;
  final String childName;
  final ChildProfile? child;

  const ChildProgressScreen({
    super.key,
    this.childId = 'demo_child_001',
    this.childName = 'Demo Child',
    this.child,
  });

  @override
  State<ChildProgressScreen> createState() => _ChildProgressScreenState();
}

class _ChildProgressScreenState extends State<ChildProgressScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _attempts = [];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final sessions = await _firestoreService.getSessions();
      final attempts = await _firestoreService.getAttempts();

      if (!mounted) return;

      setState(() {
        _sessions = sessions
            .where((session) => session['childId'] == widget.childId)
            .toList();
        _attempts = attempts
            .where((attempt) => attempt['childId'] == widget.childId)
            .toList();
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  int get _completedSessions => _sessions
      .where((session) => session['completed'] == true)
      .length;

  int get _successfulAttempts => _attempts.where((attempt) {
        final score = (attempt['speechScore'] as num?)?.toDouble() ?? 0;
        return score >= 70;
      }).length;

  int get _totalStars => _successfulAttempts;

  int get _totalSeconds => _sessions
      .where((session) => session['completed'] == true)
      .fold<int>(
        0,
        (sum, session) =>
            sum + ((session['durationSec'] as num?)?.toInt() ?? 0),
      );

  int get _successRate {
    if (_attempts.isEmpty) return 0;
    return ((_successfulAttempts / _attempts.length) * 100).round();
  }

  int get _practiceDays {
    final days = <String>{};

    for (final session in _sessions) {
      if (session['completed'] != true) continue;

      final raw = session['completedAt'] ?? session['startedAt'];
      DateTime? date;

      if (raw is DateTime) {
        date = raw;
      } else {
        try {
          date = DateTime.parse(raw.toString());
        } catch (_) {}
      }

      if (date != null) {
        days.add('${date.year}-${date.month}-${date.day}');
      }
    }

    return days.length;
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '${seconds}s';

    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;

    if (remaining == 0) return '${minutes}m';
    return '${minutes}m ${remaining}s';
  }

  String _encouragement() {
    if (_attempts.isEmpty) {
      return 'Your first adventure is waiting! 🚀';
    }

    if (_successRate >= 90) {
      return 'Amazing speaking! You are on a roll! 🌟';
    }

    if (_successRate >= 70) {
      return 'Great progress! Keep your adventure going! 🎉';
    }

    return 'Every try makes you stronger. Keep going! 💜';
  }

  String _achievementTitle() {
    if (_completedSessions >= 10) return 'Adventure Champion 🏆';
    if (_completedSessions >= 5) return 'Practice Hero 🦸';
    if (_completedSessions >= 1) return 'First Mission Complete ⭐';
    return 'Ready for Your First Mission 🚀';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Progress',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _loadProgress,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                    children: [
                      _welcomeCard(),
                      const SizedBox(height: 18),
                      _mainStats(),
                      const SizedBox(height: 18),
                      _achievementCard(),
                      const SizedBox(height: 18),
                      _progressCard(),
                      const SizedBox(height: 18),
                      _recentActivity(),
                    ],
                  ),
                ),
      bottomNavigationBar: ChildBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 2) return;

          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const PracticeScreen(
                  exerciseName: 'Adaptive Practice',
                ),
              ),
            );
          } else if (index == 3) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => ChildProfileScreen(
        child: widget.child,
      ),
    ),
  );
}
        },
      ),
    );
  }

  Widget _welcomeCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7C5CFC),
            Color(0xFF9A7BFF),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hey ${widget.childName}! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _encouragement(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainStats() {
    return Row(
      children: [
        _statCard(
          icon: Icons.star_rounded,
          value: '$_totalStars',
          label: 'Stars',
        ),
        const SizedBox(width: 10),
        _statCard(
          icon: Icons.flag_rounded,
          value: '$_completedSessions',
          label: 'Missions',
        ),
        const SizedBox(width: 10),
        _statCard(
          icon: Icons.local_fire_department_rounded,
          value: '$_practiceDays',
          label: 'Practice days',
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 17,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF7C5CFC),
              size: 26,
            ),
            const SizedBox(height: 7),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _achievementCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3D8),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFF0A500),
              size: 34,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your achievement',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _achievementTitle(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_totalStars successful speaking attempts',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressCard() {
    final progress = (_successRate / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Speaking progress',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Your successful practice attempts',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFEDE7FF),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF7C5CFC),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$_successRate%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFF7C5CFC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _miniInfo(
                  Icons.timer_rounded,
                  _formatTime(_totalSeconds),
                  'Practice time',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniInfo(
                  Icons.mic_rounded,
                  '${_attempts.length}',
                  'Attempts',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7FF),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF7C5CFC),
            size: 22,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentActivity() {
    final completed = _sessions
        .where((session) => session['completed'] == true)
        .toList();

    completed.sort((a, b) {
      final aTime = a['completedAt']?.toString() ?? '';
      final bTime = b['completedAt']?.toString() ?? '';
      return bTime.compareTo(aTime);
    });

    final recent = completed.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent adventures',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (recent.isEmpty)
            Text(
              'Complete your first mission and it will appear here! 🚀',
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            )
          else
            ...recent.map(
              (session) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFEDE7FF),
                      child: Icon(
                        Icons.check_rounded,
                        color: Color(0xFF7C5CFC),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mission completed • '
                        '${_formatTime((session['durationSec'] as num?)?.toInt() ?? 0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: Color(0xFF7C5CFC),
            ),
            const SizedBox(height: 15),
            const Text(
              'Could not load your progress.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadProgress();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
