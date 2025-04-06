import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListDonationPage extends StatefulWidget {
  const ListDonationPage({super.key});

  @override
  State<ListDonationPage> createState() => _ListDonationPageState();
}

class _ListDonationPageState extends State<ListDonationPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Books', 'Food', 'Clothes', 'Electronics', 'Furniture', 'Medical', 'Other'];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  @override
  void initState() {
    super.initState();
    // Uncomment this line to add test data (use only once)
    // _addTestData();
  }

  // This function is for testing purposes only
  Future<void> _addTestData() async {
    final List<Map<String, dynamic>> testData = [
      {
        'itemType': 'Books',
        'quantity': 50,
        'notes': 'School textbooks for grades 6-8',
        'status': 'Pending',
        'donorId': 'donor123',
        'donorName': 'John Doe',
        'donorPhone': '+1234567890',
        'location': {
          'address': '123 Main St',
          'city': 'Downtown',
          'pincode': '400001'
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'itemType': 'Food',
        'quantity': 100,
        'notes': 'Non-perishable food items',
        'status': 'Accepted',
        'donorId': 'donor456',
        'donorName': 'Jane Smith',
        'donorPhone': '+1987654321',
        'location': {
          'address': '456 Park Ave',
          'city': 'Uptown',
          'pincode': '400002'
        },
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final data in testData) {
      await _firestore.collection('donations').add(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Donations'),
        actions: [
          _buildFilterDropdown(),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getDonationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final donation = snapshot.data!.docs[index];
              return _buildDonationCard(donation);
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropdownButton<String>(
        value: _selectedFilter,
        items: _filters.map((String filter) {
          return DropdownMenuItem<String>(
            value: filter,
            child: Text(filter),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedFilter = newValue;
            });
          }
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getDonationsStream() {
    Query query = _firestore.collection('donations');
    
    if (_selectedFilter != 'All') {
      query = query.where('itemType', isEqualTo: _selectedFilter);
    }
    
    return query.orderBy('createdAt', descending: true).snapshots();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No donations available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard(DocumentSnapshot donation) {
    final data = donation.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'Pending';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final location = data['location'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['itemType'] ?? 'Unknown Item',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quantity: ${data['quantity'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 8),
            if (createdAt != null) Text(
              'Posted on ${DateFormat('MMM d, y').format(createdAt)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (location != null) Text(
              'Location: ${location['address']}, ${location['city']} - ${location['pincode']}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              data['notes'] ?? 'No additional notes',
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16),
                const SizedBox(width: 4),
                Text(
                  data['donorName'] ?? 'Anonymous',
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                const Icon(Icons.phone_outlined, size: 16),
                const SizedBox(width: 4),
                Text(
                  data['donorPhone'] ?? 'N/A',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: status == 'Pending' ? () => _acceptDonation(donation.id) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _openChat(donation.id, data['donorId']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Chat'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _requestVolunteer(donation.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Request Volunteer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Accepted':
        color = Colors.green;
        break;
      case 'Ready for Delivery':
        color = Colors.orange;
        break;
      case 'Delivered':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _acceptDonation(String donationId) async {
    try {
      await _firestore
          .collection('donations')
          .doc(donationId)
          .update({
            'status': 'Accepted',
            'acceptedBy': _auth.currentUser?.uid,
            'acceptedAt': FieldValue.serverTimestamp(),
          });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donation accepted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting donation: $e')),
      );
    }
  }

  Future<void> _openChat(String donationId, String? donorId) async {
    if (donorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot start chat: Donor information not available')),
      );
      return;
    }

    try {
      // Create or get existing chat room
      final chatRoomId = 'chat_$donationId${_auth.currentUser!.uid}$donorId';
      final chatRoom = await _firestore.collection('chatRooms').doc(chatRoomId).get();

      if (!chatRoom.exists) {
        await _firestore.collection('chatRooms').doc(chatRoomId).set({
          'donationId': donationId,
          'participants': [_auth.currentUser!.uid, donorId],
          'lastMessage': null,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // TODO: Navigate to chat screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat room created. Chat feature coming soon!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening chat: $e')),
      );
    }
  }

  Future<void> _requestVolunteer(String donationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to request a volunteer')),
        );
        return;
      }

      await _firestore
          .collection('donations')
          .doc(donationId)
          .update({
            'acceptedVolunteer': currentUser.uid,
            'volunteerRequestedAt': FieldValue.serverTimestamp(),
          });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Volunteer request sent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error requesting volunteer: $e')),
      );
    }
  }
}