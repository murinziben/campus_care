import 'package:campus_care/models/auth_session.dart';
import 'package:campus_care/models/enums.dart';
import 'package:campus_care/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeAuthRepository repo;
  late AuthProvider auth;

  setUp(() {
    repo = FakeAuthRepository();
    auth = AuthProvider(repo);
  });

  tearDown(() => auth.dispose());

  AuthSession session({
    String uid = 'u1',
    String email = 'amara@alustudent.com',
    bool verified = true,
  }) =>
      AuthSession(
          uid: uid, email: email, emailVerified: verified, displayName: 'Amara Mensah');

  test('starts in initializing and becomes unauthenticated with no user', () async {
    expect(auth.status, AuthStatus.initializing);
    repo.emit(null);
    await pumpEventQueue();
    expect(auth.status, AuthStatus.unauthenticated);
  });

  test('unverified email is held at the verification step', () async {
    repo.emit(session(verified: false));
    await pumpEventQueue();
    expect(auth.status, AuthStatus.unverified);
    expect(auth.user, isNull);
  });

  test('verified student becomes authenticated with the student role', () async {
    repo.emit(session());
    await pumpEventQueue();
    expect(auth.status, AuthStatus.authenticated);
    expect(auth.isStaff, isFalse);
    expect(auth.user!.firstName, 'Amara');
  });

  test('role comes from the stored profile, so staff get staff access', () async {
    repo.roles['staff-1'] = UserRole.staff;
    repo.emit(session(uid: 'staff-1', email: 'kofi@alueducation.com'));
    await pumpEventQueue();
    expect(auth.status, AuthStatus.authenticated);
    expect(auth.isStaff, isTrue);
  });

  test('non-ALU accounts are rejected and signed out', () async {
    repo.emit(session(email: 'someone@gmail.com'));
    await pumpEventQueue();
    expect(auth.status, AuthStatus.unauthenticated);
    expect(repo.signOutCalls, 1);
    expect(auth.error, contains('ALU'));
  });

  test('checkVerification fails politely while still unverified', () async {
    repo.emit(session(verified: false));
    await pumpEventQueue();
    final ok = await auth.checkVerification();
    expect(ok, isFalse);
    expect(repo.verificationRefreshes, 1);
    expect(auth.error, isNotNull);
  });

  test('checkVerification succeeds once the email has been verified', () async {
    repo.emit(session(verified: false));
    await pumpEventQueue();
    repo.current = session(verified: true); // reload() found the new state
    final ok = await auth.checkVerification();
    expect(ok, isTrue);
    expect(auth.status, AuthStatus.authenticated);
  });

  test('verifying moves unverified -> authenticated', () async {
    repo.emit(session(verified: false));
    await pumpEventQueue();
    repo.emit(session(verified: true)); // Firebase re-emits after reload()
    await pumpEventQueue();
    expect(auth.status, AuthStatus.authenticated);
  });

  test('signOut returns to unauthenticated and clears the user', () async {
    repo.emit(session());
    await pumpEventQueue();
    await auth.signOut();
    await pumpEventQueue();
    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.user, isNull);
  });
}
