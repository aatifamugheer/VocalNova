import 'package:flutter/material.dart'; 
 
import '../services/auth_service.dart'; 
 
class ParentRegistrationScreen extends StatefulWidget { 
  const ParentRegistrationScreen({super.key}); 
 
  @override 
  State<ParentRegistrationScreen> createState() => 
      _ParentRegistrationScreenState(); 
} 
 
class _ParentRegistrationScreenState extends State<ParentRegistrationScreen> { 
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
 
    setState(() => _loading = true); 
 
    try { 
      await _auth.registerParent( 
        name: _name.text, 
        email: _email.text, 
        password: _password.text, 
      ); 
 
     if (!mounted) return; 
 
Navigator.pushReplacementNamed(context, '/create-child'); 
    } on Exception catch (e) { 
      if (!mounted) return; 
      _showError(_friendlyError(e)); 
    } finally { 
      if (mounted) setState(() => _loading = false); 
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
    return 'Could not create the account. Please try again.'; 
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
      title: 'Parent account', 
      subtitle: 'Create your account first. We will create your child profile next.', 
      child: Form( 
        key: _formKey, 
        child: Column( 
          children: [ 
            _Input( 
              controller: _name, 
              label: 'Parent / guardian name', 
              icon: Icons.person_outline_rounded, 
              validator: (v) => 
                  v == null || v.trim().isEmpty ? 'Enter your name' : null, 
            ), 
            const SizedBox(height: 14), 
            _Input( 
              controller: _email, 
              label: 'Email address', 
              icon: Icons.email_outlined, 
              keyboardType: TextInputType.emailAddress, 
              validator: (v) { 
                if (v == null || v.trim().isEmpty) return 'Enter your email'; 
                if (!v.contains('@')) return 'Enter a valid email'; 
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
                onPressed: () => 
                    setState(() => _hidePassword = !_hidePassword), 
                icon: Icon( 
                  _hidePassword 
                      ? Icons.visibility_outlined 
                      : Icons.visibility_off_outlined, 
                ), 
              ), 
              validator: (v) => v == null || v.length < 6 
                  ? 'Use at least 6 characters' 
                  : null, 
            ), 
            const SizedBox(height: 14), 
            _Input( 
              controller: _confirm, 
              label: 'Confirm password', 
              icon: Icons.verified_user_outlined, 
              obscureText: true, 
              validator: (v) => 
                  v != _password.text ? 'Passwords do not match' : null, 
            ), 
            const SizedBox(height: 24), 
            SizedBox( 
              width: double.infinity, 
              height: 56, 
              child: ElevatedButton( 
                onPressed: _loading ? null : _create, 
                child: _loading 
                    ? const CircularProgressIndicator( 
                        color: Colors.white, 
                        strokeWidth: 2.5, 
                      ) 
                    : const Text('Create Parent Account'), 
              ), 
            ), 
          ], 
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
                icon: Icons.family_restroom_rounded, 
                text: 'PARENT / GUARDIAN', 
              ), 
              const SizedBox(height: 16), 
              Text(title, 
                  style: const TextStyle( 
                    fontSize: 30, 
                    fontWeight: FontWeight.w900, 
                  )), 
              const SizedBox(height: 8), 
              Text(subtitle, 
                  style: const TextStyle( 
                    color: Color(0xFF77727F), 
                    height: 1.45, 
                  )), 
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
  const _RoleBadge({required this.icon, required this.text}); 
  final IconData icon; 
  final String text; 
 
  @override 
  Widget build(BuildContext context) => Container( 
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
        decoration: BoxDecoration( 
          color: const Color(0xFFEDE7FF), 
          borderRadius: BorderRadius.circular(12), 
        ), 
        child: Row( 
          mainAxisSize: MainAxisSize.min, 
          children: [ 
            Icon(icon, size: 17, color: const Color(0xFF7657F4)), 
            const SizedBox(width: 7), 
            Text(text, 
                style: const TextStyle( 
                  color: Color(0xFF7657F4), 
                  fontSize: 12, 
                  fontWeight: FontWeight.w900, 
                )), 
          ], 
        ), 
      ); 
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
  Widget build(BuildContext context) => TextFormField( 
        controller: controller, 
        keyboardType: keyboardType, 
        obscureText: obscureText, 
        validator: validator, 
        decoration: InputDecoration( 
          labelText: label, 
          prefixIcon: Icon(icon), 
          suffixIcon: suffix, 
        ), 
      ); 
} 