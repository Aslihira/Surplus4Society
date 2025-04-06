import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'firebase_config.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await DefaultFirebaseOptions.initializeApp();
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Error initializing app: $e');
    runApp(const ErrorApp());
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize app',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  try {
                    await DefaultFirebaseOptions.initializeApp();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MyApp()),
                      );
                    }
                  } catch (e) {
                    debugPrint('Retry failed: $e');
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Waste Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const WasteManagementDashboard(),
    );
  }
}

class WasteManagementDashboard extends StatefulWidget {
  const WasteManagementDashboard({super.key});

  @override
  _WasteManagementDashboardState createState() => _WasteManagementDashboardState();
}

class _WasteManagementDashboardState extends State<WasteManagementDashboard> {
  String _selectedStatus = 'All';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _staticRequests = [
    {
      'id': '1',
      'title': 'Food Donation Collection',
      'status': 'Pending',
      'quantity': '50 kg',
      'notes': 'Need volunteer for collecting food donations from local restaurant',
      'createdAt': '2024-03-20 10:00 AM'
    },
    {
      'id': '2',
      'title': 'Medical Supplies Delivery',
      'status': 'In Progress',
      'quantity': '10 boxes',
      'notes': 'Delivery of medical supplies to local clinic',
      'createdAt': '2024-03-20 11:30 AM'
    },
    {
      'id': '3',
      'title': 'Clothing Distribution',
      'status': 'Completed',
      'quantity': '100 pieces',
      'notes': 'Distribution of winter clothes to homeless shelter',
      'createdAt': '2024-03-20 09:00 AM'
    }
  ];

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'in progress':
        return Icons.timer;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Requests'),
        backgroundColor: Colors.green,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<String>(
              value: _selectedStatus,
              dropdownColor: Colors.green,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              underline: Container(),
              items: ['All', 'Pending', 'In Progress', 'Completed']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedStatus = newValue;
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _staticRequests.length,
              itemBuilder: (context, index) {
                final request = _staticRequests[index];
                if (_selectedStatus != 'All' && 
                    request['status'] != _selectedStatus) {
                  return const SizedBox.shrink();
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          request['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(request['notes']),
                            const SizedBox(height: 4),
                            Text(
                              'Quantity: ${request['quantity']}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Created: ${request['createdAt']}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getStatusIcon(request['status']),
                              color: _getStatusColor(request['status']),
                            ),
                            Text(
                              request['status'],
                              style: TextStyle(
                                color: _getStatusColor(request['status']),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // View details action
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Viewing details for ${request['title']}'),
                                      backgroundColor: Colors.blue,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.visibility),
                                label: const Text('View Details'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Request accepted!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Accept'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}