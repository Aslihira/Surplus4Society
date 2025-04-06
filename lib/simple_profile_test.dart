import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'user/simple_user_profile.dart';

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
      title: 'Simple Profile Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SimpleProfileTestPage(),
    );
  }
}

class SimpleProfileTestPage extends StatelessWidget {
  const SimpleProfileTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Profile Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'This is a test page to demonstrate the SimpleUserProfilePage',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SimpleUserProfilePage(),
                  ),
                );
              },
              child: const Text('Open Simple User Profile'),
            ),
          ],
        ),
      ),
    );
  }
} 