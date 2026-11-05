/// A user-presentable error. Repositories translate low-level exceptions
/// (FirebaseAuthException, FirebaseException...) into this type so the UI and
/// providers never depend on Firebase types.
class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Turns any thrown object into a message suitable for a snackbar/banner.
String describeError(Object error) {
  if (error is AppException) return error.message;
  return 'Something went wrong. Please try again.';
}
