import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

class FirebaseConfig {
  const FirebaseConfig._();

  /// Initializes Firebase with platform-specific options.
  static Future<FirebaseApp> initialize() async {
    return await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
