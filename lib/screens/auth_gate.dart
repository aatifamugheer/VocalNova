import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'account_screen.dart';
import '../main.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoading();
        }

        if (snapshot.hasData) {
          return const _SignedInPlaceholder();
        }

        return const AccountScreen();
      },
    );
  }
}

class _AuthLoading extends StatelessWidget {
  const _AuthLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8F6FF),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF7657F4),
        ),
      ),
    );
  }
}

class _SignedInPlaceholder extends StatelessWidget {
  const _SignedInPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const WelcomeScreen();
  }
}
