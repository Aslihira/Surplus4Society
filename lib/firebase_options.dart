// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD7SG0mveMQLdWc32dDVgL4yI-m6q9-tzc',
    appId: '1:74649975179:web:7a8c5ae3f0b62c6f3b178e',
    messagingSenderId: '74649975179',
    projectId: 'surplus4society-6993e',
    authDomain: 'surplus4society-6993e.firebaseapp.com',
    storageBucket: 'surplus4society-6993e.firebasestorage.app',
    measurementId: 'G-8WWD447ZLF',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDGt4EhoOCplfoKsRx2WnsVXWnAdxzHGZw',
    appId: '1:74649975179:android:f292f4500308cb703b178e',
    messagingSenderId: '74649975179',
    projectId: 'surplus4society-6993e',
    storageBucket: 'surplus4society-6993e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDvrA8W72qEUwpKRuetYWFukNTJbMbbjKA',
    appId: '1:74649975179:ios:f7a6042121c2a6c03b178e',
    messagingSenderId: '74649975179',
    projectId: 'surplus4society-6993e',
    storageBucket: 'surplus4society-6993e.firebasestorage.app',
    iosBundleId: 'com.example.surplus4society',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDvrA8W72qEUwpKRuetYWFukNTJbMbbjKA',
    appId: '1:74649975179:ios:f7a6042121c2a6c03b178e',
    messagingSenderId: '74649975179',
    projectId: 'surplus4society-6993e',
    storageBucket: 'surplus4society-6993e.firebasestorage.app',
    iosBundleId: 'com.example.surplus4society',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD7SG0mveMQLdWc32dDVgL4yI-m6q9-tzc',
    appId: '1:74649975179:web:67d260f9c5aa8a193b178e',
    messagingSenderId: '74649975179',
    projectId: 'surplus4society-6993e',
    authDomain: 'surplus4society-6993e.firebaseapp.com',
    storageBucket: 'surplus4society-6993e.firebasestorage.app',
    measurementId: 'G-8NMRS6LJZQ',
  );
}
