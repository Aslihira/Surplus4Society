import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ngo_profile.dart';
import 'list_donation.dart';
import 'package:intl/intl.dart';
import 'create_request_page.dart';
import 'volunteers_page.dart';

class NGODashboardPage extends StatefulWidget {
  const NGODashboardPage({super.key});

  @override
  State<NGODashboardPage> createState() => _NGODashboardPageState();
}

class _NGODashboardPageState extends State<NGODashboardPage> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Dashboard stats
  int totalDonations = 0;
  int activeRequests = 0;
  int fulfilled = 0;
  int volunteers = 0;

  // Volunteer tasks data
  List<Map<String, dynamic>> volunteerTasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Load statistics
        final donationsQuery = await _firestore
            .collection('donations')
            .where('ngoId', isEqualTo: user.uid)
            .get();

        final volunteersQuery = await _firestore
            .collection('volunteers')
            .where('ngoId', isEqualTo: user.uid)
            .get();

        int completedDonations = 0;
        int pendingDonations = 0;

        for (var doc in donationsQuery.docs) {
          if (doc['status'] == 'completed') {
            completedDonations++;
          } else if (doc['status'] == 'pending') {
            pendingDonations++;
          }
        }

        // Load volunteer tasks
        final tasksQuery = await _firestore
            .collection('volunteer_tasks')
            .where('ngoId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'accepted')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get();

        setState(() {
          totalDonations = donationsQuery.docs.length;
          activeRequests = pendingDonations;
          fulfilled = completedDonations;
          volunteers = volunteersQuery.docs.length;
          
          volunteerTasks = tasksQuery.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? 'Untitled Task',
              'volunteer': data['volunteerName'] ?? 'Anonymous',
              'date': data['createdAt'] != null 
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
              'status': data['status'] ?? 'pending',
              'type': data['taskType'] ?? 'General',
            };
          }).toList();
          
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          _buildDonationsTab(),
          _buildVolunteersTab(),
          const NGOProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Donations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Volunteers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NGO Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Statistics cards
              _buildStatisticsSection(),
              const SizedBox(height: 24),
              
              // Volunteer Tasks Section
              _buildVolunteerTasksSection(),
              const SizedBox(height: 24),
              
              // Create Request Button
              _buildCreateRequestButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total Donations', totalDonations.toString()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Active Requests', activeRequests.toString()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Fulfilled', fulfilled.toString()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Volunteers', volunteers.toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Volunteer Tasks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedIndex = 2; // Switch to Volunteers tab
                });
              },
              icon: const Icon(Icons.people_outline, size: 18),
              label: const Text('View All'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (volunteerTasks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No active volunteer tasks',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          )
        else
          ...volunteerTasks.map((task) => _buildTaskCard(task)),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          task['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${task['volunteer']} • ${DateFormat('MMM d, y').format(task['date'])}',
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(
            Icons.volunteer_activism,
            color: Colors.blue[700],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            task['type'],
            style: TextStyle(
              color: Colors.green[700],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          // Navigate to task details
          _navigateToTaskDetails(task['id']);
        },
      ),
    );
  }

  Widget _buildCreateRequestButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _navigateToCreateRequest();
        },
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Create New Request'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _navigateToCreateRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateRequestPage(),
      ),
    );
  }

  void _navigateToTaskDetails(String taskId) {
    // TODO: Implement task details navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task details feature coming soon!')),
    );
  }

  Widget _buildDonationsTab() {
    return const ListDonationPage();
  }

  Widget _buildVolunteersTab() {
    return const WasteManagementDashboard();
  }
}