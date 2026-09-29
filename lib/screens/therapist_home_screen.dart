import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'account_screen.dart';

class TherapistHomeScreen extends StatefulWidget {
  const TherapistHomeScreen({super.key});

  @override
  State<TherapistHomeScreen> createState() => _TherapistHomeScreenState();
}

class _TherapistHomeScreenState extends State<TherapistHomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
  bool _loadingChildren = true;
  String? _error;

  List<Map<String, dynamic>> _children = [];
  Map<String, dynamic>? _selectedChild;

  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _attempts = [];

  bool _loadingChildData = false;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('No therapist is currently signed in.');
      }

      final snapshot = await _firestore
          .collection('children')
          .where('therapistId', isEqualTo: user.uid)
          .get();

      if (!mounted) return;

      final children = snapshot.docs.map((doc) {
        final data = doc.data();

        return <String, dynamic>{
          ...data,
          'id': doc.id,
        };
      }).toList();

      setState(() {
        _children = children;
        _loadingChildren = false;
        _error = null;
      });

      if (children.isNotEmpty) {
        await _selectChild(children.first);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingChildren = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _selectChild(Map<String, dynamic> child) async {
    final childId = child['id'] as String?;

    if (childId == null || childId.isEmpty) return;

    setState(() {
      _selectedChild = child;
      _loadingChildData = true;
      _sessions = [];
      _attempts = [];
    });

    try {
      final sessions = await _firestoreService.getSessions();
      final attempts = await _firestoreService.getAttempts();

      if (!mounted) return;

      setState(() {
        _sessions = sessions
            .where((item) => item['childId'] == childId)
            .toList();

        _attempts = attempts
            .where((item) => item['childId'] == childId)
            .toList();

        _loadingChildData = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingChildData = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loadingChildren = true;
      _error = null;
    });

    await _loadChildren();
  }

  List<Map<String, dynamic>> get _completedSessions =>
      _sessions.where((item) => item['completed'] == true).toList();

  int get _successes => _attempts.where((item) {
        final score = (item['speechScore'] as num?)?.toDouble() ?? 0;
        return score >= 70;
      }).length;

  int get _successRate {
    if (_attempts.isEmpty) return 0;

    return ((_successes / _attempts.length) * 100).round();
  }

  int get _totalSeconds => _completedSessions.fold<int>(
        0,
        (total, session) =>
            total + ((session['durationSec'] as num?)?.toInt() ?? 0),
      );

  int get _practiceDaysLast7 {
    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    final days = <String>{};

    for (final session in _completedSessions) {
      final timestamp = session['startedAt'];

      if (timestamp is! Timestamp) continue;

      final date = timestamp.toDate();

      final day = DateTime(
        date.year,
        date.month,
        date.day,
      );

      if (!day.isBefore(start)) {
        days.add('${day.year}-${day.month}-${day.day}');
      }
    }

    return days.length;
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }

    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;

    if (remaining == 0) {
      return '${minutes}m';
    }

    return '${minutes}m ${remaining}s';
  }

  Map<String, dynamic>? get _latestSession {
    if (_completedSessions.isEmpty) {
      return null;
    }

    final sessions = [..._completedSessions];

    sessions.sort((a, b) {
      final aTime = a['startedAt'];
      final bTime = b['startedAt'];

      if (aTime is! Timestamp || bTime is! Timestamp) {
        return 0;
      }

      return bTime.compareTo(aTime);
    });

    return sessions.first;
  }

  Map<String, List<double>> get _targetScores {
    final result = <String, List<double>>{};

    for (final attempt in _attempts) {
      final target = attempt['targetWord'] as String? ?? '';

      if (target.isEmpty) continue;

      final score =
          (attempt['speechScore'] as num?)?.toDouble() ?? 0;

      result.putIfAbsent(target, () => []).add(score);
    }

    return result;
  }

  List<MapEntry<String, double>> _rankTargets() {
    final ranked = _targetScores.entries.map((entry) {
      final average =
          entry.value.reduce((a, b) => a + b) / entry.value.length;

      return MapEntry(entry.key, average);
    }).toList();

    ranked.sort((a, b) => b.value.compareTo(a.value));

    return ranked;
  }

  String get _practiceInsight {
    if (_attempts.isEmpty) {
      return 'No speech attempts have been recorded yet.';
    }

    if (_successRate >= 70 && _practiceDaysLast7 >= 3) {
      return 'Recent speech performance and practice activity are both being recorded consistently.';
    }

    if (_successRate < 50) {
      return 'Recent attempts show that some speech targets may benefit from additional guided repetition.';
    }

    if (_practiceDaysLast7 < 2) {
      return 'There are fewer recent practice days recorded. Short, regular practice can provide more progress data.';
    }

    return 'Recent practice data shows a mixed pattern. Review individual targets and recent attempts before the next session.';
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingChildren) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null && _children.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: _buildError(),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            const Text(
              'Therapist Home',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'View connected children and review their home-practice progress.',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 22),
            _buildTherapistHeader(),
            const SizedBox(height: 24),
            _sectionTitle(
              'Connected Children',
              'Children connected using your therapist code',
            ),
            const SizedBox(height: 12),
            _buildChildrenSection(),
            const SizedBox(height: 26),
            if (_selectedChild != null) ...[
              _childHeader(),
              const SizedBox(height: 16),
              if (_loadingChildData)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                ..._buildChildDashboard(),
            ],
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
  return AppBar(
    title: const Text(
      'Therapist Dashboard',
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
    actions: [
      IconButton(
        tooltip: 'Refresh',
        onPressed: _refresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
      IconButton(
        tooltip: 'Logout',
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded),
      ),
    ],
  );
}
  Widget _buildTherapistHeader() {
    final user = _auth.currentUser;

    final therapistName =
        user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim()
            : 'Therapist';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEDE7FF),
            Color(0xFFF5F2FF),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Color(0xFF7657F4),
              size: 31,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    color: Color(0xFF77708D),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  therapistName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_children.length} connected ${_children.length == 1 ? 'child' : 'children'}',
                  style: const TextStyle(
                    color: Color(0xFF77708D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenSection() {
    if (_children.isEmpty) {
      return _emptyChildrenCard();
    }

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final child = _children[index];

          final selected =
              _selectedChild?['id'] == child['id'];

          return _childSelectorCard(
            child,
            selected: selected,
          );
        },
      ),
    );
  }

  Widget _childSelectorCard(
    Map<String, dynamic> child, {
    required bool selected,
  }) {
    final name =
        child['name'] as String? ?? 'Child';

    final age =
        child['age']?.toString() ?? '';

    return GestureDetector(
      onTap: () => _selectChild(child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 170,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEDE7FF)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF7657F4)
                : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFF0EDFF),
                  child: const Icon(
                    Icons.child_care_rounded,
                    color: Color(0xFF7657F4),
                  ),
                ),
                const Spacer(),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF7657F4),
                    size: 21,
                  ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (age.isNotEmpty)
              Text(
                'Age $age',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyChildrenCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 48,
            color: Color(0xFF7657F4),
          ),
          SizedBox(height: 12),
          Text(
            'No children connected yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Share your therapist code with parents. They can enter it while creating their child profile.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF77708D),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _childHeader() {
    final child = _selectedChild!;

    final name =
        child['name'] as String? ?? 'Child';

    final completedSessions =
        _completedSessions.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.child_care_rounded,
              color: Color(0xFF7C5CFC),
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$completedSessions completed sessions',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChildDashboard() {
    final latest = _latestSession;
    final rankedTargets = _rankTargets();

    return [
      _overviewCards(),
      const SizedBox(height: 26),
      _sectionTitle(
        'Speech Performance',
        'Current results from recorded speech attempts',
      ),
      const SizedBox(height: 12),
      _performancePanel(),
      const SizedBox(height: 24),
      _sectionTitle(
        'Target Overview',
        'Average scores by practiced target',
      ),
      const SizedBox(height: 12),
      if (rankedTargets.isEmpty)
        _emptyCard(
          'Target data will appear after speech attempts.',
        )
      else
        ...rankedTargets.take(5).map(_targetTile),
      const SizedBox(height: 24),
      _sectionTitle(
        'Latest Session',
        'Most recently completed practice',
      ),
      const SizedBox(height: 12),
      latest == null
          ? _emptyCard(
              'No completed practice session yet.',
            )
          : _latestSessionCard(latest),
      const SizedBox(height: 24),
      _sectionTitle(
        'Practice Insight',
        'Data-based summary for review',
      ),
      const SizedBox(height: 12),
      _insightCard(),
      const SizedBox(height: 20),
      Text(
        'These indicators are prototype tracking metrics and are not a clinical diagnosis.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade600,
        ),
      ),
    ];
  }

  Widget _overviewCards() {
    return Row(
      children: [
        Expanded(
          child: _metric(
            'Sessions',
            '${_completedSessions.length}',
            Icons.calendar_today_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metric(
            'Practice',
            _formatDuration(_totalSeconds),
            Icons.timer_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metric(
            'Success',
            '$_successRate%',
            Icons.star_rounded,
          ),
        ),
      ],
    );
  }

  Widget _metric(
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF7C5CFC),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _performancePanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Speech success',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$_successRate%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7C5CFC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: (_successRate / 100).clamp(0.0, 1.0),
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_attempts.length} attempts'),
              Text(
                '$_practiceDaysLast7 practice days',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _targetTile(
    MapEntry<String, double> target,
  ) {
    final score = target.value.clamp(0.0, 100.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEDE7FF),
          child: Icon(
            Icons.record_voice_over_rounded,
            color: Color(0xFF7C5CFC),
          ),
        ),
        title: Text(
          target.key,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 6,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        trailing: Text(
          '${score.round()}%',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _latestSessionCard(
    Map<String, dynamic> session,
  ) {
    final duration =
        (session['durationSec'] as num?)?.toInt() ?? 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                ),
                SizedBox(width: 10),
                Text(
                  'Completed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              _formatSessionDate(
                session['startedAt'],
              ),
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_formatDuration(duration)} practice',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSessionDate(dynamic timestamp) {
    if (timestamp is! Timestamp) {
      return 'Recent session';
    }

    final date = timestamp.toDate();

    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _insightCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFF7C5CFC),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _practiceInsight,
              style: const TextStyle(
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Text(message),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 50,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load therapist data',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}