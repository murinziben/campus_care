import 'package:campus_care/core/formatters.dart';
import 'package:campus_care/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ALU email validation', () {
    test('accepts student and staff domains (case/space insensitive)', () {
      expect(Validators.aluEmail('amara@alustudent.com'), isNull);
      expect(Validators.aluEmail('  Kofi@AluEducation.com '), isNull);
    });

    test('rejects other domains and malformed input', () {
      expect(Validators.aluEmail('amara@gmail.com'), isNotNull);
      expect(Validators.aluEmail('amara@alustudent.com.evil.io'), isNotNull);
      expect(Validators.aluEmail('not-an-email'), isNotNull);
      expect(Validators.aluEmail(''), isNotNull);
      expect(Validators.aluEmail(null), isNotNull);
    });
  });

  group('password rules', () {
    test('requires 8+ characters and a number', () {
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('longenoughbutnonumber'), isNotNull);
      expect(Validators.password('goodpass1'), isNull);
    });

    test('confirmation must match', () {
      expect(Validators.confirmPassword('abc12345', 'abc12345'), isNull);
      expect(Validators.confirmPassword('abc12346', 'abc12345'), isNotNull);
    });
  });

  group('report fields', () {
    test('title length bounds', () {
      expect(Validators.title('abc'), isNotNull);
      expect(Validators.title('Leaking tap'), isNull);
      expect(Validators.title('x' * 81), isNotNull);
    });

    test('description needs enough detail', () {
      expect(Validators.description('too short'), isNotNull);
      expect(Validators.description('x' * 25), isNull);
      expect(Validators.description('x' * 1001), isNotNull);
    });

    test('building is required', () {
      expect(Validators.building('  '), isNotNull);
      expect(Validators.building('Block B'), isNull);
    });
  });

  group('formatters', () {
    test('initials', () {
      expect(Formatters.initials('Amara Mensah'), 'AM');
      expect(Formatters.initials('kofi'), 'K');
      expect(Formatters.initials('  '), '?');
    });

    test('friendlyDate distinguishes today, yesterday and older', () {
      final now = DateTime(2026, 10, 29, 12);
      expect(Formatters.friendlyDate(DateTime(2026, 10, 29, 9, 24), now: now),
          startsWith('Today'));
      expect(Formatters.friendlyDate(DateTime(2026, 10, 28, 16), now: now),
          startsWith('Yesterday'));
      expect(Formatters.friendlyDate(DateTime(2026, 10, 18, 14, 15), now: now),
          startsWith('Oct 18'));
    });
  });
}
