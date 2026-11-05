# CampusCare - Campus Incident Reporting App

Flutter + Provider + Firebase (Authentication, Cloud Firestore, Storage).
Students report campus issues; authorised staff review them and update status.
Only verified `@alustudent.com` / `@alueducation.com` emails can use the app.

## Run
1. `flutter pub get`
2. Start an Android emulator, then `flutter run`
3. Tests: `flutter test`

## Firebase
Project: `campus-care-a75c7` (Android app `com.murinziben.campus_care`).
Security rules are in `firebase/firestore.rules` and `firebase/storage.rules`
(deploy with `firebase deploy --only firestore:rules,storage`).

## Staff accounts
Register normally, verify the email, then in Firebase Console -> Firestore ->
`users/{uid}` change `role` from `student` to `staff`. Users cannot do this themselves.

## Structure
`lib/core` theme/validators, `lib/models`, `lib/repositories` (only code that touches Firebase),
`lib/providers` (AuthProvider, IncidentProvider), `lib/screens`, `lib/widgets`, `test/`.
