/// Minimal, Firebase-agnostic view of the signed-in Firebase Auth user.
/// Keeping this out of the provider API lets tests use in-memory fakes.
class AuthSession {
  const AuthSession({
    required this.uid,
    required this.email,
    required this.emailVerified,
    this.displayName,
  });

  final String uid;
  final String email;
  final bool emailVerified;
  final String? displayName;
}
