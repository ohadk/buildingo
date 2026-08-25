// Generated from the Firebase project apps registered for Dira
// (equivalent to `flutterfire configure` output).
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
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDlCxUQLNbD3V-ZXfme1YQ5g5cbW5sC4-E',
    appId: '1:848466124816:web:00f734d593d6821065aa95',
    messagingSenderId: '848466124816',
    projectId: 'buildingo-6ff54',
    authDomain: 'buildingo-6ff54.firebaseapp.com',
    storageBucket: 'buildingo-6ff54.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAZwKhRgWgClUSRtWxAckxuLKBrAPjn8-I',
    appId: '1:848466124816:android:3b704878cb7361cc65aa95',
    messagingSenderId: '848466124816',
    projectId: 'buildingo-6ff54',
    storageBucket: 'buildingo-6ff54.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBl8m0vtNBJMcCxUBGpWlqS-C6vaT3yR-0',
    appId: '1:848466124816:ios:687f6ce893762d7a65aa95',
    messagingSenderId: '848466124816',
    projectId: 'buildingo-6ff54',
    storageBucket: 'buildingo-6ff54.firebasestorage.app',
    iosBundleId: 'com.dira.diraMobile',
  );
}
