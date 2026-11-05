import 'package:campus_care/app.dart';
import 'package:campus_care/models/auth_session.dart';
import 'package:campus_care/models/enums.dart';
import 'package:campus_care/widgets/incident_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeIncidentRepository incidents;

  Future<void> pumpApp(WidgetTester tester) async {
    auth = FakeAuthRepository();
    incidents = FakeIncidentRepository([
      makeIncident(id: 'a00001', title: 'Water shortage'),
    ]);
    // A tall screen so the whole home list is on screen.
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(CampusCareApp(
      authRepository: auth,
      incidentRepository: incidents,
      storageRepository: FakeStorageRepository(),
    ));
  }

  testWidgets('StatusBadge shows the status label', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StatusBadge(status: IncidentStatus.inProgress)),
    ));
    expect(find.text('In Progress'), findsOneWidget);
  });

  testWidgets('sign-in form rejects a non-ALU email', (tester) async {
    await pumpApp(tester);
    auth.emit(null);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'someone@gmail.com');
    await tester.enterText(fields.at(1), 'secret123');
    final signIn = find.widgetWithText(FilledButton, 'Sign In');
    await tester.ensureVisible(signIn);
    await tester.tap(signIn);
    await tester.pumpAndSettle();

    expect(find.textContaining('valid ALU email'), findsOneWidget);
  });

  testWidgets('verified student lands on the student home', (tester) async {
    await pumpApp(tester);
    auth.emit(const AuthSession(
        uid: 'student-1',
        email: 'amara@alustudent.com',
        emailVerified: true,
        displayName: 'Amara Mensah'));
    await tester.pumpAndSettle();

    expect(find.text('Your impact at a glance'), findsOneWidget);
    expect(find.text('Water shortage'), findsOneWidget);
    expect(find.text('Incident workspace'), findsNothing);
  });

  testWidgets('staff land on the staff workspace, not the student app', (tester) async {
    await pumpApp(tester);
    auth.roles['staff-1'] = UserRole.staff;
    auth.emit(const AuthSession(
        uid: 'staff-1',
        email: 'kofi@alueducation.com',
        emailVerified: true,
        displayName: 'Kofi Owusu'));
    await tester.pumpAndSettle();

    expect(find.text('Incident workspace'), findsOneWidget);
    expect(find.text('Your impact at a glance'), findsNothing);
  });

  testWidgets('unverified users only see the verification screen', (tester) async {
    await pumpApp(tester);
    auth.emit(const AuthSession(
        uid: 'student-1',
        email: 'amara@alustudent.com',
        emailVerified: false));
    await tester.pumpAndSettle();

    expect(find.text('Check your inbox'), findsOneWidget);
    expect(find.text('Your impact at a glance'), findsNothing);
  });
}
