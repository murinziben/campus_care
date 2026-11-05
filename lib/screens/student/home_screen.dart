import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/campus_illustration.dart';
import '../../widgets/common.dart';
import '../../widgets/incident_widgets.dart';
import 'incident_details_screen.dart';
import 'report_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onViewAll,
    required this.onOpenUpdates,
    required this.onOpenProfile,
  });

  final VoidCallback onViewAll;
  final VoidCallback onOpenUpdates;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final incidents = context.watch<IncidentProvider>();
    final mine = incidents.mine;
    final recent = mine.take(3).toList();
    final hasUnread = incidents.unreadUpdates(user?.lastSeenUpdates) > 0;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => incidents.retry(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Formatters.greeting(), style: AppText.muted),
                      Text(user?.firstName ?? '', style: AppText.h2),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Updates',
                  onPressed: onOpenUpdates,
                  icon: Badge(
                    isLabelVisible: hasUnread,
                    smallSize: 9,
                    child: const Icon(Icons.notifications_none_rounded),
                  ),
                ),
                GestureDetector(
                  onTap: onOpenProfile,
                  child: AppAvatar(name: user?.displayName ?? '?'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _HeroCard(
              onReport: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const ReportFormScreen()),
              ),
            ),
            const SizedBox(height: 22),
            const SectionHeading(
                eyebrow: 'My reports', title: 'Your impact at a glance'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                      value: mine.length,
                      label: 'Total',
                      icon: Icons.bar_chart_rounded,
                      color: AppColors.forest,
                      background: AppColors.lightGreen),
                ),
                const SizedBox(width: 8),
                for (final s in IncidentStatus.values) ...[
                  Expanded(
                    child: StatTile(
                        value: incidents.count(mine, s),
                        label: s == IncidentStatus.inProgress
                            ? 'In progress'
                            : s.label,
                        icon: switch (s) {
                          IncidentStatus.submitted => Icons.send_rounded,
                          IncidentStatus.inProgress => Icons.schedule_rounded,
                          IncidentStatus.resolved =>
                            Icons.check_circle_outline_rounded,
                        },
                        color: s.color,
                        background: s.background),
                  ),
                  if (s != IncidentStatus.values.last) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 22),
            SectionHeading(
                title: 'Recent reports',
                actionLabel: 'View all',
                onAction: onViewAll),
            const SizedBox(height: 10),
            if (incidents.isLoading && mine.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (incidents.loadError != null && mine.isEmpty)
              InlineMessage(message: incidents.loadError!)
            else if (recent.isEmpty)
              const EmptyState(
                icon: Icons.inbox_outlined,
                title: "You haven't reported anything yet",
                message: 'Tap Report to tell campus operations about an issue.',
              )
            else
              for (final i in recent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: IncidentCard(
                    incident: i,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) =>
                              IncidentDetailsScreen(incidentId: i.id)),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onReport});
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.deepGreen, AppColors.forest],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Stack(
        children: [
          const Positioned(
            right: 4,
            bottom: 0,
            child: CampusIllustration(width: 150, height: 112),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco_rounded,
                        size: 14, color: Colors.white.withValues(alpha: 0.85)),
                    const SizedBox(width: 6),
                    Text('CAMPUSCARE',
                        style: AppText.eyebrow.copyWith(
                            color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  "Let's improve our\ncampus together.",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      height: 1.18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 190,
                  child: Text(
                    'Spot something that needs attention? Let the right team know.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onReport,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Report an Issue'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.forest,
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
