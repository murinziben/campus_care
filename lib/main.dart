import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'repositories/auth_repository.dart';
import 'repositories/incident_repository.dart';
import 'repositories/storage_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(CampusCareApp(
    authRepository: FirebaseAuthRepository(),
    incidentRepository: FirestoreIncidentRepository(),
    storageRepository: CloudinaryStorageRepository(),
  ));
}
