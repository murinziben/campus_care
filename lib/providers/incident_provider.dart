import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/incident.dart';
import '../repositories/incident_repository.dart';
import '../repositories/storage_repository.dart';

/// Holds every incident the signed-in user may read (a live Firestore stream)
/// plus the list filters, and exposes the create / edit / delete / status
/// actions. All screens read from this single source of truth, so a status
/// change made by staff appears everywhere without manual refreshes.
class IncidentProvider extends ChangeNotifier {
  IncidentProvider(this._incidents, this._storage);

  final IncidentRepository _incidents;
  final StorageRepository _storage;

  AppUser? _user;
  StreamSubscription<List<Incident>>? _sub;

  List<Incident> _all = const [];
  bool _loading = false;
  String? _loadError;
  bool _submitting = false;
  String? _actionError;

  // Filters for the student "All Reports" list.
  String _search = '';
  IncidentStatus? _statusFilter;
  IncidentCategory? _categoryFilter;
  ReportScope _scope = ReportScope.mine;
  IncidentSort _sort = IncidentSort.newest;

  // ---- read-only state ---------------------------------------------------
  List<Incident> get all => _all;
  bool get isLoading => _loading;
  String? get loadError => _loadError;
  bool get isSubmitting => _submitting;
  String? get actionError => _actionError;

  String get search => _search;
  IncidentStatus? get statusFilter => _statusFilter;
  IncidentCategory? get categoryFilter => _categoryFilter;
  ReportScope get scope => _scope;
  IncidentSort get sort => _sort;
  bool get hasActiveFilters =>
      _search.isNotEmpty || _statusFilter != null || _categoryFilter != null;

  /// Reports filed by the signed-in user.
  List<Incident> get mine {
    final uid = _user?.uid;
    if (uid == null) return const [];
    return _all.where((i) => i.reporterId == uid).toList();
  }

  /// The student list after scope, search, status and category filters.
  List<Incident> get filtered => query(
        reporterId: _scope == ReportScope.mine ? _user?.uid : null,
        status: _statusFilter,
        category: _categoryFilter,
        search: _search,
        sort: _sort,
      );

  /// Pure query used by both the student list and the staff queue.
  List<Incident> query({
    String? reporterId,
    IncidentStatus? status,
    IncidentCategory? category,
    String search = '',
    IncidentSort sort = IncidentSort.newest,
  }) {
    final result = _all.where((i) {
      if (reporterId != null && i.reporterId != reporterId) return false;
      if (status != null && i.status != status) return false;
      if (category != null && i.category != category) return false;
      return i.matches(search);
    }).toList();

    switch (sort) {
      case IncidentSort.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case IncidentSort.oldest:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case IncidentSort.priority:
        result.sort((a, b) {
          if (a.isUrgent != b.isUrgent) return a.isUrgent ? -1 : 1;
          return a.createdAt.compareTo(b.createdAt);
        });
    }
    return result;
  }

  Incident? byId(String id) {
    for (final i in _all) {
      if (i.id == id) return i;
    }
    return null;
  }

  int count(Iterable<Incident> list, IncidentStatus status) =>
      list.where((i) => i.status == status).length;

