import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/incident_widgets.dart';
import 'manage_incident_screen.dart';

/// Staff "Incident workspace": live queue with overview numbers.
class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  // Tabs map onto statuses: Queue = newly submitted.
  static const _tabs = <String, IncidentStatus>{
    'Queue': IncidentStatus.submitted,
    'In Progress': IncidentStatus.inProgress,
    'Resolved': IncidentStatus.resolved,
  };

  String _tab = 'Queue';
  String _search = '';
  IncidentSort _sort = IncidentSort.priority;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<IncidentProvider>();
    final user = context.watch<AuthProvider>().user;
    final all = p.all;

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final open = all.where((i) => i.status != IncidentStatus.resolved).length;
    final fresh = p.count(all, IncidentStatus.submitted);
    final inProgress = p.count(all, IncidentStatus.inProgress);
    final resolvedToday = all
        .where((i) =>
            i.status == IncidentStatus.resolved &&
            i.updatedAt.isAfter(startOfToday))
        .length;

    final list = p.query(
      status: _tabs[_tab],
      search: _search,
      sort: _sort,
    );

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => p.retry(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CAMPUS OPERATIONS', style: AppText.eyebrow),
                      SizedBox(height: 2),
                      Text('Incident workspace', style: AppText.h2),
                    ],
                  ),
                ),
                AppAvatar(name: user?.displayName ?? '?'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.deepGreen,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Formatters.longDate(now),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('${Formatters.greeting(now: now).replaceAll(',', '')}, '
                      '${user?.firstName ?? ''}.',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _OverviewStat(label: 'Total open', value: open, big: true),
                      _OverviewStat(label: 'New', value: fresh),
                      _OverviewStat(label: 'In progress', value: inProgress),
                      _OverviewStat(label: 'Resolved today', value: resolvedToday),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search report ID, issue or location',
                prefixIcon:
                    Icon(Icons.search_rounded, color: AppColors.slate400),
              ),
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final t in _tabs.keys)
                  ButtonSegment(value: t, label: Text(t)),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_tab == 'Queue' ? 'Needs attention' : _tab,
                          style: AppText.h3.copyWith(fontSize: 16)),
                      Text('${list.length} report${list.length == 1 ? '' : 's'}',
                          style: AppText.muted),
                    ],
                  ),
                ),
                PopupMenuButton<IncidentSort>(
                  initialValue: _sort,
                  onSelected: (s) => setState(() => _sort = s),
                  itemBuilder: (_) => [
                    for (final s in IncidentSort.values)
                      PopupMenuItem(value: s, child: Text(s.label)),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_sort.label,
                            style: const TextStyle(
                                color: AppColors.forest,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        const Icon(Icons.expand_more_rounded,
                            color: AppColors.forest, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (p.isLoading && all.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (p.loadError != null && all.isEmpty)
              InlineMessage(message: p.loadError!)
            else if (list.isEmpty)
              EmptyState(
                icon: Icons.task_alt_rounded,
                title: _search.isEmpty ? 'All clear' : 'No matches',
                message: _search.isEmpty
                    ? 'There are no reports in this list right now.'
                    : 'Try a different search term.',
              )
            else
              for (final i in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: IncidentCard(
                    incident: i,
                    staffView: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ManageIncidentScreen(incidentId: i.id),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({
    required this.label,
    required this.value,
    this.big = false,
  });

  final String label;
  final int value;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: big ? 3 : 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Formatters.twoDigits(value),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: big ? 30 : 22,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 10.5)),
        ],
      ),
    );
  }
}
