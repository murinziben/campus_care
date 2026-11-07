import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../models/enums.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/form_widgets.dart';
import '../shared/incident_overview.dart';

/// Staff-only screen to review a report and change its status.
/// The UI check below is a convenience; Firestore security rules are the
/// real enforcement (students cannot write the status field).
class ManageIncidentScreen extends StatefulWidget {
  const ManageIncidentScreen({super.key, required this.incidentId});
  final String incidentId;

  @override
  State<ManageIncidentScreen> createState() => _ManageIncidentScreenState();
}

class _ManageIncidentScreenState extends State<ManageIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();
  IncidentStatus? _selected;
  bool _saved = false;
  late final Stream<List<StatusUpdate>> _updates;

  @override
  void initState() {
    super.initState();
    // One shared listener for the timeline and the activity list.
    _updates = context
        .read<IncidentProvider>()
        .watchUpdates(widget.incidentId)
        .asBroadcastStream();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<IncidentProvider>().clearActionError();
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(Incident incident) async {
    final target = _selected;
    if (target == null) return;
    if (!_formKey.currentState!.validate()) return;

    final ok = await confirmDialog(
      context,
      title: 'Confirm status change',
      message: 'Change this report from ${incident.status.label} to '
          '${target.label}? The student will be notified.',
      confirmLabel: 'Update status',
    );
    if (!ok || !mounted) return;

    final provider = context.read<IncidentProvider>();
    final success =
        await provider.updateStatus(incident, target, note: _note.text);
    if (!mounted) return;
    if (success) {
      setState(() {
        _saved = true;
        _selected = null;
        _note.clear();
      });
    }
  }

  Future<void> _delete(Incident incident) async {
    final provider = context.read<IncidentProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmDialog(
      context,
      title: 'Delete report?',
      message: 'Use this for spam or duplicates. It permanently removes the '
          'report and its history.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    final deleted = await provider.deleteReport(incident);
    if (deleted) {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Report deleted.')));
    } else {
      messenger.showSnackBar(
          SnackBar(content: Text(provider.actionError ?? 'Could not delete.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final auth = context.watch<AuthProvider>();
    final incident = provider.byId(widget.incidentId);

    if (!auth.isStaff) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Incident')),
        body: const EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Staff only',
          message: 'You are not authorized to manage incidents.',
        ),
      );
    }
    if (incident == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Incident')),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Report not available',
          message: 'It may have been deleted.',
        ),
      );
    }

    final changed = _selected != null && _selected != incident.status;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Incident'),
        actions: [
          IconButton(
            tooltip: 'Delete report',
            onPressed: () => _delete(incident),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          if (_saved) ...[
            InlineMessage(
              isError: false,
              message: 'Status updated. The student can see this change now.',
            ),
            const SizedBox(height: 14),
          ],
          IncidentOverview(incident: incident, showReporter: true),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings_outlined,
                          size: 20, color: AppColors.forest),
                      SizedBox(width: 8),
                      Text('Update report status', style: AppText.h3),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Only authorized staff can change this.',
                      style: AppText.muted),
                  const SizedBox(height: 14),
                  for (final s in IncidentStatus.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _StatusOption(
                        status: s,
                        current: s == incident.status,
                        selected: (_selected ?? incident.status) == s,
                        onTap: () => setState(() {
                          _selected = s;
                          _saved = false;
                        }),
                      ),
                    ),
                  const SizedBox(height: 6),
                  AppTextField(
                    label: 'Staff note',
                    hint: 'Add an update the student can see...',
                    controller: _note,
                    optional: true,
                    maxLines: 3,
                    maxLength: 500,
                    validator: Validators.staffNote,
                  ),
                  const SizedBox(height: 14),
                  if (provider.actionError != null) ...[
                    InlineMessage(message: provider.actionError!),
                    const SizedBox(height: 12),
                  ],
                  PrimaryButton(
                    label: 'Save status update',
                    loading: provider.isSubmitting,
                    onPressed: changed ? () => _save(incident) : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ProgressSection(incident: incident, updatesStream: _updates),
          const SizedBox(height: 16),
          _History(updates: _updates),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.status,
    required this.current,
    required this.selected,
    required this.onTap,
  });

  final IncidentStatus status;
  final bool current;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? status.background : AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
              color: selected ? status.color : AppColors.slate200,
              width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? status.color : AppColors.slate400,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(status.label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? status.color : AppColors.slate700)),
            ),
            if (current)
              Text('Current',
                  style: TextStyle(fontSize: 11, color: AppColors.slate500)),
          ],
        ),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.updates});
  final Stream<List<StatusUpdate>> updates;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StatusUpdate>>(
      stream: updates,
      builder: (context, snap) {
        final items = (snap.data ?? const <StatusUpdate>[]).reversed.toList();
        if (items.isEmpty) return const SizedBox.shrink();
        return SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Staff activity', style: AppText.h3),
              const SizedBox(height: 10),
              for (final u in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                            color: u.status.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(
                                text: '${u.staffName} set ${u.status.label}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            if (u.note.isNotEmpty) TextSpan(text: ' - ${u.note}'),
                          ]),
                          style: AppText.body.copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
