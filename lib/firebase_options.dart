import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not configured for this platform.');
    }
  }

  // TODO: Paste your Web App credentials from the Firebase Console settings

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'INSERT_YOUR_API_KEY_HERE',
    appId: 'INSERT_YOUR_APP_ID_HERE',
    messagingSenderId: 'INSERT_YOUR_SENDER_ID_HERE',
    projectId: 'INSERT_YOUR_PROJECT_ID_HERE',
    authDomain: 'INSERT_YOUR_PROJECT_ID_HERE.firebaseapp.com',
    storageBucket: 'INSERT_YOUR_PROJECT_ID_HERE.firebasestorage.app',
    measurementId: 'INSERT_YOUR_MEASUREMENT_ID_HERE',
  );
  // TODO: Paste your Android App credentials from the Firebase Console settings

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'INSERT_YOUR_API_KEY_HERE',
    appId: 'INSERT_YOUR_APP_ID_HERE',
    messagingSenderId: 'INSERT_YOUR_SENDER_ID_HERE',
    projectId: 'INSERT_YOUR_PROJECT_ID_HERE',
    storageBucket: 'INSERT_YOUR_PROJECT_ID_HERE.firebasestorage.app',
  );
}
