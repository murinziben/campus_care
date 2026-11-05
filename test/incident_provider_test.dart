import 'package:campus_care/models/enums.dart';
import 'package:campus_care/providers/incident_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeIncidentRepository repo;
  late FakeStorageRepository storage;
  late IncidentProvider provider;

  final seed = [
    makeIncident(
        id: 'a00001',
        title: 'Water shortage',
        category: IncidentCategory.water,
        building: 'Residence',
        room: 'East Wing',
        isUrgent: true,
        createdAt: DateTime(2026, 10, 20, 9)),
    makeIncident(
        id: 'a00002',
        title: 'Broken classroom projector',
        status: IncidentStatus.inProgress,
        createdAt: DateTime(2026, 10, 18, 14)),
    makeIncident(
        id: 'a00003',
        title: 'Overflowing bin',
        category: IncidentCategory.sanitation,
        status: IncidentStatus.resolved,
        reporterId: 'student-2',
        building: 'Cafeteria',
        room: '',
        createdAt: DateTime(2026, 10, 16, 11)),
  ];

  setUp(() async {
    repo = FakeIncidentRepository(seed);
    storage = FakeStorageRepository();
    provider = IncidentProvider(repo, storage);
    provider.bindUser(makeUser());
    await pumpEventQueue();
  });

  tearDown(() => provider.dispose());

  test('loads reports from the stream and separates "mine"', () {
    expect(provider.isLoading, isFalse);
    expect(provider.all.length, 3);
    expect(provider.mine.map((i) => i.id), ['a00001', 'a00002']);
  });

  test('scope, status, category and search filters combine', () {
    expect(provider.filtered.length, 2); // default scope = mine

    provider.setScope(ReportScope.campus);
    expect(provider.filtered.length, 3);

    provider.setStatusFilter(IncidentStatus.resolved);
    expect(provider.filtered.single.id, 'a00003');

    provider.setStatusFilter(null);
    provider.setCategoryFilter(IncidentCategory.water);
    expect(provider.filtered.single.id, 'a00001');

    provider.setCategoryFilter(null);
    provider.setSearch('cafeteria');
    expect(provider.filtered.single.id, 'a00003');

    provider.clearFilters();
    expect(provider.hasActiveFilters, isFalse);
  });

  test('priority sort puts urgent reports first', () {
    final sorted = provider.query(sort: IncidentSort.priority);
    expect(sorted.first.id, 'a00001');
  });

  test('submitReport persists and appears in the live list', () async {
    final id = await provider.submitReport(
      title: 'Cracked window',
      description: 'The window in the library reading room is cracked.',
      category: IncidentCategory.facilities,
      building: 'Library',
      room: '',
      isUrgent: false,
    );
    await pumpEventQueue();

    expect(id, isNotNull);
    expect(provider.all.length, 4);
    final created = provider.byId(id!)!;
    expect(created.status, IncidentStatus.submitted);
    expect(created.reporterId, 'student-1');
    expect(provider.actionError, isNull);
  });

  test('a failed submit reports an error and does not add anything', () async {
    repo.failNextWrite = true;
    final id = await provider.submitReport(
      title: 'Cracked window',
      description: 'The window in the library reading room is cracked.',
      category: IncidentCategory.facilities,
      building: 'Library',
      room: '',
      isUrgent: false,
    );
    expect(id, isNull);
    expect(provider.actionError, isNotNull);
    expect(provider.isSubmitting, isFalse);
    expect(provider.all.length, 3);
  });

  test('students cannot change status (client-side guard)', () async {
    final ok = await provider.updateStatus(
        provider.byId('a00001')!, IncidentStatus.resolved);
    expect(ok, isFalse);
    expect(provider.byId('a00001')!.status, IncidentStatus.submitted);
    expect(provider.actionError, contains('authorized staff'));
  });

  test('staff status change propagates and records history', () async {
    final staff = makeUser(uid: 'staff-1', name: 'Kofi Owusu', role: UserRole.staff);
    provider.bindUser(staff);
    await pumpEventQueue();

    final ok = await provider.updateStatus(
        provider.byId('a00001')!, IncidentStatus.inProgress,
        note: 'Plumber on the way');
    await pumpEventQueue();

    expect(ok, isTrue);
    final updated = provider.byId('a00001')!;
    expect(updated.status, IncidentStatus.inProgress);
    expect(updated.staffNote, 'Plumber on the way');
    expect(repo.history['a00001']!.single.staffName, 'Kofi Owusu');
  });

  test('student sees staff activity in the updates feed', () async {
    final staff = makeUser(uid: 'staff-1', role: UserRole.staff);
    provider.bindUser(staff);
    await pumpEventQueue();
    await provider.updateStatus(
        provider.byId('a00001')!, IncidentStatus.inProgress);
    await pumpEventQueue();

    provider.bindUser(makeUser()); // back to the student
    await pumpEventQueue();

    expect(provider.updatesFeed.map((i) => i.id), contains('a00001'));
    expect(provider.unreadUpdates(null), greaterThan(0));
    expect(provider.unreadUpdates(DateTime.now().add(const Duration(days: 1))), 0);
  });

  test('delete removes the report', () async {
    final ok = await provider.deleteReport(provider.byId('a00001')!);
    await pumpEventQueue();
    expect(ok, isTrue);
    expect(provider.byId('a00001'), isNull);
  });

  test('signing out clears data and stops the subscription', () async {
    provider.bindUser(null);
    expect(provider.all, isEmpty);
    expect(provider.isLoading, isFalse);
  });
}
