import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

/// A signed-in user profile stored at `users/{uid}`.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    this.lastSeenUpdates,
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final DateTime createdAt;

  /// When the user last opened the Updates screen (drives the unread dot).
  final DateTime? lastSeenUpdates;

  bool get isStaff => role == UserRole.staff;

  String get firstName {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'there' : parts.first;
  }

  AppUser copyWith({DateTime? lastSeenUpdates, String? displayName}) => AppUser(
        uid: uid,
        email: email,
        displayName: displayName ?? this.displayName,
        role: role,
        createdAt: createdAt,
        lastSeenUpdates: lastSeenUpdates ?? this.lastSeenUpdates,
      );

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: (map['email'] as String?) ?? '',
      displayName: (map['displayName'] as String?) ?? '',
      role: UserRole.parse(map['role'] as String?),
      createdAt: _toDate(map['createdAt']) ?? DateTime.now(),
      lastSeenUpdates: _toDate(map['lastSeenUpdates']),
    );
  }

  /// Data written when a profile is first created. The role is always
  /// `student`: security rules forbid self-assigning `staff`.
  Map<String, dynamic> toCreateMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'role': UserRole.student.value,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static DateTime? _toDate(Object? value) =>
      value is Timestamp ? value.toDate() : null;
}
