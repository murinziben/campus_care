import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/banner_carousel.dart';
import '../../widgets/common.dart';
import '../../widgets/incident_widgets.dart';
import 'incident_details_screen.dart';
import 'report_form_screen.dart';

/// Student home: location header, search, banner carousel, category
/// shortcuts, personal stats, recent reports and a trust strip.
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

  void _report(BuildContext context, [IncidentCategory? category]) {
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ReportFormScreen(initialCategory: category)));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final incidents = context.watch<IncidentProvider>();
    final mine = incidents.mine;
    final recent = mine.take(6).toList();
    final hasUnread = incidents.unreadUpdates(user?.lastSeenUpdates) > 0;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => incidents.retry(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 96),
          children: [
            _Header(
              firstName: user?.firstName ?? '',
              name: user?.displayName ?? '?',
              hasUnread: hasUnread,
              onOpenUpdates: onOpenUpdates,
              onOpenProfile: onOpenProfile,
            ),
            const SizedBox(height: 14),
            _SearchBar(onTap: onViewAll),
            const SizedBox(height: 16),
            BannerCarousel(
              onReport: () => _report(context),
              onTrack: onViewAll,
              onUpdates: onOpenUpdates,
            ),
            const SizedBox(height: 18),
            const SectionHeading(
                eyebrow: 'Quick report', title: 'What needs attention?'),
            const SizedBox(height: 12),
            _CategoryGrid(
              onCategory: (c) => _report(context, c),
              onReports: onViewAll,
              onUpdates: onOpenUpdates,
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
              SizedBox(
                height: 214,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: recent.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _RecentCard(
                    incident: recent[i],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) =>
                              IncidentDetailsScreen(incidentId: recent[i].id)),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 22),
            const _TrustStrip(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.firstName,
    required this.name,
    required this.hasUnread,
    required this.onOpenUpdates,
    required this.onOpenProfile,
  });

  final String firstName;
  final String name;
  final bool hasUnread;
  final VoidCallback onOpenUpdates;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: AppColors.lightGreen, shape: BoxShape.circle),
          child: Icon(Icons.location_on_rounded,
              color: AppColors.forest, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${Formatters.greeting()} $firstName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.h3),
              Text('Reporting to ALU campus operations',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.muted),
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
          child: AppAvatar(name: name),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.field),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: AppColors.slate400),
              SizedBox(width: 10),
              Expanded(
                child: Text('Search reports by title, place or ID',
                    style: TextStyle(color: AppColors.slate500, fontSize: 13.5)),
              ),
              Icon(Icons.tune_rounded, color: AppColors.slate400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.onCategory,
    required this.onReports,
    required this.onUpdates,
  });

  final ValueChanged<IncidentCategory> onCategory;
  final VoidCallback onReports;
  final VoidCallback onUpdates;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      for (final c in IncidentCategory.values)
        _GridTile(
            icon: c.icon,
            label: c.label,
            color: c.color,
            onTap: () => onCategory(c)),
      _GridTile(
          icon: Icons.list_alt_rounded,
          label: 'My reports',
          color: AppColors.forest,
          onTap: onReports),
      _GridTile(
          icon: Icons.notifications_none_rounded,
          label: 'Updates',
          color: AppColors.forest,
          onTap: onUpdates),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.86,
      children: tiles,
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.field),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(color: AppColors.slate200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(height: 8),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.incident, required this.onTap});
  final Incident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cat = incident.category;
    return SizedBox(
      width: 212,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.slate200),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (incident.hasPhoto)
                        Image.network(
                          incident.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _PhotoFallback(cat: cat),
                        )
                      else
                        _PhotoFallback(cat: cat),
                      if (incident.isUrgent)
                        const Positioned(
                            top: 8, left: 8, child: UrgentBadge()),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(incident.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.place_outlined,
                              size: 13, color: AppColors.slate500),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(incident.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.slate500)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          StatusBadge(status: incident.status),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                                Formatters.friendlyDate(incident.createdAt),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.slate500)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({required this.cat});
  final IncidentCategory cat;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightGreen,
      alignment: Alignment.center,
      child: Icon(cat.icon, size: 34, color: AppColors.forest),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.verified_user_outlined, 'Verified\nALU only'),
      (Icons.visibility_outlined, 'Transparent\nstatus'),
      (Icons.bolt_rounded, 'Fast campus\nresponse'),
      (Icons.timeline_rounded, 'Live\ntracking'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.slate200),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          for (final (icon, label) in items)
            Expanded(
              child: Column(
                children: [
                  Icon(icon, color: AppColors.forest, size: 22),
                  const SizedBox(height: 6),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate700)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
