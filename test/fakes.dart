import 'dart:async';
import 'dart:io';

import 'package:campus_care/models/app_user.dart';
import 'package:campus_care/models/auth_session.dart';
import 'package:campus_care/models/enums.dart';
import 'package:campus_care/models/incident.dart';
import 'package:campus_care/repositories/auth_repository.dart';
import 'package:campus_care/repositories/incident_repository.dart';
import 'package:campus_care/repositories/storage_repository.dart';

/// Builds an incident with sensible defaults for tests.
Incident makeIncident({
  String id = 'abc123def',
  String title = 'Broken classroom projector',
  String description = 'The projector powers on but shows no image at all.',
  IncidentCategory category = IncidentCategory.facilities,
  String building = 'Block B',
  String room = 'Room 204',
  IncidentStatus status = IncidentStatus.submitted,
  bool isUrgent = false,
  String reporterId = 'student-1',
  String reporterName = 'Amara Mensah',
  DateTime? createdAt,
  String staffNote = '',
}) {
  final created = createdAt ?? DateTime(2026, 10, 18, 14, 15);
  return Incident(
    id: id,
    title: title,
    description: description,
    category: category,
    building: building,
    room: room,
    status: status,
    isUrgent: isUrgent,
    reporterId: reporterId,
    reporterName: reporterName,
    createdAt: created,
    updatedAt: created,
    staffNote: staffNote,
  );
}

AppUser makeUser({
  String uid = 'student-1',
  String name = 'Amara Mensah',
  UserRole role = UserRole.student,
}) =>
    AppUser(
      uid: uid,
      email: role == UserRole.staff
          ? 'kofi@alueducation.com'
          : 'amara@alustudent.com',
      displayName: name,
      role: role,
      createdAt: DateTime(2026, 9, 1),
    );

class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthSession?>.broadcast();
  final Map<String, UserRole> roles = {};
  int signOutCalls = 0;
  int verificationRefreshes = 0;
  AuthSession? current;

  void emit(AuthSession? session) {
    current = session;
    _controller.add(session);
  }

  @override
  Stream<AuthSession?> sessionChanges() => _controller.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> resendVerification() async {}

  @override
  Future<AuthSession?> refreshVerification() async {
    verificationRefreshes++;
    return current;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async {
    signOutCalls++;
    emit(null);
  }

  @override
  Future<AppUser> loadOrCreateProfile(AuthSession session) async => AppUser(
        uid: session.uid,
        email: session.email,
        displayName: session.displayName ?? 'Test User',
        role: roles[session.uid] ?? UserRole.student,
        createdAt: DateTime(2026, 9, 1),
      );

  @override
  Future<void> markUpdatesSeen(String uid) async {}
}

class FakeIncidentRepository implements IncidentRepository {
  FakeIncidentRepository([List<Incident> seed = const []]) {
    items.addAll(seed);
  }

  final items = <Incident>[];
  final history = <String, List<StatusUpdate>>{};
  final _changes = StreamController<void>.broadcast();
  int _counter = 0;
  bool failNextWrite = false;

  void _emit() => _changes.add(null);

  void _maybeFail() {
    if (failNextWrite) {
      failNextWrite = false;
      throw Exception('boom');
    }
  }

  @override
  String newId() => 'new${(++_counter).toString().padLeft(6, '0')}';

  @override
  Stream<List<Incident>> watchIncidents() async* {
    yield List.of(items);
    await for (final _ in _changes.stream) {
      yield List.of(items);
    }
  }

  @override
  Stream<List<StatusUpdate>> watchUpdates(String incidentId) async* {
    yield List.of(history[incidentId] ?? const []);
    await for (final _ in _changes.stream) {
      yield List.of(history[incidentId] ?? const []);
    }
  }

  @override
  Future<void> create(String id, Incident draft) async {
    _maybeFail();
    items.insert(0, draft);
    _emit();
  }

  @override
  Future<void> edit(String id, IncidentEdit edit) async {
    _maybeFail();
    final index = items.indexWhere((i) => i.id == id);
    items[index] = items[index].copyWith(
      title: edit.title,
      description: edit.description,
      category: edit.category,
      building: edit.building,
      room: edit.room,
      isUrgent: edit.isUrgent,
    );
    _emit();
  }

  @override
  Future<void> updateStatus({
    required String id,
    required IncidentStatus status,
    required String note,
    required String staffUid,
    required String staffName,
  }) async {
    _maybeFail();
    final index = items.indexWhere((i) => i.id == id);
    items[index] = items[index].copyWith(
      status: status,
      staffNote: note,
      updatedAt: DateTime.now(),
    );
    history.putIfAbsent(id, () => []).add(StatusUpdate(
          id: 'u${history[id]?.length ?? 0}',
          status: status,
          note: note,
          staffName: staffName,
          createdAt: DateTime.now(),
        ));
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _maybeFail();
    items.removeWhere((i) => i.id == id);
    history.remove(id);
    _emit();
  }
}

class FakeStorageRepository implements StorageRepository {
  final uploaded = <String>[];
  final deleted = <String>[];

  @override
  Future<UploadedPhoto> uploadIncidentPhoto({
    required String uid,
    required String incidentId,
    required File file,
  }) async {
    final path = 'incident_photos/$uid/$incidentId.jpg';
    uploaded.add(path);
    return UploadedPhoto(url: 'https://example.test/$path', path: path);
  }

  @override
  Future<void> deletePhoto(String? path) async {
    if (path != null) deleted.add(path);
  }
}
