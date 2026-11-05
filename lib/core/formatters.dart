import 'package:intl/intl.dart';

/// Date helpers used across the UI.
class Formatters {
  Formatters._();

  /// "Today, 9:24 AM", "Yesterday, 4:10 PM" or "Oct 18, 2:15 PM".
  static String friendlyDate(DateTime date, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final d = DateTime(date.year, date.month, date.day);
    final t = DateTime(today.year, today.month, today.day);
    final diff = t.difference(d).inDays;
    final time = DateFormat.jm().format(date);
    if (diff == 0) return 'Today, $time';
    if (diff == 1) return 'Yesterday, $time';
    return '${DateFormat.MMMd().format(date)}, $time';
  }

  static String greeting({DateTime? now}) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  static String longDate(DateTime date) => DateFormat('EEEE, MMMM d').format(date);

  static String initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  static String twoDigits(int n) => n.toString().padLeft(2, '0');
}
