import 'package:campus_care/models/enums.dart';
import 'package:campus_care/models/incident.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  test('shortId and location are derived for display', () {
    final i = makeIncident(id: 'abc123def');
    expect(i.shortId, 'CC-ABC123');
    expect(i.location, 'Block B · Room 204');
    expect(makeIncident(room: '').location, 'Block B');
  });

  test('matches searches title, location, category and ticket id', () {
    final i = makeIncident();
    expect(i.matches('projector'), isTrue);
    expect(i.matches('block b'), isTrue);
    expect(i.matches('facilities'), isTrue);
    expect(i.matches('CC-ABC123'), isTrue);
    expect(i.matches('cafeteria'), isFalse);
    expect(i.matches('   '), isTrue);
  });

  test('students may edit only while the report is submitted', () {
    expect(makeIncident().isEditableByOwner, isTrue);
    expect(makeIncident(status: IncidentStatus.inProgress).isEditableByOwner,
        isFalse);
  });

  test('fromMap parses Firestore data and tolerates missing fields', () {
    final created = DateTime(2026, 10, 1, 8);
    final i = Incident.fromMap('xyz', {
      'title': 'Water shortage',
      'category': 'water',
      'status': 'in_progress',
      'isUrgent': true,
      'reporterId': 'u1',
      'createdAt': Timestamp.fromDate(created),
    });
    expect(i.category, IncidentCategory.water);
    expect(i.status, IncidentStatus.inProgress);
    expect(i.isUrgent, isTrue);
    expect(i.createdAt, created);
    expect(i.updatedAt, created); // falls back to createdAt
    expect(i.hasPhoto, isFalse);
  });

  test('unknown enum values fall back safely', () {
    expect(IncidentStatus.parse('nonsense'), IncidentStatus.submitted);
    expect(IncidentCategory.parse(null), IncidentCategory.other);
  });

  test('toCreateMap always starts as submitted', () {
    final map = makeIncident(status: IncidentStatus.resolved).toCreateMap();
    expect(map['status'], 'submitted');
    expect(map['reporterId'], 'student-1');
  });
}
