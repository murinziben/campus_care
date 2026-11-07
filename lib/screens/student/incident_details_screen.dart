import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/common.dart';
import '../shared/incident_overview.dart';
import 'report_form_screen.dart';

/// Student view of a single report with live status tracking.
class IncidentDetailsScreen extends StatelessWidget {
  const IncidentDetailsScreen({super.key, required this.incidentId});
  final String incidentId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final uid = context.watch<AuthProvider>().user?.uid;
    final incident = provider.byId(incidentId);

    if (incident == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incident Details')),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : const EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Report not available',
                message: 'It may have been deleted.',
              ),
      );
    }

    final isOwner = uid != null && incident.isOwnedBy(uid);
    final canModify = isOwner && incident.isEditableByOwner;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
        actions: [
          if (canModify)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => ReportFormScreen(existing: incident)));
                } else {
                  final p = context.read<IncidentProvider>();
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await confirmDialog(
                    context,
                    title: 'Delete this report?',
                    message: 'This cannot be undone.',
                    confirmLabel: 'Delete',
                    destructive: true,
                  );
                  if (!ok) return;
                  final deleted = await p.deleteReport(incident);
                  if (deleted) {
                    navigator.pop();
                    messenger.showSnackBar(
                        const SnackBar(content: Text('Report deleted.')));
                  } else {
                    messenger.showSnackBar(SnackBar(
                        content: Text(p.actionError ?? 'Could not delete.')));
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit report')),
                PopupMenuItem(value: 'delete', child: Text('Delete report')),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          IncidentOverview(incident: incident, showReporter: isOwner),
          const SizedBox(height: 16),
          ProgressSection(incident: incident),
          if (incident.hasStaffNote) ...[
            const SizedBox(height: 16),
            StaffNoteCard(incident: incident),
          ],
          if (isOwner && !incident.isEditableByOwner) ...[
            const SizedBox(height: 16),
            Text(
              'This report is being handled by staff, so it can no longer be '
              'edited or deleted.',
              style: AppText.muted,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
