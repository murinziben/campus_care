import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_exception.dart';
import '../models/enums.dart';
import '../models/incident.dart';

/// Editable fields of a report (used by the student "edit" flow).
class IncidentEdit {
  const IncidentEdit({
    required this.title,
    required this.description,
    required this.category,
    required this.building,
    required this.room,
    required this.isUrgent,
    this.photoUrl,
    this.photoPath,
    this.replacePhoto = false,
  });

  final String title;
  final String description;
  final IncidentCategory category;
  final String building;
  final String room;
  final bool isUrgent;

  /// Only applied when [replacePhoto] is true (so null can mean "remove").
  final String? photoUrl;
  final String? photoPath;
  final bool replacePhoto;
}

abstract class IncidentRepository {
  /// Pre-allocates a document id so a photo can be uploaded before the
  /// report document is written.
  String newId();

  /// Live list of reports, newest first.
  Stream<List<Incident>> watchIncidents();

  /// Live status history for one report, oldest first.
  Stream<List<StatusUpdate>> watchUpdates(String incidentId);

  Future<void> create(String id, Incident draft);
  Future<void> edit(String id, IncidentEdit edit);

  /// Staff-only: change status, optionally with a note visible to the student.
  Future<void> updateStatus({
    required String id,
    required IncidentStatus status,
    required String note,
    required String staffUid,
    required String staffName,
  });

  Future<void> delete(String id);
}

class FirestoreIncidentRepository implements IncidentRepository {
  FirestoreIncidentRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _db.collection('incidents');

  @override
  String newId() => _incidents.doc().id;

  @override
  Stream<List<Incident>> watchIncidents() {
    return _incidents
        .orderBy('createdAt', descending: true)
        .limit(300)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Incident.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<List<StatusUpdate>> watchUpdates(String incidentId) {
    return _incidents
        .doc(incidentId)
        .collection('updates')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => StatusUpdate.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<void> create(String id, Incident draft) =>
      _guard(() => _incidents.doc(id).set(draft.toCreateMap()));

  @override
  Future<void> edit(String id, IncidentEdit edit) {
    final data = <String, dynamic>{
      'title': edit.title,
      'description': edit.description,
      'category': edit.category.value,
      'building': edit.building,
      'room': edit.room,
      'isUrgent': edit.isUrgent,
      'updatedAt': FieldValue.serverTimestamp(),
      if (edit.replacePhoto) 'photoUrl': edit.photoUrl,
      if (edit.replacePhoto) 'photoPath': edit.photoPath,
    };
    return _guard(() => _incidents.doc(id).update(data));
  }

  @override
  Future<void> updateStatus({
    required String id,
    required IncidentStatus status,
    required String note,
    required String staffUid,
    required String staffName,
  }) {
    return _guard(() async {
      final ref = _incidents.doc(id);
      final batch = _db.batch();
      batch.update(ref, {
        'status': status.value,
        'staffNote': note,
        'updatedBy': staffUid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(ref.collection('updates').doc(), {
        'status': status.value,
        'note': note,
        'staffId': staffUid,
        'staffName': staffName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    });
  }

  @override
  Future<void> delete(String id) {
    return _guard(() async {
      final ref = _incidents.doc(id);
      // Remove the status history first (staff only; empty for new reports).
      final updates = await ref.collection('updates').get();
      final batch = _db.batch();
      for (final doc in updates.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(ref);
      await batch.commit();
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'permission-denied':
          throw const AppException(
              'You do not have permission to do that. If this report has '
              'already been picked up by staff it can no longer be changed.');
        case 'unavailable':
        case 'deadline-exceeded':
          throw const AppException(
              'Network problem. Please check your connection and retry.');
        case 'not-found':
          throw const AppException('That report no longer exists.');
        default:
          throw AppException('Request failed (${e.code}).');
      }
    }
  }
}
