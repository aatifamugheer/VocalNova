import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> registerParent({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await credential.user!.updateDisplayName(name.trim());

    await _firestore.collection('users').doc(credential.user!.uid).set({
      'uid': credential.user!.uid,
      'name': name.trim(),
      'email': email.trim(),
      'role': 'parent',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  Future<UserCredential> registerTherapist({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await credential.user!.updateDisplayName(name.trim());

    final therapistCode = await _generateUniqueTherapistCode();

    await _firestore.collection('users').doc(credential.user!.uid).set({
      'uid': credential.user!.uid,
      'name': name.trim(),
      'email': email.trim(),
      'role': 'therapist',
      'therapistCode': therapistCode,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  Future<String> _generateUniqueTherapistCode() async {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();

    for (int attempt = 0; attempt < 10; attempt++) {
      final code = List.generate(
        6,
        (_) => characters[random.nextInt(characters.length)],
      ).join();

      final therapistCode = 'VN-$code';

      final existing = await _firestore
          .collection('users')
          .where('therapistCode', isEqualTo: therapistCode)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        return therapistCode;
      }
    }

    throw Exception(
      'Could not generate a unique therapist code. Please try again.',
    );
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  Future<void> signOut() => _auth.signOut();
}