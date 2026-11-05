import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/incident_widgets.dart';

/// Read-only summary of a report shared by the student details screen and the
/// staff "manage" screen: title, badges, photo, description and facts.
class IncidentOverview extends StatelessWidget {
  const IncidentOverview({
    super.key,
    required this.incident,
    this.showReporter = false,
  });

  final Incident incident;

  /// Reporter identity is only shown to the owner and to staff.
  final bool showReporter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CategoryIcon(category: incident.category, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(incident.title, style: AppText.h1.copyWith(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text('Report #${incident.shortId}', style: AppText.muted),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (incident.isUrgent) const UrgentBadge(),
            StatusBadge(status: incident.status),
          ],
        ),
        const SizedBox(height: 16),
        if (incident.hasPhoto) ...[
          IncidentPhoto(url: incident.photoUrl!),
          const SizedBox(height: 16),
        ],
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: [
            _InfoTile(
                icon: Icons.place_outlined,
                label: 'Location',
                value: incident.location),
            _InfoTile(
                icon: incident.category.icon,
                label: 'Category',
                value: incident.category.label),
            if (showReporter)
              _InfoTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Reported by',
                  value: incident.reporterName),
            _InfoTile(
                icon: Icons.event_outlined,
                label: 'Submitted',
                value: Formatters.friendlyDate(incident.createdAt)),
          ],
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('About this report', style: AppText.h3),
              const SizedBox(height: 8),
              Text(incident.description, style: AppText.body),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppColors.forest),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10.5, color: AppColors.slate500)),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows "Resolution progress" using the live status history.
/// Pass [updatesStream] to share one Firestore listener with another widget;
/// otherwise this widget opens (and closes) its own.
class ProgressSection extends StatefulWidget {
  const ProgressSection({
    super.key,
    required this.incident,
    this.updatesStream,
  });

  final Incident incident;
  final Stream<List<StatusUpdate>>? updatesStream;

  @override
  State<ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<ProgressSection> {
  late final Stream<List<StatusUpdate>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = widget.updatesStream ??
        context.read<IncidentProvider>().watchUpdates(widget.incident.id);
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                  child: Text('Resolution progress', style: AppText.h3)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.green50,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text('Live updates',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<StatusUpdate>>(
            stream: _stream,
            builder: (context, snapshot) => StatusTimeline(
              current: widget.incident.status,
              updates: snapshot.data ?? const [],
            ),
          ),
        ],
      ),
    );
  }
}

/// Latest note left by staff, shown to the student.
class StaffNoteCard extends StatelessWidget {
  const StaffNoteCard({super.key, required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent_rounded,
                  size: 18, color: AppColors.forest),
              const SizedBox(width: 8),
              const Text('Campus team update',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.forest)),
              const Spacer(),
              Text(Formatters.friendlyDate(incident.updatedAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.forest)),
            ],
          ),
          const SizedBox(height: 8),
          Text(incident.staffNote, style: AppText.body),
        ],
      ),
    );
  }
}
