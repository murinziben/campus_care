import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/incident_widgets.dart';
import 'incident_details_screen.dart';

class ReportSuccessScreen extends StatelessWidget {
  const ReportSuccessScreen({super.key, required this.incidentId});
  final String incidentId;

  @override
  Widget build(BuildContext context) {
    final incident = context.watch<IncidentProvider>().byId(incidentId);
    final shortId = incident?.shortId ??
        'CC-${incidentId.substring(0, incidentId.length < 6 ? incidentId.length : 6).toUpperCase()}';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                    color: AppColors.green50, shape: BoxShape.circle),
                child: Icon(Icons.check_rounded,
                    size: 48, color: AppColors.green),
              ),
              const SizedBox(height: 22),
              Text('REPORT SUBMITTED', style: AppText.eyebrow),
              const SizedBox(height: 8),
              Text('Thanks for speaking up.', style: AppText.h1),
              const SizedBox(height: 10),
              Text(
                "Your report has been sent to the campus operations team. "
                "We'll notify you when its status changes.",
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  children: [
                    Text('Report ID', style: AppText.muted),
                    const Spacer(),
                    Text(shortId,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(width: 10),
                    const StatusBadge(status: IncidentStatus.submitted),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              PrimaryButton(
                label: 'Track this report',
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        IncidentDetailsScreen(incidentId: incidentId),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
