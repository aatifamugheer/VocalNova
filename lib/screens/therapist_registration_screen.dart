import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'therapist_home_screen.dart';
import '../services/auth_service.dart';

class TherapistRegistrationScreen extends StatefulWidget {
  const TherapistRegistrationScreen({super.key});

  @override
  State<TherapistRegistrationScreen> createState() =>
      _TherapistRegistrationScreenState();
}

class _TherapistRegistrationScreenState
    extends State<TherapistRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  final _auth = AuthService();

  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      await _auth.registerTherapist(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      );

      if (!mounted) return;

      final user = _auth.currentUser;

      if (user == null) {
        throw Exception(
          'Therapist account was created, but user session is missing.',
        );
      }

      final therapistDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = therapistDoc.data();

      final therapistCode = data?['therapistCode'] as String?;

if (therapistCode == null || therapistCode.isEmpty) {
  throw Exception(
    'Therapist code was not generated.',
  );
}

if (!mounted) return;

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => TherapistCodeScreen(
      therapistName: _name.text.trim(),
      therapistCode: therapistCode,
    ),
  ),
);
    } on Exception catch (e) {
      if (!mounted) return;

      _showError(_friendlyError(e));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _friendlyError(Exception error) {
    final text = error.toString();

    if (text.contains('email-already-in-use')) {
      return 'An account already exists with this email.';
    }

    if (text.contains('weak-password')) {
      return 'Choose a stronger password.';
    }

    if (text.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }

    if (text.contains('Therapist code was not generated')) {
      return 'Your account was created, but we could not generate your therapist code. Please try again.';
    }

    return 'Could not create the therapist account. Please try again.';
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
    return _RegistrationScaffold(
      title: 'Therapist account',
      subtitle:
          'Create your therapist account and manage your VocalNova students.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _Input(
              controller: _name,
              label: 'Therapist name',
              icon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your name';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            _Input(
              controller: _email,
              label: 'Email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your email';
                }

                if (!value.contains('@')) {
                  return 'Enter a valid email';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            _Input(
              controller: _password,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscureText: _hidePassword,
              suffix: IconButton(
                onPressed: () {
                  setState(() {
                    _hidePassword = !_hidePassword;
                  });
                },
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Use at least 6 characters';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            _Input(
              controller: _confirm,
              label: 'Confirm password',
              icon: Icons.verified_user_outlined,
              obscureText: true,
              validator: (value) {
                if (value != _password.text) {
                  return 'Passwords do not match';
                }

                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7657F4),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      )
                    : const Text(
                        'Create Therapist Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TherapistCodeScreen extends StatelessWidget {
  const TherapistCodeScreen({
    super.key,
    required this.therapistName,
    required this.therapistCode,
  });

  final String therapistName;
  final String therapistCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEDE7FF),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    size: 52,
                    color: Color(0xFF7657F4),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to VocalNova! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF29243E),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Hi $therapistName, your therapist account is ready.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF77708D),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE4DDF8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Your Therapist Code',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF77708D),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE7FF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          therapistCode,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF7657F4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Share this code with parents so they can connect their child to you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF77708D),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EDFF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF7657F4),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Parents can enter this code while creating their child profile to connect the child with you.',
                          style: TextStyle(
                            color: Color(0xFF5F5875),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const TherapistHomeScreen(),
    ),
  );
},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7657F4),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

class _RegistrationScaffold extends StatelessWidget {
  const _RegistrationScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

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
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _RoleBadge(
                icon: Icons.medical_services_rounded,
                text: 'THERAPIST',
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF77727F),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.medical_services_rounded,
            size: 17,
            color: Color(0xFF7657F4),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF7657F4),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
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
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF7657F4),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}