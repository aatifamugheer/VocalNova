import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'account_screen.dart';
import 'create_child_profile_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  final String? childId;
  final String? childName;

  const ParentHomeScreen({
    super.key,
    this.childId,
    this.childName,
  });

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

Future<void> _logout() async {
  try {
    await _authService.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const AccountScreen(),
      ),
      (route) => false,
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not log out: $e'),
      ),
    );
  }
}

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _children = [];
  String? _selectedChildId;
  Map<String, dynamic>? _selectedChild;

  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _attempts = [];
  int _engagementScore = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No signed-in parent account.');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('children')
          .where('parentId', isEqualTo: user.uid)
          .get();

      final children = snapshot.docs.map((doc) {
        final data = doc.data();
        return <String, dynamic>{
          ...data,
          'childId': data['childId'] ?? doc.id,
        };
      }).toList();

      if (children.isEmpty) {
        if (!mounted) return;
        setState(() {
          _children = [];
          _selectedChild = null;
          _selectedChildId = null;
          _sessions = [];
          _attempts = [];
          _engagementScore = 0;
          _loading = false;
          _error = null;
        });
        return;
      }

      String selectedId = widget.childId ??
          _selectedChildId ??
          (children.first['childId'] as String);

      final selected = children.firstWhere(
        (child) => child['childId'] == selectedId,
        orElse: () => children.first,
      );

      selectedId = selected['childId'] as String;

      final allSessions = await _firestoreService.getSessions();
      final allAttempts = await _firestoreService.getAttempts();

      final sessions = allSessions
          .where((session) => session['childId'] == selectedId)
          .toList();

      final attempts = allAttempts
          .where((attempt) => attempt['childId'] == selectedId)
          .toList();

      final recentSessions = sessions
          .where((session) => session['completed'] == true)
          .take(10)
          .toList();

      int engagementTotal = 0;
      int engagementCount = 0;

      for (final session in recentSessions) {
        final sessionId = session['sessionId'] as String? ?? '';
        if (sessionId.isEmpty) continue;

        final events = await _firestoreService.getEngagementEvents(
          childId: selectedId,
          sessionId: sessionId,
        );

        for (final event in events) {
          switch (event.type) {
            case 'MISSION_COMPLETED':
            case 'VOLUNTARY_RETRY':
            case 'RETURNED':
              engagementTotal += 100;
              engagementCount++;
              break;
            case 'SKIPPED':
              engagementCount++;
              break;
            case 'TIME_ON_TASK':
              if (event.value > 0) {
                engagementTotal += 75;
                engagementCount++;
              }
              break;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _children = children;
        _selectedChild = selected;
        _selectedChildId = selectedId;
        _sessions = sessions;
        _attempts = attempts;
        _engagementScore = engagementCount == 0
            ? 0
            : (engagementTotal / engagementCount).round();
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

  Future<void> _selectChild(String childId) async {
    setState(() {
      _selectedChildId = childId;
      _loading = true;
    });
    await _loadDashboard();
  }

  List<Map<String, dynamic>> get _completedSessions =>
      _sessions.where((s) => s['completed'] == true).toList();

  int get _totalPracticeSeconds => _completedSessions.fold<int>(
        0,
        (total, session) =>
            total + ((session['durationSec'] as num?)?.toInt() ?? 0),
      );

  int get _thisWeekSeconds {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    return _completedSessions.fold<int>(0, (total, session) {
      final timestamp = session['startedAt'];
      if (timestamp is! Timestamp) return total;
      final date = timestamp.toDate();
      final day = DateTime(date.year, date.month, date.day);
      if (!day.isBefore(monday)) {
        return total + ((session['durationSec'] as num?)?.toInt() ?? 0);
      }
      return total;
    });
  }

  int get _successfulAttempts => _attempts.where((attempt) {
        final score = (attempt['speechScore'] as num?)?.toDouble() ?? 0;
        return score >= 70;
      }).length;

  int get _successRate => _attempts.isEmpty
      ? 0
      : ((_successfulAttempts / _attempts.length) * 100).round();

  List<double> get _weeklySpeechPerformance {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    return List.generate(7, (index) {
      final day = monday.add(Duration(days: index));
      final dayAttempts = _attempts.where((attempt) {
        final timestamp = attempt['createdAt'];
        if (timestamp is! Timestamp) return false;
        final date = timestamp.toDate();
        return date.year == day.year &&
            date.month == day.month &&
            date.day == day.day;
      }).toList();

      if (dayAttempts.isEmpty) return 0;

      final total = dayAttempts.fold<double>(
  0,
  (totalScore, attempt) =>
      totalScore + ((attempt['speechScore'] as num?)?.toDouble() ?? 0),
);
      return total / dayAttempts.length;
    });
  }

  List<String> _rankTargets({required bool strong}) {
    final scores = <String, List<double>>{};
    for (final attempt in _attempts) {
      final word = attempt['targetWord'] as String? ?? '';
      if (word.isEmpty) continue;
      final score = (attempt['speechScore'] as num?)?.toDouble() ?? 0;
      scores.putIfAbsent(word, () => []).add(score);
    }

    final ranked = scores.entries.map((entry) {
      final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return MapEntry(entry.key, average);
    }).where((entry) => strong ? entry.value >= 70 : entry.value < 70).toList()
      ..sort((a, b) => strong
          ? b.value.compareTo(a.value)
          : a.value.compareTo(b.value));

    return ranked.take(3).map((entry) => entry.key).toList();
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return remaining == 0 ? '${minutes}m' : '${minutes}m ${remaining}s';
  }

  String _relativeDay(Map<String, dynamic> session) {
    final timestamp = session['startedAt'];
    if (timestamp is! Timestamp) return 'Recent';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(sessionDay).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return '${date.day}/${date.month}';
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: _buildErrorState(),
      );
    }

    if (_children.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: _buildNoChildrenState(),
      );
    }

    final childName =
        (_selectedChild?['name'] as String?) ?? widget.childName ?? 'Child';

    final weekTime = _formatDuration(_thisWeekSeconds);
    final totalTime = _formatDuration(_totalPracticeSeconds);

    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            _buildGreeting(childName),
            const SizedBox(height: 20),
            _buildChildrenSelector(),
            const SizedBox(height: 18),
            _buildChildDetails(),
            const SizedBox(height: 18),
            _buildHeroProgress(weekTime, totalTime),
            const SizedBox(height: 18),
            _buildQuickStats(),
            const SizedBox(height: 28),
            _buildSectionTitle(
              'Speech Performance',
              'Average speech score across this child\'s attempts',
            ),
            const SizedBox(height: 12),
            _buildSpeechChart(),
            const SizedBox(height: 24),
            _buildEngagementCard(),
            const SizedBox(height: 24),
            _buildProfileInfo(),
            const SizedBox(height: 24),
            _buildTargetCard(
              title: 'Strong Targets',
              subtitle: 'Words currently showing stronger performance',
              icon: Icons.check_circle_rounded,
              items: _rankTargets(strong: true),
              emptyText: 'Keep practicing to build a clear strength pattern.',
              isPositive: true,
            ),
            const SizedBox(height: 14),
            _buildTargetCard(
              title: 'Needs Practice',
              subtitle: 'Targets with lower recent speech scores',
              icon: Icons.track_changes_rounded,
              items: _rankTargets(strong: false),
              emptyText: 'No target currently needs extra practice.',
              isPositive: false,
            ),
            const SizedBox(height: 28),
            _buildRecentSessions(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
      title: const Text(
        'Parent Dashboard',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _loadDashboard,
          icon: const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: 'Logout',
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    );

  Widget _buildGreeting(String childName) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_greeting()} 👋',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$childName\'s Progress',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'A personalized view of home speech practice.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      );

  Widget _buildChildrenSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Your Children',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton.icon(
              onPressed: _openCreateChild,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Child'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C5CFC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 94,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _children.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == _children.length) {
                return _addChildCard();
              }

              final child = _children[index];
              final id = child['childId'] as String;
              final selected = id == _selectedChildId;

              return InkWell(
                onTap: () => _selectChild(id),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 150,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFEDE7FF)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF7C5CFC)
                          : Colors.grey.shade200,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFDCD2FF),
                        child: Icon(
                          Icons.child_care_rounded,
                          color: Color(0xFF7C5CFC),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          child['name'] as String? ?? 'Child',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openCreateChild() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateChildProfileScreen(),
      ),
    ).then((_) => _loadDashboard());
  }

  Widget _addChildCard() => InkWell(
        onTap: _openCreateChild,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 130,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF7C5CFC),
              style: BorderStyle.solid,
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline_rounded,
                  color: Color(0xFF7C5CFC)),
              SizedBox(height: 5),
              Text(
                'Add Child',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );

  Widget _buildChildDetails() {
    final child = _selectedChild!;
    final words = (child['targetWords'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final interests = (child['interests'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final mode = child['practiceMode'] == 'therapist'
        ? 'With Therapist'
        : 'Practice at Home';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Child Profile',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _detailRow(
            Icons.cake_outlined,
            'Age',
            '${child['age'] ?? '-'} years',
          ),
          const SizedBox(height: 9),
          _detailRow(Icons.groups_rounded, 'Practice', mode),
          const SizedBox(height: 14),
          _tagSection('Target Words', words),
          const SizedBox(height: 12),
          _tagSection('Interests', interests),
          if (child['therapistId'] != null) ...[
            const SizedBox(height: 12),
            _detailRow(
              Icons.medical_services_outlined,
              'Therapist',
              'Connected',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileInfo() => const SizedBox.shrink();

  Widget _detailRow(IconData icon, String title, String value) => Row(
        children: [
          Icon(icon, size: 19, color: const Color(0xFF7C5CFC)),
          const SizedBox(width: 9),
          Text(
            '$title: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Expanded(child: Text(value)),
        ],
      );

  Widget _tagSection(String title, List<String> values) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (values.isEmpty)
            Text(
              'Not set',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: values
                  .map((value) => Chip(
                        label: Text(value),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
        ],
      );

  Widget _buildHeroProgress(String weekTime, String totalTime) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C5CFC), Color(0xFF9A7BFF)],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Practice Time',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text(
                    '$weekTime this week',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Total recorded: $totalTime',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.timer_rounded, color: Colors.white, size: 38),
          ],
        ),
      );

  Widget _buildQuickStats() => Row(
        children: [
          Expanded(child: _statCard(Icons.calendar_today_rounded, 'Sessions',
              '${_completedSessions.length}')),
          const SizedBox(width: 10),
          Expanded(child: _statCard(Icons.mic_rounded, 'Attempts',
              '${_attempts.length}')),
          const SizedBox(width: 10),
          Expanded(child: _statCard(Icons.star_rounded, 'Success',
              '$_successRate%')),
        ],
      );

  Widget _statCard(IconData icon, String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF7C5CFC)),
            const SizedBox(height: 7),
            Text(value,
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      );

  Widget _buildSectionTitle(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ],
      );

  Widget _buildSpeechChart() {
    final values = _weeklySpeechPerformance;
    final hasData = values.any((value) => value > 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SizedBox(
        height: 180,
        child: hasData
            ? CustomPaint(
                painter: _SpeechChartPainter(values: values),
                child: const SizedBox.expand(),
              )
            : Center(
                child: Text(
                  'Speech performance will appear after attempts.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
      ),
    );
  }

  Widget _buildEngagementCard() {
    final score = _engagementScore.clamp(0, 100);
    final label = score >= 75
        ? 'Highly engaged'
        : score >= 50
            ? 'Building consistency'
            : score > 0
                ? 'Needs encouragement'
                : 'No engagement data yet';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white,
                  color: const Color(0xFF7C5CFC),
                ),
                Text('$score%',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Engagement',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                Text(
                  'Based on retries, returns, skips, time-on-task and completed missions.',
                  style: TextStyle(
                      color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> items,
    required String emptyText,
    required bool isPositive,
  }) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    color: isPositive
                        ? Colors.green.shade600
                        : Colors.orange.shade700),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(emptyText)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((item) => Chip(label: Text(item))).toList(),
              ),
          ],
        ),
      );

  Widget _buildRecentSessions() {
    final sessions = [..._completedSessions]
      ..sort((a, b) {
        final aTime = a['startedAt'];
        final bTime = b['startedAt'];
        if (aTime is! Timestamp || bTime is! Timestamp) return 0;
        return bTime.compareTo(aTime);
      });

    final recent = sessions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Recent Sessions',
          'Latest completed practice',
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text(
              'No completed sessions yet. Start practice to see progress here.',
            ),
          )
        else
          ...recent.map(
            (session) => Card(
              margin: const EdgeInsets.only(bottom: 9),
              elevation: 0,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEDE7FF),
                  child: Icon(Icons.mic_none_rounded,
                      color: Color(0xFF7C5CFC)),
                ),
                title: Text(_relativeDay(session),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${_formatDuration((session['durationSec'] as num?)?.toInt() ?? 0)} practice',
                ),
                trailing:
                    const Icon(Icons.check_circle_rounded, color: Colors.green),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNoChildrenState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: Color(0xFFEDE7FF),
                child: Icon(Icons.child_care_rounded,
                    size: 48, color: Color(0xFF7C5CFC)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Create your first child profile',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your child to start personalized VocalNova practice.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateChildProfileScreen(),
                    ),
                  ).then((_) => _loadDashboard());
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Child Profile'),
              ),
            ],
          ),
        ),
      );

  Widget _buildErrorState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 54),
              const SizedBox(height: 14),
              const Text(
                'Could not load progress',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _loadDashboard,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}

class _SpeechChartPainter extends CustomPainter {
  final List<double> values;

  const _SpeechChartPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = const Color(0xFF7C5CFC)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = const Color(0xFF7C5CFC);

    final top = 8.0;
    final bottom = size.height - 12;
    final height = bottom - top;

    for (int i = 0; i < 4; i++) {
      final y = top + height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * i / (values.length - 1);
      final normalized = (values[i] / 100).clamp(0.0, 1.0);
      points.add(Offset(x, bottom - normalized * height));
    }

    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final previous = points[i - 1];
        final current = points[i];
        final controlX = (previous.dx + current.dx) / 2;
        path.cubicTo(
          controlX,
          previous.dy,
          controlX,
          current.dy,
          current.dx,
          current.dy,
        );
      }
      canvas.drawPath(path, linePaint);
    }

    for (final point in points) {
      canvas.drawCircle(point, 4.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeechChartPainter oldDelegate) => true;
}
