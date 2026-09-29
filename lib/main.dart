import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/create_child_profile_screen.dart';
import 'screens/parent_home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/therapist_home_screen.dart';
import 'screens/child_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      home: const SplashScreen(),
      routes: {
        '/create-child': (context) =>
            const CreateChildProfileScreen(),
      },
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
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),
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
              MaterialPageRoute(
                builder: (_) => screen,
              ),
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
