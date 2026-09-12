import 'package:flutter/material.dart';

import 'models/practice_session.dart';
import 'data/practice_store.dart';

void main() {
  runApp(const VocalNovaApp());
}

class VocalNovaApp extends StatelessWidget {
  const VocalNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VocalNova',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C5CFC),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F7FF),
      ),
      home: const WelcomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// WELCOME
// ─────────────────────────────────────────────

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              const SizedBox(height: 35),

              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7FF),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.record_voice_over_rounded,
                  size: 55,
                  color: Color(0xFF7C5CFC),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'VocalNova',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Speech practice made fun',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 55),

              _roleButton(
                context,
                icon: Icons.child_care_rounded,
                title: "I'm a Child",
                subtitle: 'Practice and play',
                screen: const ChildHomeScreen(),
              ),

              const SizedBox(height: 16),

              _roleButton(
                context,
                icon: Icons.family_restroom_rounded,
                title: "I'm a Parent",
                subtitle: 'See practice progress',
                screen: const ParentHomeScreen(),
              ),

              const SizedBox(height: 16),

              _roleButton(
                context,
                icon: Icons.medical_services_rounded,
                title: "I'm a Therapist",
                subtitle: 'Monitor and guide practice',
                screen: const TherapistHomeScreen(),
              ),

              const SizedBox(height: 40),

              Text(
                'A prototype for home speech-practice support',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget screen,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => screen),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF7C5CFC),
                    size: 29,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 17),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CHILD HOME
// ─────────────────────────────────────────────

class ChildHomeScreen extends StatelessWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Practice',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Hi there! 👋',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Ready for today\'s practice?',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 25),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF7C5CFC),
                  Color(0xFF9A7BFF),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Goal',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Practice 3 exercises',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'You\'ve got this! ⭐',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Exercises',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _exerciseCard(
            context,
            'Say the "S" sound',
            '10 attempts',
            Icons.record_voice_over_rounded,
          ),

          _exerciseCard(
            context,
            'Word practice',
            '8 words',
            Icons.chat_bubble_rounded,
          ),

          _exerciseCard(
            context,
            'Picture naming',
            '6 pictures',
            Icons.image_rounded,
          ),

          const SizedBox(height: 15),

          const Center(
            child: Text(
              'Keep practicing! 🌟',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF7C5CFC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE7FF),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF7C5CFC),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: FilledButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PracticeScreen(exerciseName: title),
              ),
            );
          },
          child: const Text('Start'),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PRACTICE
// ─────────────────────────────────────────────

class PracticeScreen extends StatefulWidget {
  final String exerciseName;

  const PracticeScreen({
    super.key,
    required this.exerciseName,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  int attempts = 0;
  int successes = 0;
  int skipped = 0;
  int difficultyLevel = 2;
  bool completed = false;

  final Stopwatch stopwatch = Stopwatch();

  void recordAttempt(bool success) {
    setState(() {
      attempts++;
      if (success) {
        successes++;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    stopwatch.start();
  }

  @override
  void dispose() {
    stopwatch.stop();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final successRate = attempts == 0 ? 0 : (successes / attempts * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.mic_rounded,
              size: 80,
              color: Color(0xFF7C5CFC),
            ),

            const SizedBox(height: 20),

            Text(
              widget.exerciseName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Try your best and have fun!',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<int>(
              initialValue: difficultyLevel,
              decoration: const InputDecoration(
                labelText: 'Difficulty',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 1,
                  child: Text('Easy'),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text('Moderate'),
                ),
                DropdownMenuItem(
                  value: 3,
                  child: Text('Difficult'),
                ),
              ],
              onChanged: completed
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          difficultyLevel = value;
                        });
                      }
                    },
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                _statBox('Attempts', '$attempts'),
                const SizedBox(width: 12),
                _statBox('Success', '$successes'),
                const SizedBox(width: 12),
                _statBox('Rate', '$successRate%'),
              ],
            ),

            const Spacer(),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: completed
                    ? null
                    : () {
                        setState(() {
                          skipped++;
                        });
                      },
                icon: const Icon(Icons.skip_next),
                label: const Text('Skip exercise'),
              ),
            ),
            

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: completed
                    ? null
                    : () => recordAttempt(false),
                child: const Text('Try again'),
              ),
            ),

            const SizedBox(height: 20),

            if (!completed)
              TextButton(
      onPressed: attempts == 0
          ? null
          : () {
              stopwatch.stop();

              final session = PracticeSession(
                exerciseName: widget.exerciseName,
                date: DateTime.now(),
                durationSeconds: stopwatch.elapsed.inSeconds,
                attempts: attempts,
                successes: successes,
                skips: skipped,
                difficultyLevel: difficultyLevel,
              );

              PracticeStore.addSession(session);

              setState(() {
                completed = true;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Practice session recorded! 🎉',
                  ),
                ),
              );
            },
                child: const Text('Complete session'),
              ),

            if (completed)
              const Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  'Great job! Your practice has been recorded. ⭐',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C5CFC),
                  ),
                ),
              ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
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
}

