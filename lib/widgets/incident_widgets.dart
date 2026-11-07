import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/enums.dart';
import '../models/incident.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class UrgentBadge extends StatelessWidget {
  const UrgentBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.red50,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        'Urgent',
        style: TextStyle(
          color: AppColors.red,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.category, this.size = 44});
  final IncidentCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(category.icon, color: category.color, size: size * 0.5),
    );
  }
}

/// A report in a list. [staffView] shows the urgent flag in place of the
/// status chip and the ticket number underneath (as in the staff mockup).
class IncidentCard extends StatelessWidget {
  const IncidentCard({
    super.key,
    required this.incident,
    required this.onTap,
    this.staffView = false,
  });

  final Incident incident;
  final VoidCallback onTap;
  final bool staffView;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.slate200),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryIcon(category: incident.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            incident.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.h3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (staffView && incident.isUrgent)
                          const UrgentBadge()
                        else
                          StatusBadge(status: incident.status),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      incident.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.muted,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${incident.category.label}  •  '
                      '${Formatters.friendlyDate(incident.createdAt)}',
                      style: TextStyle(
                          fontSize: 11.5, color: AppColors.slate400),
                    ),
                    if (staffView) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          StatusBadge(status: incident.status),
                          const SizedBox(width: 8),
                          Text('#${incident.shortId}',
                              style: TextStyle(
                                  fontSize: 11.5, color: AppColors.slate500)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid of selectable category tiles.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final IncidentCategory selected;
  final ValueChanged<IncidentCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: [
        for (final c in IncidentCategory.values)
          _CategoryTile(
            category: c,
            selected: c == selected,
            onTap: () => onChanged(c),
          ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final IncidentCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: category.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: selected ? AppColors.lightGreen : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? AppColors.forest : AppColors.slate200,
              width: selected ? 1.8 : 1,
            ),
            boxShadow: selected ? null : AppShadows.card,
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(category.icon,
                        color: selected ? AppColors.forest : category.color,
                        size: 28),
                    const SizedBox(height: 6),
                    Text(
                      category.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.slate950
                            : AppColors.slate700,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: AppColors.forest,
                    child: Icon(Icons.check_rounded,
                        size: 12, color: AppColors.ink),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three-step progress timeline (Submitted -> In Progress -> Resolved).
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.current, this.updates = const []});

  final IncidentStatus current;
  final List<StatusUpdate> updates;

  @override
  Widget build(BuildContext context) {
    final steps = IncidentStatus.values;
    final currentIndex = steps.indexOf(current);

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineStep(
            status: steps[i],
            index: i,
            done: i <= currentIndex,
            isCurrent: i == currentIndex,
            isLast: i == steps.length - 1,
            detail: _detailFor(steps[i]),
          ),
      ],
    );
  }

  /// Latest staff update recorded for [status], if any.
  StatusUpdate? _detailFor(IncidentStatus status) {
    for (final u in updates.reversed) {
      if (u.status == status) return u;
    }
    return null;
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.status,
    required this.index,
    required this.done,
    required this.isCurrent,
    required this.isLast,
    required this.detail,
  });

  final IncidentStatus status;
  final int index;
  final bool done;
  final bool isCurrent;
  final bool isLast;
  final StatusUpdate? detail;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.forest : AppColors.slate300;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: done ? color : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.2),
                              spreadRadius: 4,
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: done && !isCurrent
                        ? Icon(Icons.check, size: 14, color: AppColors.ink)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: done ? AppColors.ink : AppColors.slate400,
                            ),
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: done && !isCurrent
                          ? AppColors.forest
                          : AppColors.slate200,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: done ? AppColors.slate950 : AppColors.slate400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail != null && done
                        ? Formatters.friendlyDate(detail!.createdAt)
                        : status.description,
                    style: AppText.muted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Network photo with loading + error states; tap to view full screen.
class IncidentPhoto extends StatelessWidget {
  const IncidentPhoto({super.key, required this.url, this.height = 190});
  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => _FullScreenPhoto(url: url)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : ColoredBox(
                        color: AppColors.slate100,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                errorBuilder: (_, _, _) => ColoredBox(
                  color: AppColors.slate100,
                  child: Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: AppColors.slate400, size: 36),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_camera_outlined,
                          size: 14, color: Colors.white),
                      SizedBox(width: 5),
                      Text('Photo attached',
                          style: TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullScreenPhoto extends StatelessWidget {
  const _FullScreenPhoto({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Photo', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
