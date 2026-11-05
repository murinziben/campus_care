import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../shared/profile_screen.dart';
import 'home_screen.dart';
import 'report_form_screen.dart';
import 'reports_screen.dart';
import 'updates_screen.dart';

/// Bottom-navigation container for the student experience.
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final lastSeen = context
        .select<AuthProvider, DateTime?>((a) => a.user?.lastSeenUpdates);
    final unread = context
        .select<IncidentProvider, int>((p) => p.unreadUpdates(lastSeen));

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onViewAll: () => _goTo(1), onOpenUpdates: () => _goTo(2), onOpenProfile: () => _goTo(3)),
          const ReportsScreen(),
          UpdatesScreen(active: _index == 2),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: _index <= 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const ReportFormScreen()),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Report'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home'),
          const NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt_rounded),
              label: 'Reports'),
          NavigationDestination(
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_none_rounded),
              ),
              selectedIcon: const Icon(Icons.notifications_rounded),
              label: 'Updates'),
          const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }
}
