/// App-wide constants.
class AppConstants {
  AppConstants._();

  static const appName = 'CampusCare';

  /// Only these email domains may use the app (also enforced in Firestore rules).
  static const studentDomain = 'alustudent.com';
  static const staffDomain = 'alueducation.com';
  static const allowedDomains = [studentDomain, staffDomain];

  static const minPasswordLength = 8;
  static const maxPhotoBytes = 5 * 1024 * 1024; // checked in the app before upload
}
