import 'package:flutter/material.dart';

import '../core/theme.dart';

enum UserRole {
  student,
  staff;

  String get value => name;

  static UserRole parse(String? raw) =>
      raw == 'staff' ? UserRole.staff : UserRole.student;
}

/// Lifecycle of a report: submitted -> in progress -> resolved.
enum IncidentStatus {
  submitted('submitted', 'Submitted'),
  inProgress('in_progress', 'In Progress'),
  resolved('resolved', 'Resolved');

  const IncidentStatus(this.value, this.label);

  /// Value persisted in Firestore (also referenced by security rules).
  final String value;
  final String label;

  static IncidentStatus parse(String? raw) => IncidentStatus.values.firstWhere(
        (s) => s.value == raw,
        orElse: () => IncidentStatus.submitted,
      );

  Color get color => switch (this) {
        IncidentStatus.submitted => AppColors.orange,
        IncidentStatus.inProgress => AppColors.amber,
        IncidentStatus.resolved => AppColors.green,
      };

  Color get background => switch (this) {
        IncidentStatus.submitted => AppColors.orange50,
        IncidentStatus.inProgress => AppColors.amber50,
        IncidentStatus.resolved => AppColors.green50,
      };

  String get description => switch (this) {
        IncidentStatus.submitted => 'Report received and awaiting review',
        IncidentStatus.inProgress => 'Campus team is addressing the issue',
        IncidentStatus.resolved => 'Issue fixed and report closed',
      };
}

enum IncidentCategory {
  facilities('facilities', 'Facilities', Icons.apartment_rounded,
      AppColors.forest, AppColors.lightGreen),
  water('water', 'Water', Icons.water_drop_outlined, AppColors.sky,
      AppColors.sky50),
  electricity('electricity', 'Electricity', Icons.bolt_rounded,
      AppColors.warmOrange, AppColors.amber50),
  safety('safety', 'Safety', Icons.shield_outlined, AppColors.red,
      AppColors.red50),
  sanitation('sanitation', 'Sanitation', Icons.delete_outline_rounded,
      AppColors.green, AppColors.green50),
  other('other', 'Other', Icons.more_horiz_rounded, AppColors.slate700,
      AppColors.slate100);

  const IncidentCategory(
      this.value, this.label, this.icon, this.color, this.background);

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  static IncidentCategory parse(String? raw) =>
      IncidentCategory.values.firstWhere(
        (c) => c.value == raw,
        orElse: () => IncidentCategory.other,
      );
}

enum ReportScope { mine, campus }

enum IncidentSort {
  newest('Newest first'),
  oldest('Oldest first'),
  priority('Urgent first');

  const IncidentSort(this.label);
  final String label;
}
