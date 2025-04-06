import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Surplus 4 Society',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true, // Use Material 3 which has better font handling
        // No font family specified to use system defaults
      ),
      home: const LoginPage(),
    );
  }
}