// ─────────────────────────────────────────────
// PARENT
// ─────────────────────────────────────────────

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {

  @override
  Widget build(BuildContext context) {
    final sessions = PracticeStore.sessions;
    final totalSessions = PracticeStore.totalSessions;
    final totalAttempts = PracticeStore.totalAttempts;
    final totalSuccesses = PracticeStore.totalSuccesses;
    final totalSeconds = PracticeStore.totalPracticeSeconds;

    final totalTime = totalSeconds < 60
      ? '${totalSeconds}s'
      : '${totalSeconds ~/ 60}m ${totalSeconds % 60}s';

    final successRate = totalAttempts == 0
        ? 0
        : ((totalSuccesses / totalAttempts) * 100).round();
        final today = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Parent Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Child Progress',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'A simple view of recent practice',
            style: TextStyle(color: Colors.grey.shade700),
          ),

          const SizedBox(height: 25),

          Row(
            children: [
              _metricCard(
                'Practice',
                '${sessions.length} sessions',
                Icons.calendar_today,
              ),
              const SizedBox(width: 12),
              _metricCard(
                'Time',
                totalTime,
                Icons.timer,
          ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _metricCard(
                'Completed',
                '$totalSessions',
                Icons.check_circle,
              ),
              const SizedBox(width: 12),
              _metricCard(
                'Success',
                '$successRate%',
                Icons.star,
              ),
            ],
          ),

          const SizedBox(height: 30),

          const Text(
            'This week',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          ..._buildWeekProgress(today),

          const SizedBox(height: 25),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: Color(0xFF7C5CFC),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Regular short sessions can help maintain a consistent practice routine.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWeekProgress(DateTime today) {
    final monday = today.subtract(
      Duration(days: today.weekday - 1),
    );

    const dayNames = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return List.generate(7, (index) {
      final day = monday.add(Duration(days: index));

      final practiced = PracticeStore.sessions.any((session) {
        return session.date.year == day.year &&
            session.date.month == day.month &&
            session.date.day == day.day;
      });

      return _progressRow(dayNames[index], practiced);
    });
  }

  Widget _metricCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: const Color(0xFF7C5CFC),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressRow(String day, bool practiced) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor:
            practiced ? const Color(0xFFE1F5E8) : Colors.grey.shade200,
        child: Icon(
          practiced ? Icons.check : Icons.remove,
          color: practiced ? Colors.green : Colors.grey,
        ),
      ),
      title: Text(day),
      trailing: Text(
        practiced ? 'Practiced' : 'No session',
        style: TextStyle(
          color: practiced ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// THERAPIST
// ─────────────────────────────────────────────

class TherapistHomeScreen extends StatelessWidget {
  const TherapistHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = PracticeStore.sessions;
    final totalSessions = PracticeStore.totalSessions;
    final totalAttempts = PracticeStore.totalAttempts;
    final totalSuccesses = PracticeStore.totalSuccesses;
    final totalSeconds = PracticeStore.totalPracticeSeconds;
    final practiceDays = PracticeStore.practiceDaysLast7;

    final successRate = totalAttempts == 0
        ? 0
        : ((totalSuccesses / totalAttempts) * 100).round();

    final totalTime = totalSeconds < 60
        ? '${totalSeconds}s'
        : '${totalSeconds ~/ 60}m ${totalSeconds % 60}s';

    final latestSession = PracticeStore.latestSession;
    String pattern = 'No data';
    Color patternColor = Colors.grey;
    String factor1 = 'No practice sessions recorded yet.';
    String factor2 = '';
    String factor3 = '';

    if (sessions.isNotEmpty) {
      final overallRate = totalAttempts == 0
          ? 0.0
          : totalSuccesses / totalAttempts;

      final totalSkips = sessions.fold(
        0,
        (total, session) => total + session.skips,
      );

      if (overallRate >= 0.75 && totalSkips == 0) {
        pattern = 'Consistent';
        patternColor = Colors.green;
        factor1 = 'High overall success rate';
        factor2 = 'Practice sessions are being completed';
        factor3 = 'No exercises skipped';
      } else if (overallRate >= 0.50) {
        pattern = 'Mixed';
        patternColor = Colors.orange;
        factor1 = 'Moderate overall success rate';
        factor2 = 'Some practice difficulties observed';
        factor3 = 'More sessions will improve the pattern';
      } else {
        pattern = 'Inconsistent';
        patternColor = Colors.red;
        factor1 = 'Lower overall success rate';
        factor2 = 'Practice difficulties observed';
        factor3 = 'More sessions are needed for monitoring';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Therapist Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Practice Overview',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Review home-practice patterns before the next session.',
            style: TextStyle(color: Colors.grey.shade700),
          ),

          const SizedBox(height: 25),

          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.child_care),
              ),
              title: const Text(
                'Demo Child',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '$totalSessions sessions • $practiceDays practice days',
              ),
              trailing: Text(
                '$successRate% success',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (latestSession != null) ...[
            const Text(
              'Latest Practice Session',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latestSession.exerciseName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Duration: ${latestSession.durationSeconds}s',
                    ),

                    Text(
                      'Attempts: ${latestSession.attempts}',
                    ),

                    Text(
                      'Successes: ${latestSession.successes}',
                    ),

                    Text(
                      'Difficulty: ${latestSession.difficultyLevel}/3',
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 25),

          const Text(
            'Practice Pattern Insight',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF7C5CFC),
              ),
              const SizedBox(width: 10),
              const Text(
                'Demo Child',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
                  const SizedBox(height: 15),
                  Text(
                    'Pattern: $pattern',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: patternColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Observed factors:',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 5),
                  Text('• $factor1'),
                  Text('• $factor2'),
                  Text('• $factor3'),
                  const SizedBox(height: 15),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.assignment_add),
                    label: const Text('Assign Practice'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Prototype insight — not a clinical diagnosis.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _childCard(
    String name,
    String sessions,
    String pattern,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(name.substring(name.length - 1)),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(sessions),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            pattern,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}