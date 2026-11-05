import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../core/validators.dart';
import '../models/app_user.dart';
import '../models/auth_session.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus {
  /// Waiting for Firebase to restore a previous session.
  initializing,
  unauthenticated,

  /// Signed in, but the ALU email has not been verified yet.
  unverified,

  /// Signed in, verified, and the profile (role) has been loaded.
  authenticated,
}

/// Owns the authentication session and the signed-in user's profile/role.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo) {
    _sub = _repo.sessionChanges().listen(
          _onSession,
          onError: (Object e) {
            _status = AuthStatus.unauthenticated;
            _error = describeError(e);
            notifyListeners();
          },
        );
  }

  final AuthRepository _repo;
  StreamSubscription<AuthSession?>? _sub;

  AuthStatus _status = AuthStatus.initializing;
  AuthSession? _session;
  AppUser? _user;
  String? _error;
  bool _busy = false;
  String _handledKey = '';

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  AppUser? get user => _user;
  String? get error => _error;
  bool get isBusy => _busy;
  bool get isStaff => _user?.isStaff ?? false;
  String get email => _session?.email ?? '';

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> _onSession(AuthSession? session) async {
    _session = session;

    if (session == null) {
      _handledKey = '';
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // userChanges() fires often (token refresh etc.); only react to real changes.
    final key = '${session.uid}:${session.emailVerified}';
    if (key == _handledKey) return;
    _handledKey = key;

    // Defence in depth: the domain is also enforced by security rules.
    if (!Validators.isAluEmail(session.email)) {
      _error = 'Only ALU email accounts can use CampusCare.';
      _handledKey = '';
      await _repo.signOut();
      return;
    }

    if (!session.emailVerified) {
      _user = null;
      _status = AuthStatus.unverified;
      notifyListeners();
      return;
    }

    try {
      _user = await _repo.loadOrCreateProfile(session);
      _status = AuthStatus.authenticated;
    } catch (e) {
      _error = describeError(e);
      _handledKey = '';
      await _repo.signOut();
      return;
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) =>
      _run(() => _repo.signIn(email: email, password: password));

  Future<bool> register(String name, String email, String password) =>
      _run(() => _repo.register(name: name, email: email, password: password));

  Future<bool> resendVerification() => _run(_repo.resendVerification);

  /// Called by "I've verified my email". Returns true when verification is
  /// now confirmed; otherwise sets an explanatory error.
  Future<bool> checkVerification() async {
    AuthSession? fresh;
    final ok = await _run(() async {
      fresh = await _repo.refreshVerification();
    });
    if (!ok) return false;
    if (fresh?.emailVerified ?? false) {
      // Apply immediately instead of waiting for the next auth event.
      await _onSession(fresh);
      return true;
    }
    _error = 'We could not confirm your email yet. '
        'Open the link in the email, then try again.';
    notifyListeners();
    return false;
  }

  Future<bool> sendPasswordReset(String email) =>
      _run(() => _repo.sendPasswordReset(email));

  Future<void> signOut() async {
    await _repo.signOut();
  }

  /// Marks the Updates feed as read.
  Future<void> markUpdatesSeen() async {
    final user = _user;
    if (user == null) return;
    _user = user.copyWith(lastSeenUpdates: DateTime.now());
    notifyListeners();
    await _repo.markUpdatesSeen(user.uid);
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _error = describeError(e);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
