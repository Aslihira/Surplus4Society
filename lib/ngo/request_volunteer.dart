import 'package:flutter/material.dart';

class RequestVolunteerPage extends StatelessWidget {
  const RequestVolunteerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Volunteer'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text('Request Volunteer Page'),
      ),
    );
  }
} 