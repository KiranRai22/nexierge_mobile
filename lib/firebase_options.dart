// GENERATED FILE — DO NOT EDIT MANUALLY
//
// ⚠️  THIS IS A PLACEHOLDER.
// Run the FlutterFire CLI to generate the real version:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// That command reads your google-services.json and GoogleService-Info.plist
// and writes the correct values into this file automatically.
//
// Until then, the app will crash on Firebase.initializeApp().

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Replace every value below with your real Firebase project credentials ──

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WEB_API_KEY',
    appId: 'REPLACE_WITH_WEB_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    authDomain: 'REPLACE_WITH_PROJECT_ID.firebaseapp.com',
    storageBucket: 'REPLACE_WITH_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCza0XKy2yGgbwTYmdZN0C-gfD-7_Dxgjw',
    appId: '1:723358623825:android:807c6355c3972c3775f070',
    messagingSenderId: '723358623825',
    projectId: 'nexierge-mobile-app',
    storageBucket: 'nexierge-mobile-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCSg9om2tzw73WHNPE0gdgAi1wCNaYc9iM',
    appId: '1:723358623825:ios:ef3518f2335d451375f070',
    messagingSenderId: '723358623825',
    projectId: 'nexierge-mobile-app',
    storageBucket: 'nexierge-mobile-app.firebasestorage.app',
    iosBundleId: 'com.nexierge.app',
  );

}