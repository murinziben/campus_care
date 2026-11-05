import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../models/enums.dart';
import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/incident_widgets.dart';
import 'report_success_screen.dart';

/// Create a report, or edit one when [existing] is given (students may edit
/// only while the report is still "Submitted").
///
/// Two pages with a four-stage progress indicator:
///   page 1 = Category + Details, page 2 = Location + Photo + Submit.
class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key, this.existing});
  final Incident? existing;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _detailsKey = GlobalKey<FormState>();
  final _locationKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _building;
  late final TextEditingController _room;
  late IncidentCategory _category;
  late bool _urgent;

  int _page = 0; // 0 = category + details, 1 = location + photo
  File? _photo; // newly picked photo
  bool _removeExistingPhoto = false;
  String? _photoError;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _building = TextEditingController(text: e?.building ?? '');
    _room = TextEditingController(text: e?.room ?? '');
    _category = e?.category ?? IncidentCategory.facilities;
    _urgent = e?.isUrgent ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<IncidentProvider>().clearActionError();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _building.dispose();
    _room.dispose();
    super.dispose();
  }

  void _next() {
    if (!_detailsKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _page = 1);
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (picked == null) return;
      final file = File(picked.path);
      if (await file.length() > AppConstants.maxPhotoBytes) {
        setState(() => _photoError = 'That photo is larger than 5 MB.');
        return;
      }
      setState(() {
        _photo = file;
        _photoError = null;
        _removeExistingPhoto = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _photoError =
          'Could not open the camera or gallery. Check app permissions.');
    }
  }

  Future<void> _submit() async {
    if (!_locationKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final provider = context.read<IncidentProvider>();

    if (_isEdit) {
      final ok = await provider.editReport(
        widget.existing!,
        title: _title.text,
        description: _description.text,
        category: _category,
        building: _building.text,
        room: _room.text,
        isUrgent: _urgent,
        newPhoto: _photo,
        removePhoto: _removeExistingPhoto,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
        showSnack(context, 'Report updated.');
      }
      return;
    }

    final id = await provider.submitReport(
      title: _title.text,
      description: _description.text,
      category: _category,
      building: _building.text,
      room: _room.text,
      isUrgent: _urgent,
      photo: _photo,
    );
    if (!mounted || id == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
          builder: (_) => ReportSuccessScreen(incidentId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();

    return PopScope(
      // On page 2 the system back button returns to page 1 first.
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _page = 0);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit Report' : 'Report an Issue'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (_page == 1) {
                setState(() => _page = 0);
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              _StepIndicator(activeIndex: _page == 0 ? 1 : 3),
              const SizedBox(height: 22),
              if (_page == 0)
                _buildDetailsPage()
              else
                _buildLocationPage(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsPage() {
    return Form(
      key: _detailsKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isEdit ? 'Update your report' : 'Choose a category',
              style: AppText.h2),
          const SizedBox(height: 2),
          const Text('Select the closest match', style: AppText.muted),
          const SizedBox(height: 12),
          CategoryPicker(
            selected: _category,
            onChanged: (c) => setState(() {
              _category = c;
              // Safety issues default to urgent, but the user can undo it.
              if (c == IncidentCategory.safety) _urgent = true;
            }),
          ),
          const SizedBox(height: 24),
          const Text('Incident details', style: AppText.h2),
          const SizedBox(height: 2),
          const Text('Describe what needs attention', style: AppText.muted),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Incident title *',
            hint: 'e.g. Leaking tap in washroom',
            controller: _title,
            maxLength: 80,
            textInputAction: TextInputAction.next,
            validator: Validators.title,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Description *',
            hint:
                'What happened? Include details that could help the response team.',
            controller: _description,
            maxLines: 4,
            maxLength: 1000,
            keyboardType: TextInputType.multiline,
            validator: Validators.description,
          ),
          const SizedBox(height: 8),
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('This is urgent', style: AppText.h3),
                      SizedBox(height: 2),
                      Text(
                          'Use for safety risks or issues affecting many people.',
                          style: AppText.muted),
                    ],
                  ),
                ),
                Switch(
                  value: _urgent,
                  onChanged: (v) => setState(() => _urgent = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Next: Location',
            icon: Icons.arrow_forward_rounded,
            onPressed: _next,
          ),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPage(IncidentProvider provider) {
    final existingPhoto = widget.existing?.photoUrl;
    final showExisting = _isEdit &&
        existingPhoto != null &&
        _photo == null &&
        !_removeExistingPhoto;

    return Form(
      key: _locationKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Location', style: AppText.h2),
          const SizedBox(height: 2),
          const Text('Help staff find the issue', style: AppText.muted),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Building or area *',
            hint: 'e.g. Block B',
            controller: _building,
            icon: Icons.apartment_rounded,
            textInputAction: TextInputAction.next,
            validator: Validators.building,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Room or nearby landmark',
            hint: 'e.g. Room 204',
            controller: _room,
            icon: Icons.meeting_room_outlined,
            optional: true,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('Add a photo', style: AppText.h2),
              const SizedBox(width: 8),
              const Text('(Optional)', style: AppText.muted),
            ],
          ),
          const SizedBox(height: 2),
          const Text('A photo can make the issue clearer', style: AppText.muted),
          const SizedBox(height: 12),
          _PhotoSection(
            file: _photo,
            existingUrl: showExisting ? existingPhoto : null,
            onPick: _pickPhoto,
            onRemove: () => setState(() {
              _photo = null;
              _removeExistingPhoto = true;
            }),
          ),
          if (_photoError != null) ...[
            const SizedBox(height: 8),
            InlineMessage(message: _photoError!),
          ],
          const SizedBox(height: 24),
          if (provider.actionError != null) ...[
            InlineMessage(message: provider.actionError!),
            const SizedBox(height: 12),
          ],
          PrimaryButton(
            label: _isEdit ? 'Save Changes' : 'Submit Report',
            icon: Icons.arrow_forward_rounded,
            loading: provider.isSubmitting,
            onPressed: _submit,
          ),
          Center(
            child: TextButton(
              onPressed:
                  provider.isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Four-stage progress indicator: Category, Details, Location, Photo.
/// Stages before [activeIndex] are shown as completed.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.activeIndex});
  final int activeIndex;

  static const _labels = ['Category', 'Details', 'Location', 'Photo'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: i == 0
                          ? const SizedBox()
                          : Container(
                              height: 2,
                              color: i <= activeIndex
                                  ? AppColors.forest
                                  : AppColors.slate200,
                            ),
                    ),
                    _Dot(
                      number: i + 1,
                      done: i < activeIndex,
                      active: i == activeIndex,
                    ),
                    Expanded(
                      child: i == _labels.length - 1
                          ? const SizedBox()
                          : Container(
                              height: 2,
                              color: i < activeIndex
                                  ? AppColors.forest
                                  : AppColors.slate200,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight:
                        i == activeIndex ? FontWeight.w800 : FontWeight.w500,
                    color: i <= activeIndex
                        ? AppColors.deepGreen
                        : AppColors.slate400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.number, required this.done, required this.active});
  final int number;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final filled = done || active;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: filled ? AppColors.forest : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
            color: filled ? AppColors.forest : AppColors.slate300, width: 1.6),
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : Text(
                '$number',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: filled ? Colors.white : AppColors.slate400,
                ),
              ),
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.file,
    required this.existingUrl,
    required this.onPick,
    required this.onRemove,
  });

  final File? file;
  final String? existingUrl;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (file == null && existingUrl == null) {
      return InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          height: 130,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.lightGreen.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.forest.withValues(alpha: 0.45)),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_camera_outlined,
                  color: AppColors.forest, size: 30),
              SizedBox(height: 8),
              Text('Take or upload a photo',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.deepGreen)),
              SizedBox(height: 2),
              Text('JPG or PNG, up to 5 MB', style: AppText.muted),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: file != null
                ? Image.file(file!, fit: BoxFit.cover)
                : Image.network(existingUrl!, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text('Replace'),
            ),
            TextButton.icon(
              onPressed: onRemove,
              style: TextButton.styleFrom(foregroundColor: AppColors.red),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Remove'),
            ),
          ],
        ),
      ],
    );
  }
}
