import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

/// A campus incident report stored at `incidents/{id}`.
class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.building,
    required this.room,
    required this.status,
    required this.isUrgent,
    required this.reporterId,
    required this.reporterName,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.photoPath,
    this.staffNote = '',
    this.updatedBy,
  });

  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final String building;
  final String room;
  final IncidentStatus status;
  final bool isUrgent;
  final String reporterId;
  final String reporterName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? photoUrl;
  final String? photoPath;
  final String staffNote;
  final String? updatedBy;

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;
  bool get hasStaffNote => staffNote.trim().isNotEmpty;

  /// Human-friendly ticket number, e.g. `CC-7F3A9C`.
  String get shortId =>
      'CC-${id.length >= 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase()}';

  /// "Block B · Room 204" (room is optional).
  String get location => room.trim().isEmpty ? building : '$building · $room';

  bool isOwnedBy(String uid) => reporterId == uid;

  /// Students may edit or delete a report only until staff pick it up.
  bool get isEditableByOwner => status == IncidentStatus.submitted;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        location.toLowerCase().contains(q) ||
        shortId.toLowerCase().contains(q) ||
        category.label.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q);
  }

  Incident copyWith({
    String? title,
    String? description,
    IncidentCategory? category,
    String? building,
    String? room,
    IncidentStatus? status,
    bool? isUrgent,
    String? staffNote,
    DateTime? updatedAt,
  }) {
    return Incident(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      building: building ?? this.building,
      room: room ?? this.room,
      status: status ?? this.status,
      isUrgent: isUrgent ?? this.isUrgent,
      reporterId: reporterId,
      reporterName: reporterName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photoUrl: photoUrl,
      photoPath: photoPath,
      staffNote: staffNote ?? this.staffNote,
      updatedBy: updatedBy,
    );
  }

  factory Incident.fromMap(String id, Map<String, dynamic> map) {
    // Server timestamps are null for a moment on the device that wrote them.
    final created = _toDate(map['createdAt']) ?? DateTime.now();
    return Incident(
      id: id,
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      category: IncidentCategory.parse(map['category'] as String?),
      building: (map['building'] as String?) ?? '',
      room: (map['room'] as String?) ?? '',
      status: IncidentStatus.parse(map['status'] as String?),
      isUrgent: (map['isUrgent'] as bool?) ?? false,
      reporterId: (map['reporterId'] as String?) ?? '',
      reporterName: (map['reporterName'] as String?) ?? '',
      createdAt: created,
      updatedAt: _toDate(map['updatedAt']) ?? created,
      photoUrl: map['photoUrl'] as String?,
      photoPath: map['photoPath'] as String?,
      staffNote: (map['staffNote'] as String?) ?? '',
      updatedBy: map['updatedBy'] as String?,
    );
  }

  /// Fields written when the report is created.
  Map<String, dynamic> toCreateMap() => {
        'title': title,
        'description': description,
        'category': category.value,
        'building': building,
        'room': room,
        'status': IncidentStatus.submitted.value,
        'isUrgent': isUrgent,
        'photoUrl': photoUrl,
        'photoPath': photoPath,
        'reporterId': reporterId,
        'reporterName': reporterName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static DateTime? _toDate(Object? value) =>
      value is Timestamp ? value.toDate() : null;
}

/// One entry in a report's status history: `incidents/{id}/updates/{uid}`.
class StatusUpdate {
  const StatusUpdate({
    required this.id,
    required this.status,
    required this.note,
    required this.staffName,
    required this.createdAt,
  });

  final String id;
  final IncidentStatus status;
  final String note;
  final String staffName;
  final DateTime createdAt;

  factory StatusUpdate.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return StatusUpdate(
      id: id,
      status: IncidentStatus.parse(map['status'] as String?),
      note: (map['note'] as String?) ?? '',
      staffName: (map['staffName'] as String?) ?? 'Campus staff',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
