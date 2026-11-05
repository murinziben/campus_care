import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/incident_widgets.dart';
import '../staff/manage_incident_screen.dart';
import 'incident_details_screen.dart';

/// Searchable, filterable list of reports.
/// Students can switch between "My reports" and the whole campus; staff
/// ([staffMode]) always see every report and open the management screen.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.staffMode = false});
  final bool staffMode;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search =
        TextEditingController(text: context.read<IncidentProvider>().search);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(Incident incident) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => widget.staffMode
          ? ManageIncidentScreen(incidentId: incident.id)
          : IncidentDetailsScreen(incidentId: incident.id),
    ));
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<IncidentProvider>();
    final list = widget.staffMode
        ? p.query(
            status: p.statusFilter,
            category: p.categoryFilter,
            search: p.search,
            sort: p.sort)
        : p.filtered;
    final filterCount = (p.categoryFilter != null ? 1 : 0) +
        (p.sort != IncidentSort.newest ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.staffMode ? 'All Reports' : 'Reports'),
        actions: [
          IconButton(
            tooltip: 'Filters',
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: filterCount > 0,
              label: Text('$filterCount'),
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: TextField(
              controller: _search,
              onChanged: context.read<IncidentProvider>().setSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search reports by title, place or ID',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.slate400),
                suffixIcon: p.search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded, size: 19),
                        onPressed: () {
                          _search.clear();
                          context.read<IncidentProvider>().setSearch('');
                        },
                      ),
              ),
            ),
          ),
          if (!widget.staffMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: SegmentedButton<ReportScope>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                      value: ReportScope.mine, label: Text('My reports')),
                  ButtonSegment(
                      value: ReportScope.campus, label: Text('Campus-wide')),
                ],
                selected: {p.scope},
                onSelectionChanged: (s) =>
                    context.read<IncidentProvider>().setScope(s.first),
              ),
            ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _StatusChip(
                  label: 'All',
                  selected: p.statusFilter == null,
                  onTap: () =>
                      context.read<IncidentProvider>().setStatusFilter(null),
                ),
                for (final s in IncidentStatus.values)
                  _StatusChip(
                    label: s.label,
                    selected: p.statusFilter == s,
                    onTap: () =>
                        context.read<IncidentProvider>().setStatusFilter(s),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('${list.length} report${list.length == 1 ? '' : 's'}',
                    style: AppText.muted),
                const Spacer(),
                if (p.hasActiveFilters || filterCount > 0)
                  TextButton(
                    onPressed: () {
                      _search.clear();
                      final prov = context.read<IncidentProvider>();
                      prov.clearFilters();
                      prov.setSort(IncidentSort.newest);
                    },
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildList(p, list)),
        ],
      ),
    );
  }

  Widget _buildList(IncidentProvider p, List<Incident> list) {
    if (p.isLoading && p.all.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (p.loadError != null && p.all.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        title: "Couldn't load reports",
        message: p.loadError!,
        actionLabel: 'Try again',
        onAction: p.retry,
      );
    }
    if (list.isEmpty) {
      final filtering = p.hasActiveFilters;
      return EmptyState(
        icon: filtering ? Icons.search_off_rounded : Icons.inbox_outlined,
        title: filtering ? 'No reports found' : 'Nothing here yet',
        message: filtering
            ? 'Try another search term or clear your current filters.'
            : (widget.staffMode || p.scope == ReportScope.campus
                ? 'No reports have been filed yet.'
                : "You haven't filed any reports yet."),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => p.retry(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, index) => IncidentCard(
          incident: list[index],
          staffView: widget.staffMode,
          onTap: () => _open(list[index]),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: AppColors.forest,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
          color: selected ? Colors.white : AppColors.slate700,
        ),
        side: BorderSide(
            color: selected ? AppColors.forest : AppColors.slate200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<IncidentProvider>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter & sort', style: AppText.h2),
            const SizedBox(height: 18),
            const Text('CATEGORY', style: AppText.eyebrow),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: p.categoryFilter == null,
                  onSelected: (_) =>
                      context.read<IncidentProvider>().setCategoryFilter(null),
                ),
                for (final c in IncidentCategory.values)
                  ChoiceChip(
                    avatar: Icon(c.icon, size: 16, color: c.color),
                    label: Text(c.label),
                    selected: p.categoryFilter == c,
                    onSelected: (_) =>
                        context.read<IncidentProvider>().setCategoryFilter(c),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('SORT BY', style: AppText.eyebrow),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final s in IncidentSort.values)
                  ChoiceChip(
                    label: Text(s.label),
                    selected: p.sort == s,
                    onSelected: (_) =>
                        context.read<IncidentProvider>().setSort(s),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            PrimaryButtonDone(onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

class PrimaryButtonDone extends StatelessWidget {
  const PrimaryButtonDone({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      FilledButton(onPressed: onPressed, child: const Text('Show results'));
}
