import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

class FirebaseConfig {
  const FirebaseConfig._();

  /// Initializes Firebase with platform-specific options and sets up session persistence.
  static Future<FirebaseApp> initialize() async {
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (kIsWeb) {
      try {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      } catch (_) {
        // Fallback gracefully if browser storage restrictions prevent explicit persistence call
      }
    }

    return app;
  }
}
