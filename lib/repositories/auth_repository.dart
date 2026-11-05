import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/app_exception.dart';
import '../models/app_user.dart';
import '../models/auth_session.dart';
import '../models/enums.dart';

/// Authentication + user-profile data access. The UI never touches Firebase
/// directly; it talks to [AuthProvider], which talks to this interface.
abstract class AuthRepository {
  /// Emits the current session (or null when signed out) and re-emits when
  /// the user reloads / refreshes their token.
  Stream<AuthSession?> sessionChanges();

  Future<void> signIn({required String email, required String password});

  /// Creates the account, stores the `users/{uid}` profile (role = student)
  /// and sends the verification email.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> resendVerification();

  /// Reloads the user and force-refreshes the ID token so the new
  /// `email_verified` claim is visible to security rules. Returns the fresh
  /// session (null when signed out).
  Future<AuthSession?> refreshVerification();

  Future<void> sendPasswordReset(String email);
  Future<void> signOut();

  Future<AppUser> loadOrCreateProfile(AuthSession session);
  Future<void> markUpdatesSeen(String uid);
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  AuthSession? _toSession(User? user) {
    if (user == null) return null;
    return AuthSession(
      uid: user.uid,
      email: user.email ?? '',
      emailVerified: user.emailVerified,
      displayName: user.displayName,
    );
  }

  @override
  Stream<AuthSession?> sessionChanges() => _auth.userChanges().map(_toSession);

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AppException(_authMessage(e));
    }
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cred = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(name.trim());
      await _userDoc(user.uid).set(AppUser(
        uid: user.uid,
        email: cleanEmail,
        displayName: name.trim(),
        role: UserRole.student,
        createdAt: DateTime.now(),
      ).toCreateMap());
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AppException(_authMessage(e));
    } on FirebaseException {
      throw const AppException(
          'Your account was created but we could not save your profile. '
          'Please sign in again.');
    }
  }

  @override
  Future<void> resendVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AppException(_authMessage(e));
    }
  }

  @override
  Future<AuthSession?> refreshVerification() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      await user.reload();
      await _auth.currentUser?.getIdToken(true);
      return _toSession(_auth.currentUser);
    } on FirebaseAuthException catch (e) {
      throw AppException(_authMessage(e));
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on FirebaseAuthException catch (e) {
      throw AppException(_authMessage(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<AppUser> loadOrCreateProfile(AuthSession session) async {
    try {
      final ref = _userDoc(session.uid);
      final snap = await ref.get();
      if (snap.exists && snap.data() != null) {
        return AppUser.fromMap(session.uid, snap.data()!);
      }
      final fresh = AppUser(
        uid: session.uid,
        email: session.email,
        displayName: (session.displayName?.trim().isNotEmpty ?? false)
            ? session.displayName!.trim()
            : session.email.split('@').first,
        role: UserRole.student,
        createdAt: DateTime.now(),
      );
      await ref.set(fresh.toCreateMap());
      return fresh;
    } on FirebaseException catch (e) {
      throw AppException(
          e.code == 'permission-denied'
              ? 'Your account is not allowed to use CampusCare.'
              : 'Could not load your profile. Check your connection.');
    }
  }

  @override
  Future<void> markUpdatesSeen(String uid) async {
    try {
      await _userDoc(uid).update({'lastSeenUpdates': FieldValue.serverTimestamp()});
    } on FirebaseException {
      // Non-critical: the unread dot simply stays until the next attempt.
    }
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Contact campus IT.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try signing in.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Authentication failed (${e.code}). Please try again.';
    }
  }
}