  /// Student's reports that staff have touched, newest activity first.
  List<Incident> get updatesFeed {
    final list = mine
        .where((i) => i.status != IncidentStatus.submitted || i.hasStaffNote)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  int unreadUpdates(DateTime? lastSeen) {
    if (lastSeen == null) return updatesFeed.length;
    return updatesFeed.where((i) => i.updatedAt.isAfter(lastSeen)).length;
  }

  Stream<List<StatusUpdate>> watchUpdates(String incidentId) =>
      _incidents.watchUpdates(incidentId);

  // ---- session binding ---------------------------------------------------

  /// Called by ChangeNotifierProxyProvider whenever the auth state changes.
  /// Does not notify: it runs during the widget build phase.
  void bindUser(AppUser? user) {
    if (user?.uid == _user?.uid) {
      _user = user;
      return;
    }
    _sub?.cancel();
    _sub = null;
    _user = user;
    _all = const [];
    _loadError = null;
    _actionError = null;
    resetFiltersSilently();

    if (user == null) {
      _loading = false;
      return;
    }
    _loading = true;
    _sub = _incidents.watchIncidents().listen(
      (list) {
        _all = list;
        _loading = false;
        _loadError = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _loadError = 'Could not load reports. Pull to retry.';
        notifyListeners();
      },
    );
  }

  // ---- filters -----------------------------------------------------------
  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setStatusFilter(IncidentStatus? value) {
    _statusFilter = value;
    notifyListeners();
  }

  void setCategoryFilter(IncidentCategory? value) {
    _categoryFilter = value;
    notifyListeners();
  }

  void setScope(ReportScope value) {
    _scope = value;
    notifyListeners();
  }

  void setSort(IncidentSort value) {
    _sort = value;
    notifyListeners();
  }

  void clearFilters() {
    _search = '';
    _statusFilter = null;
    _categoryFilter = null;
    notifyListeners();
  }

  void resetFiltersSilently() {
    _search = '';
    _statusFilter = null;
    _categoryFilter = null;
    _scope = ReportScope.mine;
    _sort = IncidentSort.newest;
  }

  /// Re-subscribes after a load error.
  void retry() {
    final user = _user;
    _user = null;
    bindUser(user);
    notifyListeners();
  }

  // ---- actions -----------------------------------------------------------

  /// Creates a report (uploading the optional photo first). Returns the new
  /// report id, or null on failure ([actionError] explains why).
  Future<String?> submitReport({
    required String title,
    required String description,
    required IncidentCategory category,
    required String building,
    required String room,
    required bool isUrgent,
    File? photo,
  }) async {
    final user = _user;
    if (user == null) return null;
    return _run<String>(() async {
      final id = _incidents.newId();
      UploadedPhoto? uploaded;
      if (photo != null) {
        uploaded = await _storage.uploadIncidentPhoto(
          uid: user.uid,
          incidentId: id,
          file: photo,
        );
      }
      final now = DateTime.now();
      final draft = Incident(
        id: id,
        title: title.trim(),
        description: description.trim(),
        category: category,
        building: building.trim(),
        room: room.trim(),
        status: IncidentStatus.submitted,
        isUrgent: isUrgent,
        reporterId: user.uid,
        reporterName: user.displayName,
        createdAt: now,
        updatedAt: now,
        photoUrl: uploaded?.url,
        photoPath: uploaded?.path,
      );
      try {
        await _incidents.create(id, draft);
      } catch (_) {
        await _storage.deletePhoto(uploaded?.path); // don't leave orphans
        rethrow;
      }
      return id;
    });
  }

  /// Student edit (allowed only while the report is still "Submitted").
  /// [newPhoto] replaces the photo; [removePhoto] deletes it.
  Future<bool> editReport(
    Incident original, {
    required String title,
    required String description,
    required IncidentCategory category,
    required String building,
    required String room,
    required bool isUrgent,
    File? newPhoto,
    bool removePhoto = false,
  }) async {
    final user = _user;
    if (user == null) return false;
    final ok = await _run<bool>(() async {
      UploadedPhoto? uploaded;
      if (newPhoto != null) {
        uploaded = await _storage.uploadIncidentPhoto(
          uid: user.uid,
          incidentId: original.id,
          file: newPhoto,
        );
      }
      final replace = newPhoto != null || removePhoto;
      try {
        await _incidents.edit(
          original.id,
          IncidentEdit(
            title: title.trim(),
            description: description.trim(),
            category: category,
            building: building.trim(),
            room: room.trim(),
            isUrgent: isUrgent,
            replacePhoto: replace,
            photoUrl: uploaded?.url,
            photoPath: uploaded?.path,
          ),
        );
      } catch (_) {
        await _storage.deletePhoto(uploaded?.path);
        rethrow;
      }
      if (replace) await _storage.deletePhoto(original.photoPath);
      return true;
    });
    return ok ?? false;
  }

  Future<bool> deleteReport(Incident incident) async {
    final ok = await _run<bool>(() async {
      await _incidents.delete(incident.id);
      await _storage.deletePhoto(incident.photoPath);
      return true;
    });
    return ok ?? false;
  }

  /// Staff-only. The UI hides this for students and Firestore rules enforce it.
  Future<bool> updateStatus(
    Incident incident,
    IncidentStatus status, {
    String note = '',
  }) async {
    final user = _user;
    if (user == null || !user.isStaff) {
      _actionError = 'Only authorized staff can update report status.';
      notifyListeners();
      return false;
    }
    final ok = await _run<bool>(() async {
      await _incidents.updateStatus(
        id: incident.id,
        status: status,
        note: note.trim(),
        staffUid: user.uid,
        staffName: user.displayName,
      );
      return true;
    });
    return ok ?? false;
  }

  void clearActionError() {
    if (_actionError == null) return;
    _actionError = null;
    notifyListeners();
  }

  Future<T?> _run<T>(Future<T> Function() action) async {
    _submitting = true;
    _actionError = null;
    notifyListeners();
    try {
      return await action();
    } catch (e) {
      _actionError = describeError(e);
      return null;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
