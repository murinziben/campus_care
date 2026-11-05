import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/common.dart';
import 'incident_details_screen.dart';

/// Feed of staff activity on the student's own reports.
class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key, required this.active});

  /// True while this tab is visible; opening it marks everything as read.
  final bool active;

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  // The "unread" cut-off is remembered so dots stay visible while the tab is
  // open, even though lastSeen is updated in the background.
  DateTime? _seenAtOpen;
  bool _wasActive = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncActive();
  }

  @override
  void didUpdateWidget(covariant UpdatesScreen old) {
    super.didUpdateWidget(old);
    _syncActive();
  }

  void _syncActive() {
    if (widget.active && !_wasActive) {
      _seenAtOpen = context.read<AuthProvider>().user?.lastSeenUpdates;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<AuthProvider>().markUpdatesSeen();
      });
    }
    _wasActive = widget.active;
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<IncidentProvider>().updatesFeed;

    return Scaffold(
      appBar: AppBar(title: const Text('Updates')),
      body: feed.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No updates yet',
              message:
                  "When campus staff respond to one of your reports, you'll see it here.",
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              itemCount: feed.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final item = feed[i];
                final unread = _seenAtOpen == null ||
                    item.updatedAt.isAfter(_seenAtOpen!);
                return _UpdateTile(incident: item, unread: unread);
              },
            ),
    );
  }
}

class _UpdateTile extends StatelessWidget {
  const _UpdateTile({required this.incident, required this.unread});
  final Incident incident;
  final bool unread;

  String get _headline => switch (incident.status) {
        IncidentStatus.resolved => 'Your report was resolved',
        IncidentStatus.inProgress => 'Staff are working on your report',
        IncidentStatus.submitted => 'Staff left a note on your report',
      };

  @override
  Widget build(BuildContext context) {
    final s = incident.status;
    return SurfaceCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => IncidentDetailsScreen(incidentId: incident.id))),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: s.background,
            child: Icon(
              s == IncidentStatus.resolved
                  ? Icons.check_circle_outline_rounded
                  : Icons.autorenew_rounded,
              color: s.color,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_headline, style: AppText.h3),
                const SizedBox(height: 2),
                Text(
                  incident.hasStaffNote
                      ? '"${incident.title}": ${incident.staffNote}'
                      : '"${incident.title}" is now ${s.label}.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(Formatters.friendlyDate(incident.updatedAt),
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.slate400)),
              ],
            ),
          ),
          if (unread)
            Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.only(top: 6),
              decoration: const BoxDecoration(
                  color: AppColors.forest, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
