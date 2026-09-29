import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'parent_home_screen.dart';
import 'therapist_home_screen.dart';
import 'child_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  final _auth = AuthService();
  final _firestoreService = FirestoreService();

  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final credential = await _auth.signIn(
        email: _email.text,
        password: _password.text,
      );

      final uid = credential.user?.uid;

      if (uid == null) {
        throw Exception(
          'Login succeeded but user information is missing.',
        );
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw Exception(
          'Your account profile could not be found.',
        );
      }

      final data = userDoc.data();
      final role = data?['role'] as String?;

      if (!mounted) return;

      if (role == 'therapist') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const TherapistHomeScreen(),
          ),
          (route) => false,
        );
        return;
      }

      if (role == 'parent') {
        final children =
            await _firestoreService.getChildrenForParent(uid);

        if (!mounted) return;

        if (children.length == 1) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => ChildHomeScreen(
                child: children.first,
              ),
            ),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const ParentHomeScreen(),
            ),
            (route) => false,
          );
        }

        return;
      }

      await _auth.signOut();

      if (!mounted) return;

      _showError(
        'Your account role could not be recognized.',
      );
    } on Exception catch (e) {
      if (!mounted) return;

      _showError(_friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    if (_email.text.trim().isEmpty) {
      _showError('Enter your email first.');
      return;
    }

    try {
      await _auth.sendPasswordReset(_email.text);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset email sent. Check your inbox.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;

      _showError(_friendlyError(e));
    }
  }

  String _friendlyError(Exception error) {
    final text = error.toString();

    if (text.contains('invalid-credential')) {
      return 'Email or password is incorrect.';
    }

    if (text.contains('user-not-found')) {
      return 'No account was found with this email.';
    }

    if (text.contains('wrong-password')) {
      return 'Email or password is incorrect.';
    }

    if (text.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }

    if (text.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }

    if (text.contains('account profile could not be found')) {
      return 'Your account profile could not be found.';
    }

    return 'Login failed. Please check your details and try again.';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6FF),
        elevation: 0,
        foregroundColor: const Color(0xFF17151D),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            12,
            24,
            30,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const _Header(),
                const SizedBox(height: 28),
                _Field(
                  controller: _email,
                  label: 'Email address',
                  hint: 'you@example.com',
                  icon: Icons.email_outlined,
                  keyboardType:
                      TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter your email';
                    }

                    if (!v.contains('@')) {
                      return 'Enter a valid email';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _Field(
                  controller: _password,
                  label: 'Password',
                  hint: 'Your password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _hidePassword,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() {
                        _hidePassword =
                            !_hidePassword;
                      });
                    },
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Enter your password';
                    }

                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed:
                        _loading ? null : _forgotPassword,
                    child:
                        const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Log In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back 👋',
          style: TextStyle(
            color: Color(0xFF7657F4),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Log in to VocalNova',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Continue your speech practice journey.',
          style: TextStyle(
            color: Color(0xFF77727F),
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
      ),
    );
  }
}