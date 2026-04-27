import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

abstract class FirebaseService {
  static Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        return;
      }
      rethrow;
    }
  }
}
