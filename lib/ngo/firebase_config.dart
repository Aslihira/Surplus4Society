import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    try {
      return const FirebaseOptions(
        apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'YOUR-API-KEY'),
        appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: 'YOUR-APP-ID'),
        messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID', defaultValue: 'YOUR-SENDER-ID'),
        projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'YOUR-PROJECT-ID'),
        storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'YOUR-BUCKET'),
      );
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_core',
        message: 'Failed to initialize Firebase: ${e.toString()}',
      );
    }
  }

  static Future<void> initializeApp() async {
    try {
      await Firebase.initializeApp(
        options: currentPlatform,
      );
    } on FirebaseException catch (e) {
      debugPrint('Firebase initialization error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during Firebase initialization: $e');
      rethrow;
    }
  }
} 