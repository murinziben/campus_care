import 'constants.dart';

/// Pure, unit-tested form validators. Each returns an error message or null.
class Validators {
  Validators._();

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static bool isAluEmail(String email) {
    final value = email.trim().toLowerCase();
    if (!_emailPattern.hasMatch(value)) return false;
    final domain = value.split('@').last;
    return AppConstants.allowedDomains.contains(domain);
  }

  static String? aluEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter your ALU email.';
    if (!_emailPattern.hasMatch(v)) return 'Please enter a valid email address.';
    if (!isAluEmail(v)) {
      return 'Please enter a valid ALU email address '
          '(@${AppConstants.studentDomain}).';
    }
    return null;
  }

  static String? fullName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter your full name.';
    if (v.length < 2) return 'Name is too short.';
    return null;
  }

  static bool hasMinLength(String value) =>
      value.length >= AppConstants.minPasswordLength;
  static bool hasNumber(String value) => RegExp(r'\d').hasMatch(value);

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter a password.';
    if (!hasMinLength(v)) {
      return 'Use at least ${AppConstants.minPasswordLength} characters.';
    }
    if (!hasNumber(v)) return 'Include at least one number.';
    return null;
  }

  static String? loginPassword(String? value) =>
      (value ?? '').isEmpty ? 'Please enter your password.' : null;

  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Please repeat your password.';
    if (value != original) return 'Passwords do not match.';
    return null;
  }

  static String? title(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please give the issue a short title.';
    if (v.length < 5) return 'Title must be at least 5 characters.';
    if (v.length > 80) return 'Title must be 80 characters or fewer.';
    return null;
  }

  static String? description(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please describe what happened.';
    if (v.length < 20) return 'Add a little more detail (at least 20 characters).';
    if (v.length > 1000) return 'Description must be 1000 characters or fewer.';
    return null;
  }

  static String? building(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please tell us the building or area.';
    if (v.length > 60) return 'Keep this under 60 characters.';
    return null;
  }

  static String? staffNote(String? value) {
    if ((value ?? '').trim().length > 500) {
      return 'Note must be 500 characters or fewer.';
    }
    return null;
  }
}
